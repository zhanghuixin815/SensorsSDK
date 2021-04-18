//
//  SensorsAnalyticsFileStore.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/16.
//

#import "SensorsAnalyticsFileStore.h"

//默认文件名
static NSString *const SensorsAnalyticsDefaultFileName = @"SensorsAnalyticsData.plist";
//队列唯一标识
static NSString *const SensorsAnalyticsSerialQueueLabel = @"cn.sensorsdata.fileStoreSerialQueue";

@interface SensorsAnalyticsFileStore()

@property(nonatomic,strong)NSMutableArray<NSDictionary*> *events;
//串行队列
@property(nonatomic,strong)dispatch_queue_t queue;

@end

@implementation SensorsAnalyticsFileStore
-(instancetype)init{
    self = [super init];
    if (self) {
        //初始化默认的事件存储地址
        _filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultFileName];
        //初始化队列的唯一标识符
        NSString *label = [NSString stringWithFormat:@"%@.%p",SensorsAnalyticsSerialQueueLabel,self];
        //创建一个串行队列
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        //从文件路径中读取数据
        [self readAllEventsFromFilePath:_filePath];
        //初始化本地最大缓存事件条数
        _maxLocalEventCount = 10000;
    }
    return self;
}

- (void)saveEvent:(NSDictionary *)event{
    //将存储事件的操作用队列包装起来
    dispatch_async(self.queue, ^{
        //如果当前事件条数超过当前的最大值，删除最旧的事件
        if (self.events.count >= self.maxLocalEventCount) {
            [self.events removeObjectAtIndex:0];
        }
        //在数组中先添加事件
        [self.events addObject:event];
        //将事件数据保存到文件中
        [self writeEventToFile];
    });
}

-(void)writeEventToFile{
    //将写入文件的操作用队列包装起来
    dispatch_async(self.queue, ^{
        //Json解析错误信息
        NSError *error = nil;
        //将字典数据解析成Json数据
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.events options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"The json object`s serialization error %@",error);
            return;
        }
        //将数据写入到文件里
        [data writeToFile:self.filePath atomically:YES];
    });
}

-(void)readAllEventsFromFilePath:(NSString*)filePath{
    //将从文件中读取数据的操作用队列包装起来
    dispatch_async(self.queue, ^{
        //从文件路径中读取数据
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSMutableArray *allEvents;
        //这里需要判断data是否为空，不为空才可以转化
        if (data) {
            //解析在文件中读取的Json数据
            allEvents = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        //将文件内的数据保存到内存中
        self.events = allEvents? allEvents : [NSMutableArray array];
        
    });
}

- (NSArray<NSDictionary *> *)allEvents{
    __block NSArray<NSDictionary *> *allEvents = nil;
    //将events的深拷贝操作用队列包装起来，确保线程安全
    dispatch_sync(self.queue, ^{
        allEvents = [self.events copy];
    });
    return allEvents;
}

- (void)deleteEventsForCount:(NSInteger)count{
    //删除count条事件数据
    [self.events removeObjectsInRange:NSMakeRange(0, count)];
    //将删除之后剩余的数据保存回文件中
    [self writeEventToFile];
}
@end
