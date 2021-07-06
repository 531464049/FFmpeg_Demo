//
//  AudioRecoderVC.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import "AudioRecoderVC.h"
#import "MHAudioRecoder.h"
#import "MHUtil.h"

@interface AudioRecoderVC ()

@property(nonatomic,strong)MHAudioRecoder * audioRecoder;
@property(nonatomic,copy)NSString * filePath;
@end

@implementation AudioRecoderVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSArray * arr = @[@"start",@"stop",@"share"];
    for (int i = 0; i < 3; i ++) {
        NSString * name = arr[i];
        UIButton * btn = [UIButton buttonWithType:0];
        btn.frame = CGRectMake(0, 0, 100, 60);
        btn.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 - 60 + 60*i);
        [btn setTitle:name forState:0];
        [btn setTitleColor:[UIColor redColor] forState:0];
        btn.tag = 1000 + i;
        [btn addTarget:self action:@selector(itemHandle:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    _filePath = [MHUtil documentsPath:@"recorder.caf"];
}
-(void)itemHandle:(UIButton *)sender
{
    if (sender.tag == 1000) {
        //start
        [self.audioRecoder start];
    }else if (sender.tag == 1001) {
        //stop
        [self.audioRecoder stop];
    }else{
        [self.audioRecoder stop];
        [MHUtil shareDataWithPath:_filePath];
    }
}
-(MHAudioRecoder *)audioRecoder
{
    if (!_audioRecoder) {
        _audioRecoder = [[MHAudioRecoder alloc] initWithPath:_filePath];
    }
    return _audioRecoder;
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
