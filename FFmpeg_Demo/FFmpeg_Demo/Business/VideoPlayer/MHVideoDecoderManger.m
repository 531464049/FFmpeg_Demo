//
//  MHVideoDecoderManger.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import "MHVideoDecoderManger.h"

@interface MHVideoDecoderManger ()
{
    dispatch_queue_t _decoderQueue;
    float _bufferedDuration;
    float _minBufferedDuration;
    float _moviePosition;
    NSMutableArray<MHVideoFrame *> * _videoFrames;
    NSMutableArray<MHAudioFrame *> * _audioFrames;
    BOOL _buffered;
}
@property(nonatomic,strong)MHAudioDecodeParameter * audioParameter;
@end

@implementation MHVideoDecoderManger
-(BOOL)isEndOfFile
{
    return self.decoder.isEndOfFile;
}
-(instancetype)initWithPath:(NSString *)videoPath videoPreInView:(UIView *)inView preFrame:(CGRect)preFrame;
{
    self = [super init];
    if (self) {
        self.audioParameter = [[MHAudioDecodeParameter alloc] init];
        
        _videoView = [[MHVideoGLView alloc] initWithFrame:preFrame];
        [inView addSubview:_videoView];

        _audioPlayer = [[MHAudioPlayer alloc] initWith:self.audioParameter];

        _decoder = [[MHVideoDecoder alloc] initWith:self.audioParameter];
        
        _decoderQueue = dispatch_queue_create("mhVideoDecoder", DISPATCH_QUEUE_SERIAL);
        _videoFrames = [NSMutableArray array];
        _audioFrames = [NSMutableArray array];
        _bufferedDuration = 0.0;
        _minBufferedDuration = 0.3;
        _moviePosition = 0.0;
        _buffered = NO;
        _movieDuraiton = 0.0;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(_decoderQueue, ^{
            [weakSelf.decoder openFile:videoPath];
            self->_movieDuraiton = weakSelf.decoder.duration;
        });
    }
    return self;
}
-(void)play
{
    if (self.playing) {
        return;
    }
    if (!self.decoder.isFileOpend) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self play];
        });
        return;
    }
    if (self.decoder.isEndOfFile) {
        [self setMoviePosition:0.0];
        return;
    }
    _playing = YES;
    [self tick];

    __weak typeof(self) weakSelf = self;
    self.audioPlayer.inputBlock = ^(float * _Nonnull data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf audioCallbackFillData:data numFrames:numFrames numChannels:numChannels];
    };
    [self.audioPlayer play];
}
-(void)tick
{
    if (!self.playing) {
        return;
    }
    MHVideoFrame * frame = [self getRenderVideoFrame];
    if (frame) {
        NSLog(@"当前帧的时间戳:%f, 当前帧的持续时间:%f", frame.position, frame.duration);
        [self.videoView render:frame];
        [self updateMoviePosition:frame.position];
        [frame clearFrame];
    }
    if (self.decoder.isEndOfFile) {
        _playing = NO;
        [self.audioPlayer stop];
        self.audioPlayer.inputBlock = nil;
        return;
    }
    if (_audioFrames.count == 0) {
        _buffered = YES;
    }else{
        _buffered = NO;
    }
    CGFloat interval = frame.duration;
    // 播放完一帧之后 继续播放下一帧 两帧之间的播放间隔不能小于0.01秒
    const NSTimeInterval time = MAX(interval, 0.01);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tick];
    });
}
-(MHVideoFrame *)getRenderVideoFrame
{
    MHVideoFrame * frame;
    @synchronized (_videoFrames) {
        if (_videoFrames.count > 0) {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
            _bufferedDuration -= frame.duration;
        }
    }
    if (self.playing && !self.decoder.isEndOfFile && _bufferedDuration < _minBufferedDuration) {
        [self asyncDecodeFrames];
    }
    return frame;
}
-(void)asyncDecodeFrames
{
    float duration = _minBufferedDuration;
    dispatch_async(_decoderQueue, ^{
        @autoreleasepool {
            NSArray * frames = [self.decoder decodeFrames:duration];
            [self addFrames:frames];
        }
    });
}
-(void)addFrames:(NSArray *)frames
{
    @synchronized (_videoFrames) {
        for (MHMovieFrame * frame in frames) {
            if (frame.type == MHMovieFrameTypeVideo) {
                [_videoFrames addObject:(MHVideoFrame *)frame];
                _bufferedDuration += frame.duration;
            }
        }
    }
    @synchronized (_audioFrames) {
        for (MHMovieFrame * frame in frames) {
            if (frame.type == MHMovieFrameTypeAudio) {
                [_audioFrames addObject:(MHAudioFrame *)frame];
            }
        }
    }
}
-(void)audioCallbackFillData:(float *)outData numFrames:(UInt32)numFrames numChannels:(UInt32)numChannels
{
    if (_buffered || !self.playing) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }
    @autoreleasepool {
        int framePos = 0;
        MHAudioFrame * frame;
        while (numFrames > 0) {
            if (!frame) {
                frame = [self getRnderAudioFrame];
                if (!frame) {
                    memset(outData, 0, numFrames * numChannels * sizeof(float));
                    return;
                }
                framePos = 0;
            }else {
                const void * datas = frame.samples + framePos;
                const int bytesLeft = frame.samplesLength - framePos;
                const int frameSize = numChannels * sizeof(float);
                const int bytesToCopy = MIN(numFrames * frameSize, bytesLeft);
                const int framesToCopy = bytesToCopy / frameSize;
                
                memcpy(outData, datas, bytesToCopy);
                numFrames = numFrames - framesToCopy;
                outData = outData + framesToCopy * numChannels;
                if (bytesToCopy < bytesLeft) {
                    framePos = framePos + bytesToCopy;
                }else{
                    break;
                }
            }
        }
        [frame clearFrame];
        frame = nil;
    }
}
-(MHAudioFrame *)getRnderAudioFrame
{
    @synchronized (_audioFrames) {
        if (_audioFrames.count == 0) {
            return nil;
        }
        MHAudioFrame * frame = _audioFrames[0];
        //音视频延迟
        float delta = _moviePosition - frame.position;
        //NSLog(@"---- %f",delta);
        if (delta < -0.1) {
            //视频滞后
            return nil;
        }else if (delta > 0.1) {
            //音频滞后
            [_audioFrames removeObjectAtIndex:0];
            [frame clearFrame];
            return [self getRnderAudioFrame];
        }else {
            [_audioFrames removeObjectAtIndex:0];
            return frame;
        }
    }
}
-(void)pause
{
    _playing = NO;
    [self.audioPlayer stop];
    self.audioPlayer.inputBlock = nil;
}
-(void)updateMoviePosition:(float)position
{
    _moviePosition = position;
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDecoderManager:duration:)]) {
        [self.delegate videoDecoderManager:self duration:position];
    }
}
-(void)setMoviePosition:(float)position
{
    [self pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updatePosition:position];
    });
}
-(void)updatePosition:(float)position
{
    [self freeFrames];
    position = MAX(0, position);
    position = MIN(_decoder.duration-1, position);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_decoderQueue, ^{
        [weakSelf.decoder updatePosition:position];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateMoviePosition:weakSelf.decoder.position];
            [weakSelf play];
        });
    });
}
-(void)freeFrames
{
    @synchronized (_videoFrames) {
        for (MHVideoFrame * frame in _videoFrames) {
            [frame clearFrame];
        }
        [_videoFrames removeAllObjects];
    }
    @synchronized (_audioFrames) {
        for (MHAudioFrame * frame in _audioFrames) {
            [frame clearFrame];
        }
        [_audioFrames removeAllObjects];
    }
    _bufferedDuration = 0;
}
-(void)destory
{
    _playing = NO;
    if (_decoderQueue) {
        _decoderQueue = NULL;
    }
    [self freeFrames];
    [self.videoView destoryPlayer];
    [self.audioPlayer destoryPlayer];
    [self.decoder destoryDecoder];
}
-(void)dealloc
{
    NSLog(@"MHVideoDecoderManger--dealloc");
}
@end
