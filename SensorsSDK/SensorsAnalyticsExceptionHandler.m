//
//  SensorsAnalyticsExceptionHandler.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/18.
//

#import "SensorsAnalyticsExceptionHandler.h"
#import "SensorsAnalyticsSDK.h"

static NSString *const SensorsDataSignalExceptionHandlerName = @"SignalExceptionHandler";
static NSString *const SensorsDataSignalExceptionHandlerUserInfo = @"SignalExceptionHandlerUserInfo";

@interface SensorsAnalyticsExceptionHandler()

@property(nonatomic)NSUncaughtExceptionHandler *previousExceptionHanler;

@end

@implementation SensorsAnalyticsExceptionHandler

//单例
+ (instancetype)sharedInstance{
    static SensorsAnalyticsExceptionHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SensorsAnalyticsExceptionHandler alloc]init];
    });
    return instance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        //保存之前的异常处理函数指针
        _previousExceptionHanler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&sensors_data_uncaught_exception_handler);
        //定义信号集结构体
        struct sigaction sig;
        //将信号集初始化为空
        sigemptyset(&sig.sa_mask);
        //在处理函数中传入__siginfo参数
        sig.sa_flags = SA_SIGINFO;
        //设置信号集处理函数
        sig.sa_sigaction = &sensors_data_signal_exception_handler;
        //定义需要采集的信号类型
        //SIGILL:程序非法指令信号，通常是因为可执行文件本身出现错误
        //SIGABRT:程序中止命令中止信号
        //SIGBUS:程序内存字节地址未对齐中止信号
        //SIGFPE:程序管道破裂信号
        //SIGSEGV:程序无效内存中止信号
        int signals[] = {SIGILL,SIGABRT,SIGBUS,SIGFPE,SIGSEGV};
        for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
            //注册信号处理
            int err = sigaction(signals[i], &sig, NULL);
            if (err) {
                NSLog(@"Errored while trying to setup sigaction fro signal %d",signals[i]);
            }
        }
        
    }
    return self;
}
static void sensors_data_uncaught_exception_handler(NSException *exception){
    //采集$AppCrashed事件
    [[SensorsAnalyticsExceptionHandler sharedInstance] trackAppCrashedWithException:exception];
    //处理保存的异常函数
    NSUncaughtExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedInstance].previousExceptionHanler;
    if (handler) {
        handler(exception);
    }
}

-(void)trackAppCrashedWithException:(NSException*)exception{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    //异常名称
    NSString *name = [exception name];
    //出现异常的原因
    NSString *reason = [exception reason];
    //异常的堆栈信息
    //当异常对象没有堆栈信息时，获取当前线程的堆栈信息，因为UNIX信号异常是自己构建的，没有堆栈信息
    NSArray *stacks = [exception callStackSymbols]?:[NSThread callStackSymbols];
    //将异常信息组装
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name: %@ \n Exception name: %@ \n Exception stack: %@",name,reason,stacks];
    //设置$AppCrashed事件属性$app_crashed_reason
    properties[@"$app_crashed_reason"] = exceptionInfo;
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppCrashed" properties:properties];
    //在闪退时采集$AppEnd事件，保证$AppStart和$AppEnd成对出现
    //采集$AppEnd回调的block
    dispatch_block_t trackAppEndBlock = ^{
        //判断应用是否处于运行状态
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            //触发事件
            [[SensorsAnalyticsSDK sharedInstance] track:@"$AppEnd" properties:nil];
        }
    };
    //获取主线程
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    //判断当前线程是否为主线程
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(mainQueue)) == 0) {
        //如果当前线程时主线程，直接回调trackAppEndBlock
        trackAppEndBlock();
    }else{
        //如果当前不是主线程,用主线程回调trackAppEndBlock
        dispatch_sync(mainQueue, trackAppEndBlock);
    }
    //获取 SensorsAnalyticsSDK 中的 serialQueue
    dispatch_queue_t serialQueue = [[SensorsAnalyticsSDK sharedInstance] valueForKeyPath:@"serialQueue"];
    //阻塞当前线程让serialQueue执行完成
    dispatch_sync(serialQueue, ^{});
    //获取数据存储时的线程
    dispatch_queue_t databaseQueue = [[SensorsAnalyticsSDK sharedInstance] valueForKeyPath:@"database.queue"];
    //阻塞当前线程让$AppCrashed事件完成入库
    dispatch_sync(databaseQueue, ^{});
    NSSetUncaughtExceptionHandler(NULL);
    int signals[] = {SIGILL,SIGABRT,SIGBUS,SIGFPE,SIGSEGV};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        signal(signals[i],SIG_DFL);
    }
}

static void sensors_data_signal_exception_handler(int sig, struct __siginfo *info, void *context){
    NSDictionary *userInfo = @{SensorsDataSignalExceptionHandlerUserInfo:@(sig)};
    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised",sig];
    NSException *exception = [NSException exceptionWithName:SensorsDataSignalExceptionHandlerName reason:reason userInfo:userInfo];
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedInstance];
    [handler trackAppCrashedWithException:exception];
}

@end
