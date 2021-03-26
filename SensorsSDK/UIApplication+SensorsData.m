//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/25.
//

#import "UIApplication+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"
#import "UIView+SensorsData.h"
@implementation UIApplication (SensorsData)

+(void)load{
    [UIApplication sensorsdata_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(sensorsdata_sendAction:to:from:forEvent:)];
}

-(BOOL)sensorsdata_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent*)event{
    
    //如果当前控件为UISwitch UISegmentedControl UIStepper或者触发UITouchPhaseEnded时候才会去触发AppClick事件
    if ([sender isKindOfClass:[UISwitch class]]||[sender isKindOfClass:[UISegmentedControl class]]||[sender isKindOfClass:[UIStepper class]]||event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        //将sender转换成UIView类型
        UIView *view = (UIView*)sender;
        //触发AppClick事件
        [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithView:view properties:nil];
    }
    //调用原有方法实现 即 sendAction: to: from: forEvent: 方法
    return [self sensorsdata_sendAction:action to:target from:sender forEvent:event];
}
@end
