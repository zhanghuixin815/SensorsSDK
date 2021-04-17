//
//  SensorsAnalyticsDatabase.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/16.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDatabase : NSObject

//数据库文件路径
@property(nonatomic,copy,readonly)NSString *filePath;
//sqlite3数据库
@property(nonatomic)sqlite3 *database;
//本地事件存储总量
@property(nonatomic)NSInteger eventCount;

/**
 初始化方法
 @param filePath 数据库路径，如果为空就使用默认路径
 @return 数据库对象
 */
-(instancetype)initWithFilePath:(nullable NSString*)filePath;

/**
 同步向数据库中插入事件数据
 @param event 事件
 */
-(void)insertEvent:(NSDictionary*)event;

/**
 从数据库中获取事件数据
 @param count 获取事件的条数
 @return 事件数据
 */
-(NSArray<NSString*>*)selectEventsForCount:(NSUInteger)count;

/**
 从数据库中删除一定数量的事件数据
 @param count 需要删除的事件数量
 @return 是否成功删除数据
 
 */
-(BOOL)deleteEventsForCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
