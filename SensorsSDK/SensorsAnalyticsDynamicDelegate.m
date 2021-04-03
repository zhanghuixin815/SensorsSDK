//
//  SensorsAnalyticsDynamicDelegate.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/3.
//

#import "SensorsAnalyticsDynamicDelegate.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

//delegate对象的子类前缀
static NSString *const kSensorsDelegatePrefix = @"cn.SensorsData.";
//tableView:didSelectRowAtIndexPath:方法指针类型
typedef void (*SensorsDidSelectRowImplementation)(id,SEL,UITableView*,NSIndexPath*);
//collectionView:didSelectItemAtIndexPath:方法指针类型
typedef void (*SensorsDidSelectItemImplementation)(id,SEL,UICollectionView*,NSIndexPath*);

@implementation SensorsAnalyticsDynamicDelegate

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //第一步：获取原始类
    Class cla = object_getClass(tableView);
    NSString *className = [NSStringFromClass(cla) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    Class originalClass = objc_getClass([className UTF8String]);
    
    //第二步：调用开发者自己实现的方法
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP originalImplementation = method_getImplementation(originalMethod);
    if (originalImplementation) {
        ((SensorsDidSelectRowImplementation)originalImplementation)(tableView.delegate,originalSelector,tableView,indexPath);
    }
    
    //第三步：埋点
    //触发$AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

+(void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate{
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    //当delegate中没有实现tableView:didSelectRowAtIndexPath:方法时，直接返回
    if (![delegate respondsToSelector:originalSelector]) {
        return;
    }
    //通过Runtime动态的创建一个新的类
    Class originalClass = object_getClass(delegate);
    NSString *originalClassName = NSStringFromClass(originalClass);
    //当delegate已经是一个动态创建的类时(判断originalClassName是否有kSensorsDelegatePrefix前缀)，无须重复设置，直接返回即可
    if ([originalClassName hasPrefix:kSensorsDelegatePrefix]) {
        return;
    }
    
    NSString *subClassName = [kSensorsDelegatePrefix stringByAppendingString:originalClassName];
    Class subClass = NSClassFromString(subClassName);
    if (!subClass) {
        //注册一个新的字类，其父类为originalClass
        subClass = objc_allocateClassPair(originalClass, subClassName.UTF8String, 0);
        //获取SensorsAnalyticsDynamicDelegate中的tableView:didSelectRowAtIndexPath:方法指针
        Method method = class_getInstanceMethod(self, originalSelector);
        //获取方法的具体实现
        IMP methodIMP = method_getImplementation(method);
        //获取方法的类型编码
        const char *types = method_getTypeEncoding(method);
        //在subClass中添加tableView:didSelectRowAtIndexPath:方法
        if (!class_addMethod(subClass, originalSelector, methodIMP, types)) {
            NSLog(@"Cannot copy method to destination selector %@ is already exists",NSStringFromSelector(originalSelector));
        }
        
        //获取SensorsAnalyticsDynamicDelegate中的sensorsdata_class方法指针
        Method classMethod = class_getInstanceMethod(self, @selector(sensorsdata_class));
        //获取方法实现
        IMP classIMP = method_getImplementation(classMethod);
        //获取方法的类型编码
        const char *classTypes = method_getTypeEncoding(classMethod);
        //在subClass中添加class方法
        if (!class_addMethod(subClass, @selector(class), classIMP, classTypes)) {
            NSLog(@"Cannot copy method to destination selector -(void)class is already exists");
        }
        
        //子类和原始类的大小必须相同，不能有更多的成员变量和属性
        //如果大小不相同将会导致设置子类时重新分配内存，重写对象的isa指针
        if (class_getInstanceSize(subClass) != class_getInstanceSize(originalClass)) {
            NSLog(@"Cannot create subClass of Delegate because the created subClass is not the same size of %@",NSStringFromClass(originalClass));
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return;
        }
        
        //将delegate设置为新创建的子类对象
        objc_registerClassPair(subClass);
    }
    
    if (object_setClass(delegate, subClass)) {
        NSLog(@"Successfully Created Deletgate Proxy Automatically");
    }
}

-(void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //第一步：获取原始类
    Class cla = object_getClass(collectionView);
    NSString *className = [NSStringFromClass(cla) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    Class originalClass = objc_getClass([className UTF8String]);
    
    //第二步：调用开发者自己实现的方法
    SEL originalSelector = NSSelectorFromString(@"collectionView:didSelectItemAtIndexPath:");
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP originalImplementation = method_getImplementation(originalMethod);
    if (originalImplementation) {
        ((SensorsDidSelectItemImplementation)originalImplementation)(collectionView.delegate,originalSelector,collectionView,indexPath);
    }
    
    //第三步：埋点
    //触发$AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}

+(void)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate{
    SEL originalSelector = NSSelectorFromString(@"collectionView:didSelectRowAtIndexPath:");
    //当delegate中没有实现tableView:didSelectRowAtIndexPath:方法时，直接返回
    if (![delegate respondsToSelector:originalSelector]) {
        return;
    }
    //通过Runtime动态的创建一个新的类
    Class originalClass = object_getClass(delegate);
    NSString *originalClassName = NSStringFromClass(originalClass);
    //当delegate已经是一个动态创建的类时(判断originalClassName是否有kSensorsDelegatePrefix前缀)，无须重复设置，直接返回即可
    if ([originalClassName hasPrefix:kSensorsDelegatePrefix]) {
        return;
    }
    
    NSString *subClassName = [kSensorsDelegatePrefix stringByAppendingString:originalClassName];
    Class subClass = NSClassFromString(subClassName);
    if (!subClass) {
        //注册一个新的字类，其父类为originalClass
        subClass = objc_allocateClassPair(originalClass, subClassName.UTF8String, 0);
        //获取SensorsAnalyticsDynamicDelegate中的tableView:didSelectRowAtIndexPath:方法指针
        Method method = class_getInstanceMethod(self, originalSelector);
        //获取方法的具体实现
        IMP methodIMP = method_getImplementation(method);
        //获取方法的类型编码
        const char *types = method_getTypeEncoding(method);
        //在subClass中添加tableView:didSelectRowAtIndexPath:方法
        if (!class_addMethod(subClass, originalSelector, methodIMP, types)) {
            NSLog(@"Cannot copy method to destination selector %@ is already exists",NSStringFromSelector(originalSelector));
        }
        
        //获取SensorsAnalyticsDynamicDelegate中的sensorsdata_class方法指针
        Method classMethod = class_getInstanceMethod(self, @selector(sensorsdata_class));
        //获取方法实现
        IMP classIMP = method_getImplementation(classMethod);
        //获取方法的类型编码
        const char *classTypes = method_getTypeEncoding(classMethod);
        //在subClass中添加class方法
        if (!class_addMethod(subClass, @selector(class), classIMP, classTypes)) {
            NSLog(@"Cannot copy method to destination selector -(void)class is already exists");
        }
        
        //子类和原始类的大小必须相同，不能有更多的成员变量和属性
        //如果大小不相同将会导致设置子类时重新分配内存，重写对象的isa指针
        if (class_getInstanceSize(subClass) != class_getInstanceSize(originalClass)) {
            NSLog(@"Cannot create subClass of Delegate because the created subClass is not the same size of %@",NSStringFromClass(originalClass));
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return;
        }
        
        //将delegate设置为新创建的子类对象
        objc_registerClassPair(subClass);
    }
    
    if (object_setClass(delegate, subClass)) {
        NSLog(@"Successfully Created Deletgate Proxy Automatically");
    }
}

-(Class)sensorsdata_class{
    //获取对象的类
    Class class = object_getClass(self);
    //将类名前缀设置为空字符串，获取原始类名
    NSString *className = [NSStringFromClass(class) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    //通过字符串取类并返回
    return objc_getClass([className UTF8String]);
}
@end
