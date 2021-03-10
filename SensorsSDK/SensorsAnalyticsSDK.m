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

static NSString * const SensorsAnalyticsVersion = @"1.0.0";

@interface SensorsAnalyticsSDK()

@property(nonatomic,copy)NSDictionary<NSString *,id> *automaticProperties;

@end

@implementation SensorsAnalyticsSDK

-(instancetype)init{
    if (self = [super init]) {
        _automaticProperties = [self collectAutomaticProperties];
        [self setupListeners];
    }
    return  self;
}

+(SensorsAnalyticsSDK *)sharedInstance{
    
    static dispatch_once_t onceTken;
    static SensorsAnalyticsSDK *sdk = nil;
    dispatch_once(&onceTken, ^{
        sdk = [[SensorsAnalyticsSDK alloc]init];
    });
    return sdk;
    
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
    //注册监听UIApplicationDidEnterBackgroundNotification 本地通知，当app进入后台调用
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //注册监听UIApplicationDidBecomeActiveNotification 本地通知，当app处于活动状态调用
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //注册监听UIApplicationDidFinishLaunchingNotification 本地通知，当冷启动调用
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
}

-(void)applicationDidEnterBackground:(NSNotification*)notification{
    NSLog(@"Application Did Enter Background!");
    //触发 $AppEnd 事件
    [self track:@"$AppEnd" properties:nil];
}

-(void)applicationDidBecomeActive:(NSNotification*)notification{
    NSLog(@"Application Did Become Active!");
    //触发 $AppActive 事件
    [self track:@"$AppActive" properties:nil];
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification{
    NSLog(@"Application Did Finish Launching!");
    //触发 $AppStart 事件
    [self track:@"$AppStart" properties:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

@implementation SensorsAnalyticsSDK (Track)

-(void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *,id>*)properties{
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    //设置事件名称
    event[@"event"] = eventName;
    //设置事件戳 单位：秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 *1000];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    //添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    //添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    event[@"properties"] = eventProperties;
    [self printEvent:event];
}

@end
