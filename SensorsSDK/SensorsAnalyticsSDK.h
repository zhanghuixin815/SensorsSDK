//
//  SensorsAnalyticsSDK.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/3/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK : NSObject

//设备ID(匿名ID)
@property(nonatomic,copy)NSString *anonymousId;
/**
 @abstract
 获取SDK实例
 
 @return返回单例
 */

+(SensorsAnalyticsSDK *)sharedInstance;

/**
 用户登录，设置登录ID
 @param loginId 用户的登录id
 */
-(void)login:(NSString*)loginId;

@end

@interface SensorsAnalyticsSDK (Track)

/**
 @abstract
 调用track接口触发事件
 @discusstion
 properties是一个NSDictionary。
 其中key是属性名称，必须是NSString类型；value则是属性的内容
 @param eventName 事件名称
 @param properties 事件属性
 */
-(void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *,id>*)properties;

/**
 触发AppClick事件
 @param view 事件名称
 @param properties 自定义事件属性
 */
-(void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *,id>*)properties;

/**
 支持UITableView触发AppClick事件
 @param tableView 触发事件的UITableView视图
 @param indexPath 在UITableView中点击的位置
 @param properties 自定义事件属性
 */
-(void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *,id>*)properties;

/**
 支持UICollectionView触发AppClick事件
 @param collectionView 触发事件的UICollectionView视图
 @param indexPath 在UITableView中点击的位置
 @param properties 自定义事件属性
 */
-(void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *,id>*)properties;
@end
NS_ASSUME_NONNULL_END
