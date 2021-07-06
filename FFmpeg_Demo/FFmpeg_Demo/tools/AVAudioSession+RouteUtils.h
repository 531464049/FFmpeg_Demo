//
//  AVAudioSession+RouteUtils.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import <AVFAudio/AVFAudio.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (RouteUtils)

-(BOOL)usingBlueTooth;

-(BOOL)usingWiredMicrophone;

-(BOOL)shouldShowEarphoneAlert;

@end

NS_ASSUME_NONNULL_END
