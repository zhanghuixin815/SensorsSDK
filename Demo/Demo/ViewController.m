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
    
    //测试UIButton埋点
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    button.backgroundColor = [UIColor redColor];
//    button.frame = CGRectMake(0, 0, 100, 50);
//    [button setTitle:@"点击" forState:UIControlStateNormal];
//    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:button];
//    button.center = self.view.center;
    
    //测试UISwitch埋点
//    UISwitch *mySwitch = [[UISwitch alloc]init];
//    mySwitch.frame=CGRectMake(0,0,0,0);
//    [mySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:mySwitch];
//    mySwitch.center = self.view.center;
//
    //测试UISlider埋点
//    UISlider *slider =[[UISlider alloc]initWithFrame:CGRectMake(20, 400, [UIScreen mainScreen].bounds.size.width-40, 20)];
//    slider.value=0.5;
//    slider.minimumTrackTintColor=[UIColor greenColor];
//    slider.maximumTrackTintColor=[UIColor blackColor];
//    slider.thumbTintColor=[UIColor grayColor];
//    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
//    [self.view addSubview:slider];
//    slider.center = self.view.center;
    
    //测试UISegmentedControl埋点
//    NSArray *segmentedArray = [[NSArray alloc]initWithObjects:@"1",@"2",@"3",@"4",nil];
//    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:segmentedArray];
//    segmentedControl.frame = CGRectMake(20.0, 20.0, 250.0, 50.0);
//    segmentedControl.selectedSegmentIndex = 2;//设置默认选择项索引
//    segmentedControl.tintColor = [UIColor redColor];
//    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
//    [self.view addSubview:segmentedControl];
//    segmentedControl.center = self.view.center;
    
    //测试UIStepper埋点
//    UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(180, 500, 50, 40)];
//    stepper.backgroundColor = [UIColor whiteColor];
//    [stepper addTarget:self action:@selector(stepperAction:) forControlEvents:UIControlEventValueChanged];
//    [stepper setMinimumValue:0];
//    [stepper setMaximumValue:100];
//    stepper.stepValue = 1;
//    [stepper setWraps:YES];
//    [stepper setContinuous:YES];
//    [self.view addSubview:stepper];
//    stepper.center = self.view.center;
   

}

-(void)valueChanged:(UISwitch*)mySwitch{
 
  if(mySwitch.on==YES){
    NSLog(@"开关被打开了");
  }else{
    NSLog(@"开关被关闭了");
  }
}

-(void)buttonClick:(id)sender{
    NSLog(@"按钮被点击了");
}

-(void)sliderValueChanged:(id)sender{
    NSLog(@"slider被滑动了");
}

-(void)segmentAction:(UISegmentedControl *)Seg{

    NSInteger index = Seg.selectedSegmentIndex;
    NSLog(@"当前的选中的索引是%@", @(index));
}

-(void)stepperAction:(UIStepper*)stepper{
    NSLog(@"当前stepper的值是:%@", [NSString stringWithFormat:@"%g",stepper.value]);
    
}


@end
