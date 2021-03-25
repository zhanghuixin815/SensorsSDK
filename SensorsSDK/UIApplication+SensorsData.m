//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/25.
//

#import "UIApplication+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"
@implementation UIApplication (SensorsData)

+(void)load{
    [UIApplication sensorsdata_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(sensorsdata_sendAction:to:from:forEvent:)];
}

-(BOOL)sensorsdata_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent*)event{
    
    //触发$AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]track:@"$AppClick" properties:nil];
    
    //调用原有方法实现 即 sendAction: to: from: forEvent: 方法
    return [self sensorsdata_sendAction:action to:target from:sender forEvent:event];
}
@end
