//
//  MHAudioRecoder.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import "MHAudioRecoder.h"
#import "MHAudioSession.h"
#import "MHUtil.h"
/**
 * Setup AudioSession
 *  1: Category
 *  2: Set Listener
 *      Interrupt Listener
 *      AudioRoute Change Listener
 *      Hardwate output Volume Listener
 *  3: Set IO BufferDuration
 *  4: Active AudioSession
 *
 * Setup AudioUnit
 *  1:Build AudioComponentDescription To Build AudioUnit Instance
 *  2:Build AudioStreamBasicDescription To Set AudioUnit Property
 *  3:Connect Node Or Set RenderCallback For AudioUnit
 *  4:Initialize AudioUnit
 *  5:Initialize AudioUnit
 *  6:AudioOutputUnitStart
 *
 **/

@interface MHAudioRecoder ()
{
    AudioUnitElement ioInputElement;
    AudioUnitElement ioOutputElement;
    Float64 sampleRate;
    NSString * _destinationFilepath;
    ExtAudioFileRef _finalAudioFile;
}
@property(nonatomic,assign)AUGraph auGraph;
@property(nonatomic,assign)AUNode ioNode;
@property(nonatomic,assign)AudioUnit ioUnit;
@property(nonatomic,assign)AUNode convertNode;
@property(nonatomic,assign)AudioUnit convertUnit;

@end

@implementation MHAudioRecoder

-(instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        ioInputElement = 1;
        ioOutputElement = 0;
        sampleRate = 44100.0;
        _destinationFilepath = path;

        [self setupAudioSession];
        
        [self setupAudioUnitGraph];
    }
    return self;
}
#pragma mark - 初始化 AudioSession
-(void)setupAudioSession
{
    MHAudioSession.sharedInstance.category = AVAudioSessionCategoryPlayAndRecord;
    MHAudioSession.sharedInstance.preferredSampleRate = sampleRate;
    MHAudioSession.sharedInstance.active = YES;
    [MHAudioSession.sharedInstance addRouteChangeListener];
    // 添加被打断的通知
    [self addAudioSessionInterruptedNoti];
}
#pragma mark - 初始化 AudioUnitGraph
-(void)setupAudioUnitGraph
{
    //创建AUGraph
    //声明并实例化一个AUGraph
    OSStatus status = NewAUGraph(&_auGraph);
    CheckStatus(status, @"Could not create a new AUGraph");
    //按照AudioUnit的描述在AUGraph中增加一个AUNode
    [self addAudioUnitNodes];
    //打开AUGraph 其实打开AUGraph的过程也是间接实例化AUGraph中所有的AUNode 注意:必须在获取AudioUnit之前打开整个 AUGraph，否则我们将不能从对应的 AUNode 中获取正确的 AudioUnit
    status = AUGraphOpen(_auGraph);
    CheckStatus(status, @"Could not open AUGraph");
    //在AUGraph中的某个Node里获得AudioUnit引用
    [self getUnitsFromNodes];
    //设置AudioUnit属性
    [self setAudioUnitProperties];
    //连接 AudioUnit AUNode
    [self makeNodeConnections];
    
    CAShow(_auGraph);
    status = AUGraphInitialize(_auGraph);
    CheckStatus(status, @"Counld not initialize AUGraph");
}
-(void)addAudioUnitNodes
{
    OSStatus status;
    AudioComponentDescription ioDesp = mh_audioComponentDescription(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
    status = AUGraphAddNode(_auGraph, &ioDesp, &_ioNode);
    CheckStatus(status, @"Could not add I/O Node to AUGraph");
    
    AudioComponentDescription converterDesp = mh_audioComponentDescription(kAudioUnitType_FormatConverter, kAudioUnitSubType_AUConverter, kAudioUnitManufacturer_Apple);
    status = AUGraphAddNode(_auGraph, &converterDesp, &_convertNode);
    CheckStatus(status, @"Could not add convert Node to AUGraph");
}

-(void)getUnitsFromNodes
{
    OSStatus status;
    status = AUGraphNodeInfo(_auGraph, _ioNode, NULL, &_ioUnit);
    CheckStatus(status, @"Could not get AudioUnit from I/O node");
    status = AUGraphNodeInfo(_auGraph, _convertNode, NULL, &_convertUnit);
    CheckStatus(status, @"Could not get AudioUnit from convert node");
}
-(void)setAudioUnitProperties
{
    OSStatus status;
    AudioStreamBasicDescription pcmSreamFormat = k_noninterleavedPCMFormatWithChannels(2);
    
    UInt32 bytesPerSample = sizeof (Float32);
    AudioStreamBasicDescription _clientFormat32float;
    _clientFormat32float.mFormatID = kAudioFormatLinearPCM;
    _clientFormat32float.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    _clientFormat32float.mBytesPerPacket = bytesPerSample;
    _clientFormat32float.mFramesPerPacket = 1;
    _clientFormat32float.mBytesPerFrame = bytesPerSample;
    _clientFormat32float.mChannelsPerFrame = 2;
    _clientFormat32float.mBitsPerChannel = 8 * bytesPerSample;
    _clientFormat32float.mSampleRate = sampleRate;
    
    UInt32 enableIO = 1;
    status = AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, ioInputElement, &enableIO, sizeof(enableIO));
    CheckStatus(status, @"Could not set enable I/O on I/O unit input scope");
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, ioInputElement, &pcmSreamFormat, sizeof(pcmSreamFormat));
    CheckStatus(status, @"Could not set streamFormat on I/O unit output scope");
    
//    AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, ioOutputElement, &_clientFormat32float, sizeof(_clientFormat32float));
    
 
    AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &pcmSreamFormat, sizeof(pcmSreamFormat));
    AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_clientFormat32float, sizeof(_clientFormat32float));
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &sampleRate, sizeof(sampleRate));
}
static OSStatus renderCallBack(void * inRefCon, AudioUnitRenderActionFlags * ioActionFlags, const AudioTimeStamp * inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList * __nullable ioData)
{
    OSStatus status = noErr;
    __unsafe_unretained MHAudioRecoder * this = (__bridge MHAudioRecoder *)inRefCon;
    // 从 _mixerUnit 获取数据
    AudioUnitRender(this->_convertUnit, ioActionFlags, inTimeStamp, 0, inNumberFrames, ioData);
    // 将数据写入_finalAudioFile
    status = ExtAudioFileWriteAsync(this->_finalAudioFile, inNumberFrames, ioData);
    return status;
}
-(void)makeNodeConnections
{
    OSStatus status = noErr;
    status = AUGraphConnectNodeInput(_auGraph, _ioNode, 1, _convertNode, 0);
    CheckStatus(status, @"Could not connect I/O node to convert node");
    
    AURenderCallbackStruct finalRenderProc;
    finalRenderProc.inputProc = &renderCallBack;
    finalRenderProc.inputProcRefCon = (__bridge void*)self;
    status = AUGraphSetNodeInputCallback(_auGraph, _ioNode, 0, &finalRenderProc);
    CheckStatus(status, @"Counld not set inputCallBack for I/O node");
}
-(void)prepareFinalWriteFile
{
    AudioStreamBasicDescription destinationFormat;
    destinationFormat.mFormatID = kAudioFormatLinearPCM;
    destinationFormat.mSampleRate = sampleRate;
    // if we want pcm, default to signed 16-bit little-endian
    destinationFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    destinationFormat.mBitsPerChannel = 8 * 2;
    destinationFormat.mChannelsPerFrame = 2;
    destinationFormat.mFramesPerPacket = 1;
    destinationFormat.mBytesPerFrame = destinationFormat.mBitsPerChannel / 8 * destinationFormat.mChannelsPerFrame;
    destinationFormat.mBytesPerPacket = destinationFormat.mBytesPerFrame * destinationFormat.mFramesPerPacket;
    
    UInt32 size = sizeof(destinationFormat);
    OSStatus result = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
    CheckStatus(result, @"AudioFormatGetProperty failed");
    
    // 路径
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)_destinationFilepath,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    // 创建文件--指定文件格式 .caf
    result = ExtAudioFileCreateWithURL(destinationURL,
                                       kAudioFileCAFType,
                                       &destinationFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &_finalAudioFile);
    CheckStatus(result, @"ExtAudioFileCreateWithURL failed");
    CFRelease(destinationURL);
    
    AudioStreamBasicDescription clientFormat;
    UInt32 fSize = sizeof(clientFormat);
    memset(&clientFormat, 0, fSize);
    // 从output unit 获取音频数据格式
    result = AudioUnitGetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &clientFormat, &fSize);
    CheckStatus(result, @"AudioUnitGetProperty failed");
    // 设置音频数据格式
    result = ExtAudioFileSetProperty(_finalAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat);
    CheckStatus(result, @"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    // 指定编解码器
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    result = ExtAudioFileSetProperty(_finalAudioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(codec), &codec);
    CheckStatus(result, @"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer failed");
    // 写入数据
    result = ExtAudioFileWriteAsync(_finalAudioFile, 0, NULL);
    CheckStatus(result, @"ExtAudioFileWriteAsync Failed");
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
            [self start];
            break;
        default:
            break;
    }
}
-(void)start
{
    [self prepareFinalWriteFile];
    OSStatus status = AUGraphStart(_auGraph);
    CheckStatus(status, @"Could not start AUGraph");
}
-(void)stop
{
    OSStatus status = AUGraphStop(_auGraph);
    CheckStatus(status, @"Could not stop AUGraph");
    ExtAudioFileDispose(_finalAudioFile);
}
-(void)dealloc
{
    [self destoryAudioUnitFraph];
}
-(void)destoryAudioUnitFraph
{
    AUGraphStop(_auGraph);
    AUGraphUninitialize(_auGraph);
    AUGraphClose(_auGraph);
    AUGraphRemoveNode(_auGraph, _convertNode);
    AUGraphRemoveNode(_auGraph, _ioNode);
    DisposeAUGraph(_auGraph);
    _ioUnit = NULL;
    _ioNode = 0;
    _convertUnit = NULL;
    _convertNode = 0;
    _auGraph = NULL;
}
/// 非交错左右声道音频PCM AudioStreamBasicDescription
/// @param channels 声道数
AudioStreamBasicDescription k_noninterleavedPCMFormatWithChannels(UInt32 channels)
{
    UInt32 bytePerSample = sizeof(SInt32);
    
    AudioStreamBasicDescription asbd;
    bzero(&asbd, sizeof(asbd));
    asbd.mFormatID = kAudioFormatLinearPCM; //编码格式
    asbd.mSampleRate = 44100.0; // 采样率
    asbd.mChannelsPerFrame = channels; //声道数
    asbd.mFramesPerPacket = 1; //每个 Packet有几个 Frame
    /**
     描述声音表示格式的参数
     ：第一个参数指定每个sample的表示格式是Float格式;
     ：第二个参数Noninterleaved，字面理解这个单词 的意思是非交错的，其实对于音频来讲就是左右声道是非交错存放的，实际的音频 数据会存储在一个 AudioBufferList结构中的变量 mBuffers 中，如果 mFormatFlags 指 定 的 是 Nonlnterleaved， 那么左声道就会在 mBuffers[O]里面，右 声道 就 会 在 mBuffers[l]里面;而如果 mFormatFlags 指定的是 Interleaved 的话，那么左右声道就 会交错排列在 mBuffers[O] 里面
     */
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
//    asbd.mFormatFlags = kAudioFormatFlagsAudioUnitCanonical | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel = 8 * bytePerSample; //一个声道的音频数据用多少位来表示
    /**
     参数mBytesPerFrame 和 mBytesPerPacket 的赋值，需要根据 mFormatFlags 的值来进行分配
     --如果在 Noninterleaved 的情况下，就赋值为 bytesPerSample (因为左 右声道是分开存放的 )
     --但如果是 Interleaved 的话，那么就应该是 bytesPerSample * channels (因为左右声道是交错存放的 )，这样才能表示一个 Frame里面到底有多少个 byte
     */
    asbd.mBytesPerFrame = bytePerSample;
    asbd.mBytesPerPacket = bytePerSample;
    return asbd;
}
@end
