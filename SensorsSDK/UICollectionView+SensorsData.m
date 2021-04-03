//
//  UICollectionView+SensorsData.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/3.
//

#import "UICollectionView+SensorsData.h"
#import "NSObject+SASwizzler.h"
#import "SensorsAnalyticsDelegateProxy.h"
#import "UIScrollView+SensorsData.h"
#import "SensorsAnalyticsDynamicDelegate.h"
#import <objc/message.h>
#import "SensorsAnalyticsSDK.h"

@implementation UICollectionView (SensorsData)

+(void)load{
    [UICollectionView sensorsdata_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

-(void)sensorsdata_setDelegate:(id<UICollectionViewDelegate>)delegate{
    //方案1:方法交换
    [self sensorsdata_setDelegate:delegate];
    //交换delegate中的 collectionView:didSelectItemAtIndexPath: 方法
    [self sensorsdata_swizzleDidSelectItemAtIndexPathMethodWithDelegate:delegate];
    
    //方案2:动态子类
    [self sensorsdata_setDelegate:delegate];
    [SensorsAnalyticsDynamicDelegate proxyWithCollectionViewDelegate:delegate];
    
    //方案3:NSProxy消息转发
    //销毁保存的委托对象
    self.sensorsdata_delegateProxy = nil;
    if (delegate) {
        SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy proxyWithCollectionViewDelegate:delegate];
        //保存委托对象
        self.sensorsdata_delegateProxy = proxy;
        //调用原始方法，将代理设置为委托对象
        [self sensorsdata_setDelegate:proxy];
    }else{
        //调用原始方法，将代理设置为nil
        [self sensorsdata_setDelegate:nil];
    }
}

static void sensorsdata_collectionViewDidSelectItem(id object,SEL selector, UICollectionView*collectionView,NSIndexPath *indexPath){
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_collectionViewDidSelectItem:");
    //通过消息发送调用原始的 collectionView:didSelectItemAtIndexPath:
    ((void(*)(id,SEL,id,id))objc_msgSend)(object,destinationSelector,collectionView,indexPath);
    
    //触发AppClick事件
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}

-(void)sensorsdata_swizzleDidSelectItemAtIndexPathMethodWithDelegate:(id)delegate{
    //获取delegate对象的类
    Class deleagetClass = [delegate class];
    //方法名
    SEL sourceSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    //当deleagte对象中没有实现 collectionView:didSelectItemAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_collectionViewDidSelectItem:");
    //当delegate对象内已经实现了 sensorsdata_collectionViewDidSelectItem 方法时，证明已经交换完成了，此时可以直接返回
    if([delegate respondsToSelector:destinationSelector]){
        return;
    }
    Method sourceMethod = class_getInstanceMethod(deleagetClass, sourceSelector);
    const char *encoding = method_getTypeEncoding(sourceMethod);
    //当该类中已经存在该方法，证明方法交换失败，前面判断了是否存在，所以此处一定会添加成功
    if (!class_addMethod(deleagetClass, destinationSelector, (IMP)sensorsdata_collectionViewDidSelectItem, encoding)) {
        NSLog(@"add %@ to %@ error",NSStringFromSelector(destinationSelector),deleagetClass);
        return;
    }
    //方法添加成功之后，进行方法交换
    [deleagetClass sensorsdata_swizzleMethod:sourceSelector withMethod:destinationSelector];

}
@end
