//
//  ViewController.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/28.
//

#import "ViewController.h"
#import "Mp3Encoder.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView * tabView;
@property(nonatomic,copy)NSArray * titleArr;
@property(nonatomic,copy)NSArray * desArr;
@property(nonatomic,copy)NSArray * vcArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.titleArr = @[@"AudioRecoder",
                      @"AUPlayer",
                      @"VideoPlayer"];
    self.desArr = @[@"录音",
                    @"AudioFilePlayer Unit + RemotelIO Unit 音频播放器",
                    @"VideoPlayer"];
    self.vcArr = @[@"AudioRecoderVC",
                   @"AUPlayerVC",
                   @"VideoPlayerVC"];
    self.tabView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tabView .showsVerticalScrollIndicator = NO;
    self.tabView .showsHorizontalScrollIndicator = NO;
    self.tabView .delegate = self;
    self.tabView .dataSource = self;
    self.tabView .tableFooterView = [UIView new];
    [self.view addSubview:self.tabView];
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titleArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellid = @"klklklkl";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellid];
    }
    cell.textLabel.text = self.titleArr[indexPath.row];
    cell.detailTextLabel.text = self.desArr[indexPath.row];
    cell.detailTextLabel.numberOfLines = 0;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString * vcName = self.vcArr[indexPath.row];
    Class cls =  NSClassFromString(vcName);
    UIViewController *vc = (UIViewController *)[[cls alloc] init];
    vc.title = self.titleArr[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
