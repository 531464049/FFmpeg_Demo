//
//  VideoPlayerVC.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/7.
//

#import "VideoPlayerVC.h"
#import "MHVideoDecoderManger.h"
#import "MHUtil.h"

@interface VideoPlayerVC ()<MHVideoDecoderManagerDelegate>
{
    UISlider * slider;
}
@property(nonatomic,strong)MHVideoDecoderManger * decoderManger;

@end

@implementation VideoPlayerVC
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.decoderManger destory];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect rect = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    NSString * path = [MHUtil bundlePath:@"test2.mp4"];
    self.decoderManger = [[MHVideoDecoderManger alloc] initWithPath:path videoPreInView:self.view preFrame:rect];
    self.decoderManger.delegate = self;
    
    for (int i = 0; i < 2; i ++) {
        UIButton * btn = [UIButton buttonWithType:0];
        btn.frame = CGRectMake(0, 0, 60, 40);
        if (i == 0) {
            [btn setTitle:@"play" forState:0];
            btn.center = CGPointMake(self.view.frame.size.width/4, self.view.frame.size.width + 100 + 50);
        }else{
            [btn setTitle:@"stop" forState:0];
            btn.center = CGPointMake(self.view.frame.size.width/4 * 3, self.view.frame.size.width + 100 + 50);
        }
        [btn setTitleColor:[UIColor redColor] forState:0];
        btn.tag = 100 + i;
        [btn addTarget:self action:@selector(btnHandle:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
    slider = [[UISlider alloc] initWithFrame:CGRectMake(40, self.view.frame.size.width + 100 + 100, self.view.frame.size.width-80, 40)];
    slider.maximumValue = 100;
    slider.minimumValue = 0;
    slider.value = 0;
    [slider addTarget:self action:@selector(valueChanged:) forControlEvents:(UIControlEventValueChanged)];
    [self.view addSubview:slider];
    
}
-(void)btnHandle:(UIButton *)sender
{
    if (sender.tag == 100) {
        [self play];
    }else{
        [self pause];
    }
}
-(void)play
{
    if (!self.decoderManger.playing) {
        [self.decoderManger play];
    }
}
-(void)pause
{
    [self.decoderManger pause];
}
-(void)valueChanged:(UISlider *)slider
{
    CGFloat value = slider.value / 100.0;
    CGFloat position = self.decoderManger.movieDuraiton * value;
    NSLog(@"****** set movie position %f",position);
    [self.decoderManger setMoviePosition:position];
}
-(void)videoDecoderManager:(MHVideoDecoderManger *)manager duration:(float)duration
{
    float movieDuration = self.decoderManger.movieDuraiton;
    float value = duration / movieDuration * 100.f;
    slider.value = value;
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
