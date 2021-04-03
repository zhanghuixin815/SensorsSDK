//
//  SensorsAnalyticsDynamicDelegate.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDynamicDelegate : NSObject

+(void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

+(void)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
