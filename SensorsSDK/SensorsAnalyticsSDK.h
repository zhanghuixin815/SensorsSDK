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

#pragma mark - Timer
@interface SensorsAnalyticsSDK (Timer)

/**
 开始统计事件时长
 
 调用这个接口时，并不会真正触发一次事件，只是开始计时
 
 @param event 事件名
 */
-(void)trackTimerStart:(NSString*)event;

/**
 结束事件时长统计，计算时常
 
 事件发生时长是从调用trackTimerStart:方法开始，一直到调用trackTimerEnd:properties:方法结束。
 如果多次调用trackTimerStart:方法，则从最后一次调用开始计算
 如果没有调用trackTimerStart:方法，就直接调用trackTimerEnd:properties:方法，则触发一次普通事件，不带时常属性
 
 @param event 事件名
 @param properties 事件属性
 
 */

-(void)trackTimerEnd:(NSString*)event properties:(nullable NSDictionary*)properties;

/**
 暂停统计事件时长
 
 如果该时间未开始，即如果没有调用trackTimerStart:方法，则不做任何操作
 
 @param event 事件名
 
 */

-(void)trackTimerPause:(NSString*)event;

/**
 恢复统计事件时长
 
 如果该时间未开始，即如果没有调用trackTimerStart:方法，则没有影响
 
 @param event 事件名
 
 */

-(void)trackTimerResume:(NSString*)event;

@end
NS_ASSUME_NONNULL_END
