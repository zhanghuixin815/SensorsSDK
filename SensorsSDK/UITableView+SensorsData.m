//
//  UITableView+SensorsData.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/3/28.
//

#import "UITableView+SensorsData.h"
#import "NSObject+SASwizzler.h"
#import <objc/message.h>
#import "SensorsAnalyticsSDK.h"

@implementation UITableView (SensorsData)

+(void)load{
    [UITableView sensorsdata_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

-(void)sensorsdata_setDelegate:(id<UITableViewDelegate>)delegate{
    [self sensorsdata_setDelegate:delegate];
    
    //方案1: 方法交换
    //交换delegate中的 tableView:didSelectRowAtIndexPath: 方法
    [self sensorsdata_swizzleDidSelectRowAtIndexPathMethodWithDelegate:delegate];
}

static void sensorsdata_tableViewDidSelectRow(id object,SEL selector,UITableView *tableView,NSIndexPath *indexPath){
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableViewDidSelectRow:");
    //通过消息发送调用原始的 tableView:disSelectRowAtIndexPath:
    ((void(*)(id,SEL,id,id))objc_msgSend)(object,destinationSelector,tableView,indexPath);
    
    //触发AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

-(void)sensorsdata_swizzleDidSelectRowAtIndexPathMethodWithDelegate:(id)delegate{
    //获取delegate对象的类
    Class deleagetClass = [delegate class];
    //方法名
    SEL sourceSelector = @selector(tableView:didSelectRowAtIndexPath:);
    //当deleagte对象中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableViewDidSelectRow:");
    //当delegate对象内已经实现了 sensorsdata_tableViewDidSelectRow: 方法时，证明已经交换完成了，此时可以直接返回
    if([delegate respondsToSelector:destinationSelector]){
        return;
    }
    Method sourceMethod = class_getInstanceMethod(deleagetClass, sourceSelector);
    const char *encoding = method_getTypeEncoding(sourceMethod);
    //当该类中已经存在该方法，证明方法交换失败，前面判断了是否存在，所以此处一定会添加成功
    if (!class_addMethod(deleagetClass, destinationSelector, (IMP)sensorsdata_tableViewDidSelectRow, encoding)) {
        NSLog(@"add %@ to %@ error",NSStringFromSelector(destinationSelector),deleagetClass);
        return;
    }
    //方法添加成功之后，进行方法交换
    [deleagetClass sensorsdata_swizzleMethod:sourceSelector withMethod:destinationSelector];

}
@end
