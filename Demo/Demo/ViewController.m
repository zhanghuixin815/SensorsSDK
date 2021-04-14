//
//  ViewController.m
//  Demo
//
//  Created by 张慧鑫 on 2021/3/10.
//

#import "ViewController.h"
#import <SensorsSDK/SensorsSDK.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,copy)NSArray *dataSource;
@property(nonatomic,strong)UICollectionView *collectionView;
@property(nonatomic,strong)UIImageView *imageView;

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
    
    //测试UITableView埋点
//    self.tableView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStylePlain];
//    self.tableView.delegate = self;//遵循协议
//    self.tableView.dataSource = self;//遵循数据源
//    self.dataSource = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8"];
//    [self.view addSubview:self.tableView];
    
    //测试UICollectionView埋点
//    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
//    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
//    layout.itemSize = CGSizeMake(200, 100);
//    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
//    _collectionView.delegate = self;
//    _collectionView.dataSource = self;
//    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CellId"];
//    [self.view addSubview:_collectionView];
    
    //测试手势采集埋点
//    self.imageView = [[UIImageView alloc]initWithImage:[UIImage addImage]];
//    [self.view addSubview:self.imageView];
//    self.imageView.center = self.view.center;
//    self.imageView.userInteractionEnabled = YES;
//    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
//    [tapGestureRecognizer addTarget:self action:@selector(tapAction:)];
//    [self.imageView addGestureRecognizer:tapGestureRecognizer];
//    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressAction:)];
//    [longPressGestureRecognizer addTarget:self action:@selector(longPressAction:)];
//    [self.imageView addGestureRecognizer:longPressGestureRecognizer];
    
    //测试事件时长埋点埋点
    UIButton *buttonBegin = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonBegin.backgroundColor = [UIColor redColor];
    buttonBegin.frame = CGRectMake(0, 150, 100, 50);
    [buttonBegin setTitle:@"开始" forState:UIControlStateNormal];
    [buttonBegin addTarget:self action:@selector(buttonClickBegin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonBegin];
    
    UIButton *buttonEnd = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonEnd.backgroundColor = [UIColor redColor];
    buttonEnd.frame = CGRectMake(0, 300, 100, 50);
    [buttonEnd setTitle:@"结束" forState:UIControlStateNormal];
    [buttonEnd addTarget:self action:@selector(buttonClickEnd:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonEnd];
    
    
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
//分区，组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
//每个分区的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}
//表格行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
//每个单元格的内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    //系统单元格
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellID"];
    }
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"点击了第 %ld 行",(long)indexPath.row + 1);
}

#pragma mack - collection delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 50;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellId" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:arc4random()%225/225.0 green:arc4random()%225/225.0 blue:arc4random()%225/225.0 alpha:1];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"点击了第 %ld 行",(long)indexPath.row + 1);
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

-(void)tapAction:(UITapGestureRecognizer*)sender{
    NSLog(@"点击手势触发了");
}

-(void)longPressAction:(UILongPressGestureRecognizer*)sender{
    NSLog(@"长按手势触发了");
}

-(void)buttonClickBegin:(id)sender{
    [[SensorsAnalyticsSDK sharedInstance]trackTimerStart:@"do something"];
}

-(void)buttonClickEnd:(id)sender{
    [[SensorsAnalyticsSDK sharedInstance]trackTimerEnd:@"do something" properties:nil];
}


@end
