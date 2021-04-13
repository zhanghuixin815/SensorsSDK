//
//  SensorsAnalyticsKeychainItem.h
//  SensorsSDK
//
//  Created by 张慧鑫 on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsKeychainItem : NSObject

-(instancetype)initWithService:(NSString*)service key:(NSString*)key;
-(instancetype)initWithService:(NSString*)service accessGroup:(nullable NSString*)accessGroup key:(NSString*)key;

-(nullable NSString*)value;
-(void)update:(NSString*)value;
-(void)remove;
@end

NS_ASSUME_NONNULL_END
