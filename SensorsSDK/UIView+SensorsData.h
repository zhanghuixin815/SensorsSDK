//
//  UIView+SensorsData.h
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SensorsData)
//控件类型
@property(nonatomic,copy,readonly)NSString *sensorsdata_elementType;
//控件文本
@property(nonatomic,copy,readonly)NSString *sensorsdata_elementContent;
//所在控制器
@property(nonatomic,readonly)UIViewController *sensorsdata_viewController;

@end

@interface UIButton (SensorsData)

@end

@interface UISwitch (SensorsData)

@end

@interface UISlider (SensorsData)

@end

@interface UISegmentedControl (SensorsData)

@end

@interface UIStepper (SensorsData)

@end

NS_ASSUME_NONNULL_END
