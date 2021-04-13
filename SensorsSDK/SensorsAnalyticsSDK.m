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

static NSString *const SensorsAnalyticsVersion = @"1.0.0";
static NSString *const SensorsAnalyticsAnonymousId = @"cn.sensorsdata.anonymous_id";
static NSString *const SensorsAnalyticsKeychainService = @"cn.sensorsdata.SensorsAnalytics.id";

@interface SensorsAnalyticsSDK()

@property(nonatomic, copy)NSDictionary<NSString *,id> *automaticProperties;
//标记程序是否已经收到 UIApplicationWillResignActiveNotification 通知
@property(nonatomic)BOOL applicationWillResignActive;
//是否为被动启动
@property(nonatomic, getter=_isLaunchedPassively) BOOL launchedPassively;

@end

@implementation SensorsAnalyticsSDK{
    NSString *_anonymousId;
}

-(instancetype)init{
    if (self = [super init]) {
        _automaticProperties = [self collectAutomaticProperties];
        
        //设置是否被动启动标记
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;
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
#pragma clang diagnostic ignored "Wundeclared-selector"
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
    self.applicationWillResignActive = NO;
    //触发 $AppEnd 事件
    [self track:@"$AppEnd" properties:nil];
}

-(void)applicationDidBecomeActive:(NSNotification*)notification{
    NSLog(@"Application Did Become Active!");
    //如果已经收到过UIApplicationWillResignActiveNotification本地通知，就清除这个标记位，并且不会触发$AppActive 事件
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }
    self.launchedPassively = NO;
    //触发 $AppActive 事件
    [self track:@"$AppStart" properties:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

@implementation SensorsAnalyticsSDK (Track)

-(void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *,id>*)properties{
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    //设置事件的distinct_id用来唯一标识一个用户
    event[@"distinct_id"] = self.anonymousId;
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
    [self printEvent:event];
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
