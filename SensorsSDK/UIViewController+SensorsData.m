//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by huixin.a.zhang on 2021/3/24.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"

static NSString * const kSensorsDataBliackListFileName = @"sensorsdata_black_list";
@implementation UIViewController (SensorsData)

+(void)load{
    [UIViewController sensorsdata_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_viewDidAppear:)];
}

-(void)sensorsdata_viewDidAppear:(BOOL)animated{
    //调用原始方法，即 viewDidAppear
    [self sensorsdata_viewDidAppear:animated];
    if ([self shouldTrackAppViewScreen]) {
        //触发$AppViewScreen事件
        NSMutableDictionary *properties = [[NSMutableDictionary alloc]init];
        [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
        //navigationItem.titleView的优先级高于navigationItem.title，先获取navigationItem.titleView
        NSString *title = [self contentFromView:self.navigationItem.titleView];
        if (title.length == 0) {
            title = self.navigationItem.title;
        }
        [properties setValue:title forKey:@"$title"];
        [[SensorsAnalyticsSDK sharedInstance]track:@"$AppViewScreen" properties:properties];
    }
}

-(BOOL)shouldTrackAppViewScreen{
   
    static NSSet *blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //获取黑名单文件路径
        NSBundle *SDKBundle = [NSBundle bundleForClass:[SensorsAnalyticsSDK class]];
        NSString *path = [SDKBundle pathForResource:kSensorsDataBliackListFileName ofType:@"plist"];
        NSArray *classNames = [NSArray arrayWithContentsOfFile:path];
        NSMutableSet *set = [NSMutableSet setWithCapacity:classNames.count];
        for (NSString *className in classNames) {
            [set addObject:NSClassFromString(className)];
        }
        blackList = [set copy];
        
    });
    for (Class cla in blackList) {
        if ([self isKindOfClass:cla]) {
            return NO;
        }
    }
    return YES;
}

-(NSString*)contentFromView:(UIView*)rootView{
    if (rootView.isHidden) {
        return  nil;
    }
    //为了简化，目前只支持获取UIButton，UILabel，UITextView控件的文本
    NSMutableString *elementContent = [NSMutableString string];
    if ([rootView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton*)rootView;
        NSString *title = button.titleLabel.text;
        if ([title length] > 0) {
            [elementContent appendString:title];
        }
    }else if ([rootView isKindOfClass:[UILabel class]]){
        UILabel *label = (UILabel*)rootView;
        NSString *title = label.text;
        if ([title length] > 0) {
            [elementContent appendString:title];
        }
    }else if ([rootView isKindOfClass:[UITextView class]]){
        UITextView *textView = (UITextView*)rootView;
        NSString *title = textView.text;
        if ([title length] > 0) {
            [elementContent appendString:title];
        }
    }else{
        NSMutableArray<NSString *>*elementArray = [NSMutableArray array];
        for (UIView *subView in rootView.subviews) {
            NSString *temp = [self contentFromView:subView];
            if ([temp length] > 0) {
                [elementArray addObject:temp];
            }
        }
        if (elementArray.count > 0) {
            [elementContent appendString:[elementArray componentsJoinedByString:@"-"]];
        }
    }
    return [elementContent copy];
}
@end
