//
//  AVAudioSession+RouteUtils.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import "AVAudioSession+RouteUtils.h"

@implementation AVAudioSession (RouteUtils)

-(BOOL)usingBlueTooth
{
    NSArray * inputs = self.currentRoute.inputs;
    NSArray * blueToothInputRotes = @[AVAudioSessionPortBluetoothHFP];
    for (AVAudioSessionPortDescription * description in inputs) {
        if ([blueToothInputRotes containsObject:description.portType]) {
            return YES;
        }
    }
    
    NSArray * outPuts = self.currentRoute.outputs;
    NSArray * blueToothOutputRotes = @[AVAudioSessionPortBluetoothHFP,AVAudioSessionPortBluetoothA2DP,AVAudioSessionPortBluetoothLE];
    for (AVAudioSessionPortDescription * description in outPuts) {
        if ([blueToothOutputRotes containsObject:description.portType]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)usingWiredMicrophone
{
    NSArray *inputs = self.currentRoute.inputs;
    NSArray *headSetInputRoutes = @[AVAudioSessionPortHeadsetMic];
    for (AVAudioSessionPortDescription *description in inputs) {
        if ([headSetInputRoutes containsObject:description.portType]) {
            return YES;
        }
    }
    
    NSArray *outputs = self.currentRoute.outputs;
    NSArray *headSetOutputRoutes = @[AVAudioSessionPortHeadphones, AVAudioSessionPortUSBAudio];
    for (AVAudioSessionPortDescription *description in outputs) {
        if ([headSetOutputRoutes containsObject:description.portType]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)shouldShowEarphoneAlert
{
    // 用户如果没有带耳机，则应该提出提示，目前采用保守策略，即尽量减少alert弹出，所以，我们认为只要不是用手机内置的听筒或者喇叭作为声音外放的，都认为用户带了耳机
    NSArray *outputs = self.currentRoute.outputs;
    NSArray *headSetOutputRoutes = @[AVAudioSessionPortBuiltInReceiver, AVAudioSessionPortBuiltInSpeaker];
    for (AVAudioSessionPortDescription *description in outputs) {
        if ([headSetOutputRoutes containsObject:description.portType]) {
            return YES;
        }
    }
    return NO;
}

@end
