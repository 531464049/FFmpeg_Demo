//
//  MHDecoderModel.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    MHMovieFrameTypeAudio,
    MHMovieFrameTypeVideo,
} MHMovieFrameType;

@interface MHMovieFrame : NSObject
@property (readonly, nonatomic) MHMovieFrameType type;
@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat duration;
-(void)clearFrame;
@end

@interface MHVideoFrame : MHMovieFrame
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic,nullable) char * luma;
@property (nonatomic,nullable) char * chromaB;
@property (nonatomic,nullable) char * chromaR;

-(char *)copyFrameData:(UInt8 *)frameData lineSize:(int)lineSize width:(int)width height:(int)height;



@end

@interface MHAudioFrame : MHMovieFrame

@property(nonatomic,nullable)void *samples;
@property(nonatomic,assign)int samplesLength;

@end

@interface MHAudioDecodeParameter : NSObject
@property(nonatomic,assign,readonly)AudioStreamBasicDescription asbd;
@property(nonatomic,assign,readonly)UInt32 channels;
@property(nonatomic,assign,readonly)Float64 sampleRate;
@property(nonatomic,assign,readonly)UInt32 bytesPerSample;

@end

NS_ASSUME_NONNULL_END
