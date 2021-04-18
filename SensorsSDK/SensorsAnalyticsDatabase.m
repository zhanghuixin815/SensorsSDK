//
//  SensorsAnalyticsDatabase.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/16.
//

#import "SensorsAnalyticsDatabase.h"

static NSString *const SensorsAnalyticsDefaultDatabaseName = @"SensorsAnalyticsDatabase.splite";
static NSString *const SensorsAnalyticsSerialQueueLabel = @"cn.sensorsdata.databaseSerialQueue";

@interface SensorsAnalyticsDatabase()

@property(nonatomic,copy)NSString *filePath;
@property(nonatomic,strong)dispatch_queue_t queue;

@end

@implementation SensorsAnalyticsDatabase{
    sqlite3 *_database;
}
-(instancetype)init{
    return [self initWithFilePath:nil];
}

- (instancetype)initWithFilePath:(NSString *)filePath{
    self = [super init];
    if (self) {
        _filePath = filePath?:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultDatabaseName];
        //初始化队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"%@.%p",SensorsAnalyticsSerialQueueLabel,self];
        //创建一个串行队列
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        //打开数据库
        [self open];
        
        [self queryLocalDatbaseEventCount];
    }
    return self;
}
-(void)open{
    dispatch_async(self.queue, ^{
        //初始化SQLite库
        if (sqlite3_initialize() != SQLITE_OK) {
            return;
        }
        //打开数据库，获取数据库指针
        if (sqlite3_open_v2([self.filePath UTF8String], &(self->_database), SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,NULL)!= SQLITE_OK) {
            NSLog(@"SQLite stmt prepare error :%s",sqlite3_errmsg(self.database));
            return;
        }
        char *error;
        //创建数据库表的SQL语句
        NSString *sql = @"CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event BLOB)";
        //运行创建表的SQL语句
        if (sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, &error) != SQLITE_OK) {
            NSLog(@"Create events failier %s",error);
            return;
        }
    });
}

//为了提升性能，缓存一下 sqlite3_stmt
static sqlite3_stmt *insertStmt = NULL;
- (void)insertEvent:(NSDictionary *)event{
    dispatch_async(self.queue, ^{
        if (insertStmt) {
            //重置插入语句，重置之后可以绑定新的数据
            sqlite3_reset(insertStmt);
        }else{
            //插入语句
            NSString* sql = @"INSERT INTO events (event) values (?)";
            //准备执行SQL语句，获取sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
                //准备执行SQL语句失败
                NSLog(@"SQLite stmt prepare error:%s",sqlite3_errmsg(self.database));
                return;
            }
        }
        NSError *error = nil;
        //将event转化成Json数据
        NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            //event转换失败
            NSLog(@"JSON serialization error :%@",error);
            return;
        }
        //将Json数据与stmt绑定
        sqlite3_bind_blob(insertStmt, 1, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        //执行stmt
        if (sqlite3_step(insertStmt) != SQLITE_DONE) {
            NSLog(@"insert event to events error");
            return;
        }
        //事件插入成功，更新事件数量
        self.eventCount++;
    });
}

//为了提升性能，缓存一下 sqlite3_stmt
static sqlite3_stmt *selectStmt = NULL;
//最后一次查询的事件数量
static NSUInteger lastSelectEventCount = 50;
- (NSArray<NSString *> *)selectEventsForCount:(NSUInteger)count{
    //初始化数组，用于存储查询到的事件数据
    NSMutableArray<NSString*> *events = [NSMutableArray arrayWithCapacity:count];
    //用同步是为了获取事件的完整性
    dispatch_sync(self.queue, ^{
        //本地事件数量为0时直接返回
        if(self.eventCount == 0){
            return;
        }
        if (count != lastSelectEventCount) {
            lastSelectEventCount = count;
            selectStmt = NULL;
        }
        if (selectStmt) {
        //重置查询语句，重置之后可重新查询数据
            sqlite3_reset(selectStmt);
        }else{
            //插入语句
            NSString* sql = [NSString stringWithFormat:@"SELECT id, event FROM events ORDER BY id ASC LIMIT %lu",(unsigned long)count];
            if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &selectStmt, NULL) != SQLITE_OK) {
                //准备执行SQL语句失败
                NSLog(@"SQLite stmt prepare error:%s",sqlite3_errmsg(self.database));
                return;
            }
        }
        //执行SQL语句
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            //将当前查询到的数据转换成NSData数据
            NSData *data = [[NSData alloc]initWithBytes:sqlite3_column_blob(selectStmt, 1) length:sqlite3_column_bytes(selectStmt, 1)];
            //将查询到的数据转换成Json字符串
            NSString *jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
#ifdef DEBUG
            NSLog(@"%@",jsonString);
#endif
            //将Json字符串添加到数组中
            [events addObject:jsonString];
        }
    });
    return events;
}

- (BOOL)deleteEventsForCount:(NSUInteger)count{
    __block BOOL success = YES;
    dispatch_sync(self.queue, ^{
        //当本地事件数量为0时，直接返回
        if (self.eventCount == 0) {
            return;
        }
        //删除语句
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN (SELECT id FROM events ORDER BY id ASC LIMIT %lu)",(unsigned long)count];
        char *errormsg;
        //执行SQL语句
        if (sqlite3_exec(self.database, [sql UTF8String ], NULL, NULL, &errormsg) != SQLITE_OK) {
            success = NO;
            NSLog(@"Falied to delete record errmsg = %s",errormsg);
            return;
        }
        //事件删除成功，更新事件数量
        self.eventCount = self.eventCount < count ? 0 : self.eventCount - count;
    });
    return success;
}

#pragma mark - Private
-(void)queryLocalDatbaseEventCount{
    dispatch_async(self.queue, ^{
        //查询语句
        NSString *sql = @"SELECT COUNT(*) FROM events;";
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            //准备执行SQL语句失败
            NSLog(@"SQLite stmt prepare error:%s",sqlite3_errmsg(self.database));
            return;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            self.eventCount = sqlite3_column_int(stmt, 0);
        }
        
    });
}

@end
