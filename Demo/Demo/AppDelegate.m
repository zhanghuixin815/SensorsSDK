//
//  AppDelegate.m
//  Demo
//
//  Created by 张慧鑫 on 2021/3/10.
//

#import "AppDelegate.h"
#import <SensorsSDK/SensorsSDK.h>
#import "ViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [SensorsAnalyticsSDK sharedInstance];
    [[SensorsAnalyticsSDK sharedInstance] track:@"MyFirstEvent" properties:@{@"testKey":@"testValue"}];
    [[SensorsAnalyticsSDK sharedInstance] login:@"123456"];
    self.window = [[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
    ViewController *vc = [[ViewController alloc]init];
    vc.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:vc];
    self.window.rootViewController = navi;
    [self.window makeKeyAndVisible];
    return YES;
}


@end
