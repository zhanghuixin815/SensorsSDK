//
//  NSObject+SASwizzler.h
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SASwizzler)

/**
 交换方法originalSEL和alternateSEL的方法实现
 @param originalSEL 原始方法名称
 @param alternateSEL 要交换的方法名称
 */
+(BOOL)sensorsdata_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL;

@end

NS_ASSUME_NONNULL_END
