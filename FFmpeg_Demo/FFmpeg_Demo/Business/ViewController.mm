//
//  ViewController.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/28.
//

#import "ViewController.h"
#include "Mp3Encoder.hpp"
#import "MHUtil.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self testPcmToMp3];
}
-(void)testPcmToMp3
{
    NSLog(@"*** Mp3Encoder *** encode start");
    Mp3Encoder * encoder = new Mp3Encoder();
    const char * pcmFilePath = [[MHUtil bundlePath:@"vocal.pcm"] cStringUsingEncoding:NSUTF8StringEncoding];
    const char * mp3FilePath = [[MHUtil documentsPath:@"vocal.mp3"] cStringUsingEncoding:NSUTF8StringEncoding];
    int sampleRate = 44100; //采样频率
    int channels = 2; //声道数
    int bitRate = 128 * 1024; //码率
    bool ret = encoder->Init(pcmFilePath, mp3FilePath, sampleRate, channels, bitRate);
    if (!ret) {
        NSLog(@"*** Mp3Encoder *** init fail");
        delete encoder;
    }
    //编码
    encoder->Encode();
    //关闭文件
    encoder->Destory();
    delete encoder;
    NSLog(@"*** Mp3Encoder *** encode success");
}

@end
