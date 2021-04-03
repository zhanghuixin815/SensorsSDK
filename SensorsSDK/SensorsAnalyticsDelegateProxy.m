//
//  SensorsAnalyticsDelegateProxy.m
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/3.
//

#import "SensorsAnalyticsDelegateProxy.h"
#import "SensorsAnalyticsSDK.h"

@interface SensorsAnalyticsDelegateProxy()

@property(nonatomic,weak) id delegate;

@end

@implementation SensorsAnalyticsDelegateProxy

+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate{
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

+(instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate{
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)sel{
    //返回delegate中对对应的方法签名
    return [(NSObject*)self.delegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation{
    //先执行delegated对象中的方法
    [invocation invokeWithTarget:self.delegate];
    //判断是否是cell点击事件的代理方法
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        //将方法修改为进行数据采集的方法，即本类中实现的方法：sensorsdata_tableView:didSelectRowAtIndexPath:
        invocation.selector = @selector(sensorsdata_tableView:didSelectRowAtIndexPath:);
        //执行数据采集的相关方法
        [invocation invokeWithTarget:self];
    }else if (invocation.selector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        //将方法修改为进行数据采集的方法，即本类中实现的方法：sensorsdata_collectionView:didSelectRowAtIndexPath:
        invocation.selector = @selector(sensorsdata_collectionView:didSelectRowAtIndexPath:);
        //执行数据采集的相关方法
        [invocation invokeWithTarget:self];
    }
}
-(void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

-(void)sensorsdata_collectionView:(UICollectionView *)collectionView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[SensorsAnalyticsSDK sharedInstance]trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}
@end
