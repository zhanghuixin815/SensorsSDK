//
//  UIView+SensorsData.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/25.
//

#import "UIView+SensorsData.h"

@implementation UIView (SensorsData)

- (NSString *)sensorsdata_elementType{
    //返回当前控件的类型
    return NSStringFromClass([self class]);
}

- (NSString *)sensorsdata_elementContent{
    return nil;
}

- (UIViewController *)sensorsdata_viewController{
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)responder;
        }
    }
    //如果没找到就返回nil
    return nil;
}
@end

@implementation UIButton (SensorsData)

- (NSString *)sensorsdata_elementContent{
    return self.titleLabel.text;
}
@end

@implementation UISwitch (SensorsData)

- (NSString *)sensorsdata_elementContent{
    //在此处定一个规则，如果UISwitch当前为打开状态，设置内容为checked，否则为unchecked
    return self.on ? @"checked" : @"unchecked";
}
@end

@implementation UISlider (SensorsData)

- (NSString *)sensorsdata_elementContent{
    //在此处定一个规则，取UISlider当前的值并保留两位小数作为文本
    return [NSString stringWithFormat:@"%.2f",self.value];
}
@end

@implementation UISegmentedControl (SensorsData)

- (NSString *)sensorsdata_elementContent{
    //在此处定一个规则，取UISegmentedControl当前选定的index作为文本
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}
@end

@implementation UIStepper (SensorsData)

- (NSString *)sensorsdata_elementContent{
    //在此处定一个规则，取UIStepper当前的值作为文本
    return [NSString stringWithFormat:@"%g",self.value];
}
@end
