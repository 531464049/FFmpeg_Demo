//
//  MHAudioSession.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import "MHAudioSession.h"
#import "AVAudioSession+RouteUtils.h"

@implementation MHAudioSession

+(MHAudioSession *)sharedInstance
{
    static MHAudioSession *instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MHAudioSession alloc] init];
    });
    return instance;
}
-(instancetype)init
{
    self = [super init];
    if (self) {
        // 采样率
        _preferredSampleRate = _currentSampleRate = 44100.0;
        // I/O buffer Buffer 越小则说明延迟越低
        _preferredLatency = 0.002;
        
        _audioSession = [AVAudioSession sharedInstance];
    }
    return self;
}
-(void)setCategory:(NSString *)category
{
    _category = category;
    NSError * error;
    if (![self.audioSession setCategory:category error:&error]) {
        NSLog(@"could not set category on audio session : %@",error.localizedDescription);
    }
}
-(void)setActive:(BOOL)active
{
    _active = active;
    NSError * error;
    if (![self.audioSession setPreferredSampleRate:self.preferredSampleRate error:&error]) {
        NSLog(@"could not set preferredSampleRate on audio session : %@",error.localizedDescription);
    }
    if (![self.audioSession setActive:active error:&error]) {
        NSLog(@"could not set active on audio session : %@",error.localizedDescription);
    }
    
    _currentSampleRate = self.audioSession.sampleRate;
}
-(void)setPreferredLatency:(NSTimeInterval)preferredLatency
{
    _preferredLatency = preferredLatency;
    NSError * error;
    if (![self.audioSession setPreferredIOBufferDuration:preferredLatency error:&error]) {
        NSLog(@"could not set preferred I/O buffer duration on audio session : %@",error.localizedDescription);
    }
}
-(void)addRouteChangeListener
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onNotificationAudioRouteChange:)
                                               name:AVAudioSessionRouteChangeNotification
                                             object:nil];
    [self adjustOnRouteChange];
}
- (void)onNotificationAudioRouteChange:(NSNotification *)sender {
    [self adjustOnRouteChange];
}
-(void)adjustOnRouteChange
{
    AVAudioSessionRouteDescription * curentDescription = AVAudioSession.sharedInstance.currentRoute;
    if (curentDescription) {
        if ([AVAudioSession.sharedInstance usingWiredMicrophone]) {
            
        }else{
            if (![AVAudioSession.sharedInstance usingBlueTooth]) {
                [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
        }
    }
}
@end
