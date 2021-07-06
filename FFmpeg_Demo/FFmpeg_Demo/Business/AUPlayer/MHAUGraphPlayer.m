//
//  MHAUGraphPlayer.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/5.
//

#import "MHAUGraphPlayer.h"
#import "MHAudioSession.h"
#import "MHUtil.h"

@interface MHAUGraphPlayer ()

@property(nonatomic,assign)AUGraph          mPlayerGraph;

@property(nonatomic,assign)AUNode           mFileNode;
@property(nonatomic,assign)AudioUnit        mFileUnit;

@property(nonatomic,assign)AUNode           mSplitterNode;
@property(nonatomic,assign)AudioUnit        mSplitterUnit;

@property(nonatomic,assign)AUNode           mAccMixerNode;
@property(nonatomic,assign)AudioUnit        mAccMixerUnit;

@property(nonatomic,assign)AUNode           mVocalMixerNode;
@property(nonatomic,assign)AudioUnit        mVocalMixerUnit;

@property(nonatomic,assign)AUNode           mPlayerIONode;
@property(nonatomic,assign)AudioUnit        mPlayerIOUnit;

@property(nonatomic,copy)NSURL *            playPath;

@end

@implementation MHAUGraphPlayer
-(instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        [self setupAudioSession];
        _playPath = [NSURL URLWithString:path];
        
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
    
    // 添加被打断的通知
    [self addAudioSessionInterruptedNoti];
}
-(void)setupAUGraph
{
    OSStatus status = noErr;
    //构造AUGraph
    status = NewAUGraph(&_mPlayerGraph);
    CheckStatus(status, @"Could not create AUGraph");
    // 添加 fileNode
    AudioComponentDescription playerDesc = mh_audioComponentDescription_AppleManufacturer(kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer);
    status = AUGraphAddNode(_mPlayerGraph, &playerDesc, &_mFileNode);
    // 添加 SplitterNode
    AudioComponentDescription splitterDesc = mh_audioComponentDescription_AppleManufacturer(kAudioUnitType_FormatConverter, kAudioUnitSubType_Splitter);
    status = AUGraphAddNode(_mPlayerGraph, &splitterDesc, &_mSplitterNode);
    // 添加Mixer
    AudioComponentDescription mixDesc = mh_audioComponentDescription_AppleManufacturer(kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer);
    status = AUGraphAddNode(_mPlayerGraph, &mixDesc, &_mVocalMixerNode);
    status = AUGraphAddNode(_mPlayerGraph, &mixDesc, &_mAccMixerNode);
    //添加 i/o nodes
    AudioComponentDescription ioDesc = mh_audioComponentDescription_AppleManufacturer(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO);
    status = AUGraphAddNode(_mPlayerGraph, &ioDesc, &_mPlayerIONode);
    
    //打开AUGraph
    status = AUGraphOpen(_mPlayerGraph);
    CheckStatus(status, @"Could not open AUGraph");
    //获取AudioUnit
    AUGraphNodeInfo(_mPlayerGraph, _mFileNode, NULL, &_mFileUnit);
    AUGraphNodeInfo(_mPlayerGraph, _mSplitterNode, NULL, &_mSplitterUnit);
    AUGraphNodeInfo(_mPlayerGraph, _mVocalMixerNode, NULL, &_mVocalMixerUnit);
    AUGraphNodeInfo(_mPlayerGraph, _mAccMixerNode, NULL, &_mAccMixerUnit);
    AUGraphNodeInfo(_mPlayerGraph, _mPlayerIONode, NULL, &_mPlayerIOUnit);
    
    //设置参数
    AudioStreamBasicDescription asbd;
    UInt32 bytesPerSample = sizeof(Float32);
    bzero(&asbd, sizeof(asbd));
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mSampleRate = 48000.0;
    asbd.mChannelsPerFrame = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mBytesPerPacket = bytesPerSample;
    asbd.mBytesPerFrame = bytesPerSample;
    
    AudioUnitSetProperty(_mFileUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, sizeof(asbd));
    
    AudioUnitSetProperty(_mSplitterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    AudioUnitSetProperty(_mSplitterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, sizeof(asbd));
    
    int mixerElementCount = 1;
    AudioUnitSetProperty(_mVocalMixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    AudioUnitSetProperty(_mVocalMixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, sizeof(asbd));
    AudioUnitSetProperty(_mVocalMixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &mixerElementCount, sizeof(mixerElementCount));
    
    AudioUnitSetProperty(_mAccMixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    AudioUnitSetProperty(_mAccMixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, sizeof(asbd));
    mixerElementCount = 2;
    AudioUnitSetProperty(_mAccMixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &mixerElementCount, sizeof(mixerElementCount));
    
    AudioUnitSetProperty(_mPlayerIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));

    
    [self setInputSource:NO];
    
    //连接node
    AUGraphConnectNodeInput(_mPlayerGraph, _mFileNode, 0, _mSplitterNode, 0);
    
    AUGraphConnectNodeInput(_mPlayerGraph, _mSplitterNode, 0, _mVocalMixerNode, 0);
    AUGraphConnectNodeInput(_mPlayerGraph, _mVocalMixerNode, 0, _mAccMixerNode, 0);
    
    AUGraphConnectNodeInput(_mPlayerGraph, _mSplitterNode, 0, _mAccMixerNode, 1);
    
    AUGraphConnectNodeInput(_mPlayerGraph, _mAccMixerNode, 0, _mPlayerIONode, 0);
    
    //初始化Graph
    status = AUGraphInitialize(_mPlayerGraph);
    CheckStatus(status, @"Couldn't Initialize the graph");
    
    [self setupFileUnit];
}
-(void)setInputSource:(BOOL)isAcc
{
    NSLog(@"\n");
    OSStatus status = noErr;
    AudioUnitParameterValue value;
    status = AudioUnitGetParameter(_mVocalMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, &value);
    CheckStatus(status, @"get vocalMixer volume");
    NSLog(@"VocalMixer volume %lf",value);
    status = AudioUnitGetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, &value);
    CheckStatus(status, @"get accMixer 0 volume");
    NSLog(@"accMixer 0 volume %lf",value);
    status = AudioUnitGetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, &value);
    CheckStatus(status, @"get accMixer 1 volume");
    NSLog(@"accMixer 1 volume %lf",value);
    
    if (isAcc) {
        status = AudioUnitSetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, 0.1, 0);
        CheckStatus(status, @"set acc 0 volume 0.1");
        status = AudioUnitSetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, 1.0, 0);
        CheckStatus(status, @"set acc 1 volume 1.0");
    }else{
        status = AudioUnitSetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, 1.0, 0);
        CheckStatus(status, @"set acc 0 volume 1.0");
        status = AudioUnitSetParameter(_mAccMixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, 0.1, 0);
        CheckStatus(status, @"set acc 1 volume 0.1");
    }
}
-(void)setupFileUnit
{
    OSStatus status = noErr;
    // open file
    AudioFileID musicFile;
    CFURLRef songURL = (__bridge  CFURLRef) _playPath;
    status = AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &musicFile);
    CheckStatus(status, @"Could not open Music file");
    
    AudioUnitSetProperty(_mFileUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &musicFile, sizeof(musicFile));
    
    // 获取音频数据格式
    AudioStreamBasicDescription fileAsbd;
    UInt32 propSize = sizeof(fileAsbd);
    status = AudioFileGetProperty(musicFile, kAudioFilePropertyDataFormat, &propSize, &fileAsbd);
    CheckStatus(status, @"get audio file data format fail");
    UInt64 nPackets;
    propSize = sizeof(nPackets);
    status = AudioFileGetProperty(musicFile, kAudioFilePropertyAudioDataPacketCount, &propSize, &nPackets);
    
    ScheduledAudioFileRegion rgn;
    memset(&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = musicFile;
    rgn.mLoopCount = 0;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = (UInt32)nPackets * fileAsbd.mFramesPerPacket;
    status = AudioUnitSetProperty(_mFileUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &rgn, sizeof(rgn));
    CheckStatus(status, @"set regin fail");
    
    UInt32 defaultVal = 0;
    AudioUnitSetProperty(_mFileUnit, kAudioUnitProperty_ScheduledFilePrime, kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal));
    
    AudioTimeStamp startTime;
    memset(&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    status = AudioUnitSetProperty(_mFileUnit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &startTime, sizeof(startTime));
    CheckStatus(status, @"set startTime");
}
-(void)play
{
    OSStatus status = AUGraphStart(_mPlayerGraph);
    CheckStatus(status, @"start play");
}
-(void)stop
{
    Boolean isRunning = false;
    OSStatus status = AUGraphIsRunning(_mPlayerGraph, &isRunning);
    if (isRunning) {
        status = AUGraphStop(_mPlayerGraph);
        CheckStatus(status, @"stop ");
    }
}
#pragma mark - AudioSession被打断的通知
-(void)addAudioSessionInterruptedNoti
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onNotificationAudioInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
}
-(void)onNotificationAudioInterrupted:(NSNotification *)noti
{
    AVAudioSessionInterruptionType type = [[noti.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    switch (type) {
        case AVAudioSessionInterruptionTypeBegan:
            // 系统中断了AudioSession
            [self stop];
            break;
        case AVAudioSessionInterruptionTypeEnded:
            // 中断结束
            [self play];
            break;
        default:
            break;
    }
}
-(void)dealloc
{
    [self destoryAudioUnitFraph];
}
-(void)destoryAudioUnitFraph
{
    AUGraphStop(_mPlayerGraph);
    AUGraphUninitialize(_mPlayerGraph);
    AUGraphClose(_mPlayerGraph);
    AUGraphRemoveNode(_mPlayerGraph, _mFileNode);
    AUGraphRemoveNode(_mPlayerGraph, _mSplitterNode);
    AUGraphRemoveNode(_mPlayerGraph, _mAccMixerNode);
    AUGraphRemoveNode(_mPlayerGraph, _mVocalMixerNode);
    AUGraphRemoveNode(_mPlayerGraph, _mPlayerIONode);
    DisposeAUGraph(_mPlayerGraph);
    _mFileUnit = NULL;
    _mFileNode = 0;
    _mSplitterUnit = NULL;
    _mSplitterNode = 0;
    _mAccMixerUnit = NULL;
    _mAccMixerNode = 0;
    _mVocalMixerUnit = NULL;
    _mVocalMixerNode = 0;
    _mPlayerIOUnit = NULL;
    _mPlayerIONode = 0;
    _mPlayerGraph = NULL;
}
@end
