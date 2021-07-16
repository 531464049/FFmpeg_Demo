//
//  MHAudioPlayer.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/14.
//

#import "MHAudioPlayer.h"
#import "MHAudioSession.h"
#import "MHUtil.h"
#import <Accelerate/Accelerate.h>

@interface MHAudioPlayer ()
{
    float * _outData;
    MHAudioDecodeParameter * _parameter;
}
@property(nonatomic,assign)AUGraph mPlayerGraph;
@property(nonatomic,assign)AUNode mIONode;
@property(nonatomic,assign)AudioUnit mIOUnit;
@end

@implementation MHAudioPlayer

-(instancetype)initWith:(MHAudioDecodeParameter *)parameter
{
    self = [super init];
    if (self) {
        _parameter = parameter;
        size_t maxDataSize = 4096 * 2 * sizeof(float);
        _outData = (float *)malloc(maxDataSize);
        [self setupAudioSession];
        [self setupAUGraph];
    }
    return self;
}
-(void)setupAudioSession
{
    MHAudioSession.sharedInstance.category = AVAudioSessionCategoryPlayAndRecord;
    MHAudioSession.sharedInstance.preferredSampleRate = 44100.0;
    MHAudioSession.sharedInstance.active = YES;
    [MHAudioSession.sharedInstance addRouteChangeListener];
}
-(void)setupAUGraph
{
    OSStatus status = noErr;
    //构造AUGraph
    status = NewAUGraph(&_mPlayerGraph);
    CheckStatus(status, @"Could not create AUGraph");

    //添加 i/o nodes
    AudioComponentDescription ioDesc = mh_audioComponentDescription_AppleManufacturer(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO);
    status = AUGraphAddNode(_mPlayerGraph, &ioDesc, &_mIONode);
    
    //打开AUGraph
    status = AUGraphOpen(_mPlayerGraph);
    CheckStatus(status, @"Could not open AUGraph");
    //获取AudioUnit
    AUGraphNodeInfo(_mPlayerGraph, _mIONode, NULL, &_mIOUnit);
    
    //设置参数
    AudioStreamBasicDescription asbd = _parameter.asbd;
    AudioUnitSetProperty(_mIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    
    //连接node
    AURenderCallbackStruct finalRenderProc;
    finalRenderProc.inputProc = &renderCallBack;
    finalRenderProc.inputProcRefCon = (__bridge void*)self;
    status = AUGraphSetNodeInputCallback(_mPlayerGraph, _mIONode, 0, &finalRenderProc);
    CheckStatus(status, @"Counld not set inputCallBack for I/O node");
    
    //初始化Graph
    status = AUGraphInitialize(_mPlayerGraph);
    CheckStatus(status, @"Couldn't Initialize the graph");
}
-(OSStatus)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData
{
    for (int i = 0; i < ioData->mNumberBuffers; i ++) {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    if (!_isPlaying || !self.inputBlock) {
        return noErr;
    }
    
    self.inputBlock(_outData, numFrames, _parameter.channels);
    if (_parameter.bytesPerSample == 4) {
        float zero = 0.0;
        for (int i = 0; i < ioData->mNumberBuffers; i ++) {
            int numChannels = ioData->mBuffers[i].mNumberChannels;
            for (int iChannel = 0; iChannel < numChannels; iChannel ++) {
                vDSP_vsadd(_outData+iChannel, _parameter.channels, &zero, (float *)ioData->mBuffers[i].mData, numChannels, numFrames);
            }
        }
    }else if (_parameter.bytesPerSample == 2) {
        //convert SInt16 -> Float (and scale)
        float scale = (float)INT16_MAX;
        vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames*_parameter.channels);
        for (int i = 0; i < ioData->mNumberBuffers; i ++) {
            int numChannels = ioData->mBuffers[i].mNumberChannels;
            for (int iChannel = 0; iChannel < numChannels; iChannel ++) {
                vDSP_vfix16(_outData+iChannel, _parameter.channels, (SInt16 *)ioData->mBuffers[i].mData+iChannel, numChannels, numFrames);
            }
        }
    }
    
    return noErr;
}
static OSStatus renderCallBack(void * inRefCon, AudioUnitRenderActionFlags * ioActionFlags, const AudioTimeStamp * inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList * __nullable ioData)
{
    __unsafe_unretained MHAudioPlayer * this = (__bridge MHAudioPlayer *)inRefCon;
    return [this renderFrames:inNumberFrames ioData:ioData];
}
-(void)play
{
    OSStatus status = AUGraphStart(_mPlayerGraph);
    CheckStatus(status, @"start play");
    _isPlaying = status == noErr;
}
-(void)stop
{
    Boolean isRunning = false;
    OSStatus status = AUGraphIsRunning(_mPlayerGraph, &isRunning);
    if (isRunning) {
        status = AUGraphStop(_mPlayerGraph);
        CheckStatus(status, @"stop ");
    }
    _isPlaying = NO;
}
-(void)destoryAudioUnitFraph
{
    AUGraphStop(_mPlayerGraph);
    AUGraphUninitialize(_mPlayerGraph);
    AUGraphClose(_mPlayerGraph);
    AUGraphRemoveNode(_mPlayerGraph, _mIONode);
    DisposeAUGraph(_mPlayerGraph);
    _mIOUnit = NULL;
    _mIONode = 0;
    _mPlayerGraph = NULL;
    if (_outData) {
        free(_outData);
    }
}
-(void)destoryPlayer
{
    [self destoryAudioUnitFraph];
}
-(void)dealloc
{
    NSLog(@"MHAudioPlayer--dealloc");
}
@end
