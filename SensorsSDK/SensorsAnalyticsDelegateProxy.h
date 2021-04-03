//
//  SensorsAnalyticsDelegateProxy.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDelegateProxy : NSProxy<UITableViewDelegate,UICollectionViewDelegate>

/**
 初始化委托对象，用于拦截UITableView控件的选中cell事件
 @param delegate UITableView控件的代理
 @return 初始化对象
 */
+(instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

/**
 初始化委托对象，用于拦截UICollectionView控件的选中cell事件
 @param delegate UICollectionView控件的代理
 @return 初始化对象
 */
+(instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
