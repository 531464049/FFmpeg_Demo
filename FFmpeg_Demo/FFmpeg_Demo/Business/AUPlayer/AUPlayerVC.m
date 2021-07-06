//
//  AUPlayerVC.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/5.
//

#import "AUPlayerVC.h"
#import "MHUtil.h"
#import "MHAUGraphPlayer.h"

@interface AUPlayerVC ()

@property(nonatomic,strong)MHAUGraphPlayer * player;
@property(nonatomic,copy)NSString * filePath;
@property(nonatomic,assign)BOOL isAcc;

@end

@implementation AUPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _isAcc = NO;
    NSArray * arr = @[@"start",@"stop",@"change"];
    for (int i = 0; i < 3; i ++) {
        NSString * name = arr[i];
        UIButton * btn = [UIButton buttonWithType:0];
        btn.frame = CGRectMake(0, 0, 100, 60);
        btn.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 - 60 + 60*i);
        [btn setTitle:name forState:0];
        [btn setTitleColor:[UIColor redColor] forState:0];
        [btn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        btn.tag = 1000 + i;
        [btn addTarget:self action:@selector(itemHandle:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}
-(void)itemHandle:(UIButton *)sender
{
    if (sender.tag == 1000) {
        //start
        [self.player play];
    }else if (sender.tag == 1001) {
        //stop
        [self.player stop];
    }else{
        _isAcc = !_isAcc;
        [self.player setInputSource:_isAcc];
    }
}
-(MHAUGraphPlayer *)player
{
    if (!_player) {
        _filePath = [MHUtil bundlePath:@"test1.mp3"];
        _player = [[MHAUGraphPlayer alloc] initWithPath:_filePath];
    }
    return _player;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
