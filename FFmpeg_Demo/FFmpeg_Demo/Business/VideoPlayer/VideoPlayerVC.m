//
//  VideoPlayerVC.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/7.
//

#import "VideoPlayerVC.h"
#import "MHVideoDecoderManger.h"
#import "MHUtil.h"

@interface VideoPlayerVC ()

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
    
    [self.decoderManger play];
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
