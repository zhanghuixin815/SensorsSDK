//
//  NSObject+SASwizzler.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/24.
//

#import "NSObject+SASwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>
@implementation NSObject (SASwizzler)

+(BOOL)sensorsdata_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL{
    //获取原始方法
    Method originalMethod = class_getInstanceMethod(self, originalSEL);
    //当原始方法不存在时，直接返回NO，表示swizzling失败
    if (!originalMethod) {
        return NO;
    }
    //获取要交换的方法
    Method alternateMethod = class_getInstanceMethod(self, alternateSEL);
    //当需要交换方法不存在时，直接返回NO，表示swizzling失败
    if (!alternateMethod) {
        return NO;
    }
    //交换两个方法的实现
    method_exchangeImplementations(originalMethod, alternateMethod);
    //返回YES，表示swizzling成功
    return YES;
}
@end
