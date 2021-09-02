//
//  TextCaptureVC.m
//  MHVideoTool
//
//  Created by mahao on 2019/5/23.
//  Copyright © 2019 mh. All rights reserved.
//

#import "TextCaptureVC.h"
#import "MHCapture.h"

#import "MHHWH264Encoder.h"
#import "MHHWAACEncoder.h"

#import "MHHWH264Decoder.h"
#import "MHHWAACDecoder.h"

@interface TextCaptureVC ()<MHCaptureDelegate,MHHWH264EncoderDelegate,MHHWAACEncoderDelegate,MHHWH264DecoderDelegate,MHHWAACDecoderDelegate>

@property(nonatomic,strong)MHCapture * capture;

@property(nonatomic,strong)MHHWH264Encoder * videoEncoder;
@property(nonatomic,strong)MHHWAACEncoder * audioEncoder;

@property(nonatomic,strong)MHHWH264Decoder * videoDecoder;
@property(nonatomic,strong)MHHWAACDecoder * audioDecoder;

@end

@implementation TextCaptureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //采集
    self.capture = [[MHCapture alloc] initWithCaptureType:MHAVCaptureTypeGPUImage sessionPreset:AVCaptureSessionPreset1280x720 preViewRect:self.view.bounds];
//    self.capture = [[MHCapture alloc] initWithCaptureType:MHAVCaptureTypeSystem sessionPreset:AVCaptureSessionPreset1280x720 preViewRect:self.view.bounds];
    self.capture.delegate = self;
    [self.view addSubview:self.capture.preview];
    
    //编码
    self.videoEncoder = [[MHHWH264Encoder alloc] initWithParam:nil];
    self.videoEncoder.delegate = self;

    self.audioEncoder = [[MHHWAACEncoder alloc] initWithParam:nil];
    self.audioEncoder.delegate = self;

    //解码
    self.videoDecoder = [[MHHWH264Decoder alloc] init];
    self.videoDecoder.outPutType = MHHWH264DecoderOutPutType_y_u_v;
    self.videoDecoder.delegate = self;

    self.audioDecoder = [[MHHWAACDecoder alloc] init];
    self.audioDecoder.delegate = self;
    
    [self.capture startCapture];
    
    
}
#pragma mark - 采集回调代理
-(void)mhCaptureSendVideoBuffer:(CVImageBufferRef)videoBuffer
{
    [self.videoEncoder videoEncodeInputBuffer:videoBuffer];
}
-(void)mhCaptureSendAudioBuffer:(CMSampleBufferRef)audioBuffer
{
    [self.audioEncoder audioEncodeInpuBuffer:audioBuffer];
}
#pragma mark - 编码回调
-(void)mhHWH264EncoderOutputData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"视频编码回调-%d",(int)data.bytes);
    [self.videoDecoder decodeH264VideoData:data];
}
-(void)mhHWAACEncoderOutputData:(NSData *)aacData
{
    NSLog(@"音频编码回调-%d",(int)aacData.bytes);
    [self.audioDecoder audioDecodeAACData:aacData];
}
#pragma mark - 解码回调
-(void)mhHWH264DecoderOuPutY_U_VData:(NSData *)yuvData frameWidth:(int)width height:(int)height
{
    NSLog(@"视频解码回调-%d-%d-%d",(int)yuvData.bytes,width,height);
}
-(void)mhHWAACDecoderOutPutPcmData:(NSData *)pcmData
{
    NSLog(@"音频解码回调-%d",(int)pcmData.bytes);
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
