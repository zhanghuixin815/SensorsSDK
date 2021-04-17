//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/3/10.
//

#import "SensorsAnalyticsSDK.h"
#include <sys/sysctl.h>
#import<Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsKeychainItem.h"
#import "SensorsAnalyticsFileStore.h"
#import "SensorsAnalyticsDatabase.h"

static NSString *const SensorsAnalyticsVersion = @"1.0.0";
static NSString *const SensorsAnalyticsAnonymousId = @"cn.sensorsdata.anonymous_id";
static NSString *const SensorsAnalyticsKeychainService = @"cn.sensorsdata.SensorsAnalytics.id";
static NSString *const SensorsAnalyticsLoginId = @"cn.sensorsdata.login_id";
static NSString *const SensorsAnalyticsEventBeginKey = @"event_begin";
static NSString *const SensorsAnalyticsEventDurationKey = @"event_duration";
static NSString *const SensorsAnalyticsEventIsPauseKey = @"is_pause";

@interface SensorsAnalyticsSDK()

@property(nonatomic, copy)NSDictionary<NSString *,id> *automaticProperties;
//标记程序是否已经收到 UIApplicationWillResignActiveNotification 通知
@property(nonatomic)BOOL applicationWillResignActive;
//是否为被动启动
@property(nonatomic, getter=_isLaunchedPassively) BOOL launchedPassively;
//登陆ID
@property(nonatomic,copy)NSString *loginId;
//事件开始发生的时间戳
@property(nonatomic,strong)NSMutableDictionary<NSString*,NSDictionary*> *trackTimer;
//保存进入后台时未暂停的事件名称
@property(nonatomic,strong)NSMutableArray<NSString*> *enterbackgroundTrackTimerEvents;
//文件缓存事件数据对象
@property(nonatomic,strong)SensorsAnalyticsFileStore *fileStore;
//数据库存储对象
@property(nonatomic,strong)SensorsAnalyticsDatabase *database;

@end

@implementation SensorsAnalyticsSDK{
    NSString *_anonymousId;
}

-(instancetype)init{
    if (self = [super init]) {
        _automaticProperties = [self collectAutomaticProperties];
        
        //设置是否被动启动标记
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;
        
        //从NSUserDefaults中获取登陆ID
        _loginId = [[NSUserDefaults standardUserDefaults]objectForKey:SensorsAnalyticsLoginId];
        
        //初始化时间戳
        _trackTimer = [NSMutableDictionary dictionary];
        
        //初始化保存进入后台时未暂停的事件名称的数组
        _enterbackgroundTrackTimerEvents = [NSMutableArray array];
        
        //初始化文件缓存事件数据对象
        _fileStore = [[SensorsAnalyticsFileStore alloc]init];
        
        //初始化SensorsAnalyticsDatabase类的对象，并使用默认路径
        _database = [[SensorsAnalyticsDatabase alloc]init];
        
        //建立监听
        [self setupListeners];
    }
    return self;
}

+(SensorsAnalyticsSDK *)sharedInstance{
    
    static dispatch_once_t onceTken;
    static SensorsAnalyticsSDK *sdk = nil;
    dispatch_once(&onceTken, ^{
        sdk = [[SensorsAnalyticsSDK alloc]init];
    });
    return sdk;
    
}

- (void)setAnonymousId:(NSString *)anonymousId{
    _anonymousId = anonymousId;
    //保存设备ID(匿名ID)
    [self saveAnonymousId:anonymousId];
}

//获取设备ID的优先级顺序：IDFA > IDFV > UUID
- (NSString *)anonymousId{
    if (_anonymousId) {
        return _anonymousId;
    }
    //方案1:从NSUserDefaults中获取设备ID(匿名ID)
    _anonymousId = [[NSUserDefaults standardUserDefaults] objectForKey:SensorsAnalyticsAnonymousId];
    
    //方案2:从钥匙串中获取设备ID(匿名ID)
    SensorsAnalyticsKeychainItem *item = [[SensorsAnalyticsKeychainItem alloc]initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId];
    _anonymousId = [item value];
    if (_anonymousId) {
        return _anonymousId;
    }
    //获取IDFA
    //这里使用NSClassFromString 是为了防止应用程序没有导入AdSupport.framework
    Class cls = NSClassFromString(@"ASIdentifierManager");
    if (cls) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        //获取ASIdentifierManager的单例对象
        id manager = [cls performSelector:@selector(sharedmanager)];
        SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL (*isAdvertisingTrackingEnabled)(id,SEL) = (BOOL (*)(id,SEL))[manager methodForSelector:selector];
        if (isAdvertisingTrackingEnabled(manager,selector)) {
            //使用IDFA作为设备ID(匿名ID)
            _anonymousId = [(NSUUID*)[manager performSelector:@selector(advertisingInentifier)]UUIDString];
        }
#pragma clang diagnostic pop
    }
    if (!_anonymousId) {
        //使用IDFV作为设备ID(匿名ID)
        _anonymousId = UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    if (!_anonymousId) {
        //使用UUID作为设备ID(匿名ID)
        _anonymousId = NSUUID.UUID.UUIDString;
    }
    //保存设备ID(匿名ID)
    [self saveAnonymousId:_anonymousId];
    return _anonymousId;
}

#pragma mark - Properties
-(NSDictionary<NSString *,id>*)collectAutomaticProperties{
    NSMutableDictionary * properties = [NSMutableDictionary dictionary];
    //操作系统类型
    properties[@"$os"] = @"iOS";
    //SDK平台类型
    properties[@"$lib"] = @"iOS";
    //设备制造商
    properties[@"$maunfacturer"] = @"Apple";
    //SDK版本号
    properties[@"$lib_version"] = SensorsAnalyticsVersion;
    //手机型号
    properties[@"$model"] = [self deviceModel];
    //iOS版本号
    properties[@"$os_version"] = UIDevice.currentDevice.systemVersion;
    //app版本号
    properties[@"$app_version"] = NSBundle. mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    
    return [properties copy];
}

#pragma mark - 获取手机型号
-(NSString*)deviceModel{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *result = @(answer);
    return  result;
}

-(void)printEvent:(NSDictionary*) event{
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"JSON Serialization error :%@",error);
    }
    NSString *json = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[event]:%@",json);
#endif
}

#pragma mark Application Lifecycle
-(void)setupListeners{
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //注册监听UIApplicationDidEnterBackgroundNotification本地通知
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //注册监听UIApplicationDidBecomeActiveNotification本地通知
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //注册监听UIApplicationDidFinishLaunchingNotification本地通知
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    //注册监听UIApplicationWillResignActiveNotification本地通知
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
}

-(void)saveAnonymousId:(NSString*)anonymousId{
    //方案1:保存设备ID(匿名ID)到 NSUserDefaults 中
    [[NSUserDefaults standardUserDefaults]setObject:anonymousId forKey:SensorsAnalyticsAnonymousId];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    //方案2:保存设备ID(匿名ID)到钥匙串中
    SensorsAnalyticsKeychainItem *item = [[SensorsAnalyticsKeychainItem alloc]initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId];
    if (anonymousId) {
        //当设备ID(匿名ID)不为空时，将其保存在钥匙串内
        [item update:anonymousId];
    }else {
        //当设备ID(匿名ID)为空时，将其从钥匙串内删除
        [item remove];
    }
}

-(void)applicationDidEnterBackground:(NSNotification*)notification{
    NSLog(@"Application Did Enter Background!");
    //还原标识位
    self.applicationWillResignActive = NO;
    //触发 $AppEnd 事件
//    [self track:@"$AppEnd" properties:nil];
    [self trackTimerEnd:@"$AppEnd" properties:nil];
    //暂停所有事件的时长统计
    [self.trackTimer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            if (![obj[SensorsAnalyticsEventIsPauseKey] boolValue]) {
                [self.enterbackgroundTrackTimerEvents addObject:key];
                [self trackTimerPause:key];
            }
    }];
}

-(void)applicationDidBecomeActive:(NSNotification*)notification{
    NSLog(@"Application Did Become Active!");
    //如果已经收到过UIApplicationWillResignActiveNotification本地通知，就清除这个标记位，并且不会触发$AppActive 事件
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }
    
    //将被动启动标记位设置为NO，正常记录事件
    self.launchedPassively = NO;
    //触发 $AppActive 事件
    [self track:@"$AppActive" properties:nil];
    //恢复所有事件的时长统计
    for (NSString *event in self.enterbackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    //都恢复完成之后清空这个数组
    [self.enterbackgroundTrackTimerEvents removeAllObjects];
    //开始$AppEnd事件计时,统计app使用时长
    [self trackTimerStart:@"$AppEnd"];
}

-(void)applicationWillResignActive:(NSNotification*)notification{
    NSLog(@"Application Will Resign Active!");
    //标记已经收到UIApplicationWillResignActiveNotification本地通知
    self.applicationWillResignActive = YES;
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification{
    NSLog(@"Application Did Finish Launching!");
    if (self._isLaunchedPassively) {
        //触发 $AppStartPassively 事件
        [self track:@"$AppStartPassively" properties:nil];
    }
}

-(void)login:(NSString *)loginId{
    self.loginId = loginId;
    //在本地保存登陆ID
    [[NSUserDefaults standardUserDefaults]setObject:loginId forKey:SensorsAnalyticsLoginId];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark - Property
//目前未使用此方法获取当前时间
+(double)currentTime{
    //获取手机当前时间戳(受用户手动改变时间的影响，不一定准确)
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

//目前正在采用此方法获取当前时间
+(double)systemUpTime{
    //获取手机启动时间戳(不受用户手动改变时间的影响，更加准确)
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

@implementation SensorsAnalyticsSDK (Track)

-(void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *,id>*)properties{
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    //设置事件的distinct_id用来唯一标识一个用户
    event[@"distinct_id"] = self.loginId? self.loginId:self.anonymousId;
    //设置事件名称
    event[@"event"] = eventName;
    //设置时间戳 单位：豪秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 *1000];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    //添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    //添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    //被动启动设置状态
    if (self._isLaunchedPassively) {
        eventProperties[@"app_state"] = @"background";
    }
    event[@"properties"] = eventProperties;
    //将事件的内容打印出来
    [self printEvent:event];
    //将事件存储到文件里
//    [self.fileStore saveEvent:event];
    //将事件存储到数据库里面
    [self.database insertEvent:event];
}

-(void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *,id>*)properties{
    
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    //获取控件类型
    eventProperties[@"$element_type"] = view.sensorsdata_elementType;
    //获取控件显示文本
    eventProperties[@"$element_content"] = view.sensorsdata_elementContent;
    //获取控件所在控制器
    eventProperties[@"$screen_name"] = NSStringFromClass([view.sensorsdata_viewController class]);
    //添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    //触发$AppClick事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}

-(void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *,id>*)properties{
    
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    //获取用户点击的UITableViewCell对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //设置被用户点击的UITableViewCell控件上的内容($element_content)
    eventProperties[@"$element_content"] = cell.sensorsdata_elementContent;
    //设置被用户点击的UITableViewCell控件所在的位置($element_position)
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"section:%ld,row:%ld",(long)indexPath.section,(long)indexPath.row];
    //添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    //触发AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithView:tableView properties:eventProperties];
}

-(void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *,id>*)properties{
    
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    
    //获取用户点击的UICollectionViewCell对象
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    //设置被用户点击的UICollectionViewCell控件上的内容($element_content)
    eventProperties[@"$element_content"] = cell.sensorsdata_elementContent;
    //设置被用户点击的UICollectionViewCell控件所在的位置($element_position)
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"section:%ld,row:%ld",(long)indexPath.section,(long)indexPath.row];
    //添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    //触发AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithView:collectionView properties:eventProperties];
}

@end

#pragma mark - Timer
@implementation SensorsAnalyticsSDK (Timer)

- (void)trackTimerStart:(NSString *)event{
    //记录开时间
    self.trackTimer[event] = @{SensorsAnalyticsEventBeginKey : @([SensorsAnalyticsSDK systemUpTime])};
}

- (void)trackTimerEnd:(NSString *)event properties:(NSDictionary *)properties{
    NSDictionary *eventTimer = self.trackTimer[event];
    if (!eventTimer) {
        [self track:event properties:properties];
    }
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:properties];
    //移除
    [self.trackTimer removeObjectForKey:event];
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey]boolValue]) {
        //当事件处于暂停状态时，直接获取已经记录到的时长即可
        //获取事件时长
        double eventDuration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        //设置事件时长属性
        [p setObject:@([[NSString stringWithFormat:@"%.0lf",eventDuration] floatValue]) forKey:@"$event_duration"];
        
    }else{
        //如果时间未处于暂停状态，则需要加上之前暂停状态的时长(如有)
        //事件开始时间
        double beginTime = [(NSNumber*)eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
        //获取当前时间 -> 获取系统启动时间
        double currentTime = [SensorsAnalyticsSDK systemUpTime];
        //计算事件时长
        double eventDuration = currentTime - beginTime + [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        //设置事件时长属性
        [p setObject:@([[NSString stringWithFormat:@"%.0lf",eventDuration] floatValue]) forKey:@"$event_duration"];
    }
    //触发事件
    [self track:event properties:p];
}

- (void)trackTimerPause:(NSString *)event{
    NSMutableDictionary *eventTimer = self.trackTimer[event].mutableCopy;
    //如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    //如果该时间时长统计已经暂停，直接返回，不做任何处理
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    //获取当前系统启动时间
    double systemUpTime = [SensorsAnalyticsSDK systemUpTime];
    //获取开始时间
    double beginTime = [eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
    //计算暂停前统计的时长
    double duration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue] + systemUpTime - beginTime;
    eventTimer[SensorsAnalyticsEventDurationKey] = @(duration);
    //事件处于暂停状态
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(YES);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerResume:(NSString *)event{
    NSMutableDictionary *eventTimer = self.trackTimer[event].mutableCopy;
    //如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    //如果该时间时长统计没有暂停，直接返回，不做任何处理
    if (![eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    //获取当前系统启动时间
    double systemUpTime = [SensorsAnalyticsSDK systemUpTime];
    //重置时间开始时间
    eventTimer[SensorsAnalyticsEventBeginKey] = @(systemUpTime);
    //将时间暂停标记设置为NO
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(NO);
    self.trackTimer[event] = eventTimer;
}

@end
