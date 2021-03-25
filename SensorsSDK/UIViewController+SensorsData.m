//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/24.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"

static NSString * const kSensoorsDataBliackListFileName = @"sensorsdata_black_list";
@implementation UIViewController (SensorsData)

+(void)load{
    [UIViewController sensorsdata_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_viewDidAppear:)];
}

-(void)sensorsdata_viewDidAppear:(BOOL)animated{
    //调用原始方法，即 viewDidAppear
    [self sensorsdata_viewDidAppear:animated];
    //触发$AppViewScreen事件
    NSMutableDictionary *properties = [[NSMutableDictionary alloc]init];
    [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
    [[SensorsAnalyticsSDK sharedInstance]track:@"$AppViewScreen" properties:properties];
}
-(BOOL)shouldTrackAppViewScreen{
    
}
@end
