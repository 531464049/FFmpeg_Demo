//
//  MHAudioPlayer.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import <Foundation/Foundation.h>
#import "MHDecoderModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MHAudioPlayerInputBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@interface MHAudioPlayer : NSObject

@property(nonatomic,assign,readonly)BOOL isPlaying;
@property(nonatomic,copy,nullable)MHAudioPlayerInputBlock inputBlock;

-(instancetype)initWith:(MHAudioDecodeParameter *)parameter;

-(void)play;
-(void)stop;
-(void)destoryPlayer;
@end

NS_ASSUME_NONNULL_END
