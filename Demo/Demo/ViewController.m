//
//  ViewController.m
//  Demo
//
//  Created by 张慧鑫 on 2021/3/10.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"标题1";
    self.navigationItem.title = @"标题2";
    UILabel *customTitleVIew = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    customTitleVIew.text = @"标题3";
    customTitleVIew.font = [UIFont systemFontOfSize:18];
    customTitleVIew.textColor = [UIColor blackColor];
    customTitleVIew.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = customTitleVIew;
    
    //测试控件点击事件埋点
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    button.frame = CGRectMake(20, 20, 100, 50);
    [button setTitle:@"点击" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(butClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    button.center = self.view.center;
    
}

-(void)butClick:(id)sender{
    NSLog(@"我被修改了");
}


@end
