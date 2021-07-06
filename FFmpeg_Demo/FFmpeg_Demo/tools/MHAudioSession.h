//
//  MHAudioSession.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHAudioSession : NSObject

+ (MHAudioSession *)sharedInstance;

@property(nonatomic,strong)AVAudioSession *audioSession;
@property(nonatomic,assign)Float64 preferredSampleRate;
@property(nonatomic,assign,readonly) Float64 currentSampleRate;
@property(nonatomic,assign)NSTimeInterval preferredLatency;
@property(nonatomic,assign)BOOL active;
@property(nonatomic,strong)NSString *category;

- (void)addRouteChangeListener;

@end

NS_ASSUME_NONNULL_END
