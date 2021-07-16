//
//  MHVideoDecoderManger.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import <Foundation/Foundation.h>
#import "MHVideoDecoder.h"
#import "MHVideoGLView.h"
#import "MHAudioPlayer.h"
#import "MHUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class MHVideoDecoderManger;
@protocol MHVideoDecoderManagerDelegate <NSObject>

@optional
-(void)videoDecoderManager:(MHVideoDecoderManger *)manager duration:(float)duration;

@end

@interface MHVideoDecoderManger : NSObject

@property(nonatomic,assign,readonly)BOOL playing;
@property(nonatomic,assign,readonly)BOOL isEndOfFile;
@property(nonatomic,strong,readonly)MHVideoDecoder * decoder;
@property(nonatomic,strong,readonly)MHVideoGLView * videoView;
@property(nonatomic,strong,readonly)MHAudioPlayer * audioPlayer;
@property(nonatomic,assign,readonly)float movieDuraiton;
@property(nonatomic,weak)id <MHVideoDecoderManagerDelegate> delegate;

-(instancetype)initWithPath:(NSString *)videoPath videoPreInView:(UIView *)inView preFrame:(CGRect)preFrame;
-(void)play;
-(void)setMoviePosition:(float)position;
-(void)pause;
-(void)destory;

@end

NS_ASSUME_NONNULL_END
