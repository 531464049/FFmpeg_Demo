//
//  MHDecoderModel.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import "MHDecoderModel.h"

@implementation MHMovieFrame
-(void)clearFrame
{
    
}
@end

@implementation MHVideoFrame
-(MHMovieFrameType)type
{
    return MHMovieFrameTypeVideo;
}
-(char *)copyFrameData:(UInt8 *)frameData lineSize:(int)lineSize width:(int)width height:(int)height
{
    width = MIN(lineSize, width);
    size_t size = width * height * sizeof(char);
    char * dst = (char *)malloc(size);
    memcpy(dst, frameData, size);
    return dst;
}
-(void)clearFrame
{
    if (self.luma) {
        free(self.luma);
        self.luma = NULL;
    }
    if (self.chromaB) {
        free(self.chromaB);
        self.chromaB = NULL;
    }
    if (self.chromaR) {
        free(self.chromaR);
        self.chromaR = NULL;
    }
}
@end

@implementation MHAudioFrame
-(MHMovieFrameType)type
{
    return MHMovieFrameTypeAudio;
}
-(void)clearFrame
{
    if (self.samples) {
        free(self.samples);
        self.samples = NULL;
    }

}
@end


@implementation MHAudioDecodeParameter
-(instancetype)init
{
    self = [super init];
    if (self) {
        AudioStreamBasicDescription asbd;
        UInt32 bytesPerSample = sizeof(Float32);
        bzero(&asbd, sizeof(asbd));
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
        asbd.mSampleRate = 44100.0;
        asbd.mChannelsPerFrame = 2;
        asbd.mFramesPerPacket = 1;
        asbd.mBitsPerChannel = 8 * bytesPerSample;
        asbd.mBytesPerPacket = bytesPerSample;
        asbd.mBytesPerFrame = bytesPerSample;
        _asbd = asbd;
        _bytesPerSample = asbd.mBitsPerChannel / 8;
        _sampleRate = asbd.mSampleRate;
        _channels = asbd.mChannelsPerFrame;
    }
    return self;
}
@end

