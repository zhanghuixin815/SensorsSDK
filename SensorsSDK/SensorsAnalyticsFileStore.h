//
//  SensorsAnalyticsFileStore.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsFileStore : NSObject

@property(nonatomic,copy)NSString *filePath;
@property(nonatomic,strong,readonly)NSArray<NSDictionary*> *allEvents;
//本地最大缓存事件条数
@property(nonatomic,assign)NSInteger maxLocalEventCount;

/**
 将事件保存到文件内
 @param event 事件名
 */
-(void)saveEvent:(NSDictionary*)event;

/**
 根据数量删除本地保存的事件数据
 @param count 需要删除的事件数量
 */
-(void)deleteEventsForCount:(NSInteger)count;
@end

NS_ASSUME_NONNULL_END
