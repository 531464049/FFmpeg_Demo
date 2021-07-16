//
//  MHVideoDecoder.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/7.
//

#import "MHVideoDecoder.h"
#import "MHFFmpegUtil.h"
#import <Accelerate/Accelerate.h>
#import "MHUtil.h"

@interface MHVideoDecoder ()
{
    MHAudioDecodeParameter * _audioParameter;
    
    AVFormatContext * pFormatCtx;
    
    int _videoStreamIndex;
    AVCodecContext * pVideoCodecCtx;
    struct SwsContext * pVideoSwsCtx;
    AVFrame * _tempVideoFrame;
    AVFrame * _videoFrame;
    float _fps;
    float _videoTimeBase;
    
    int _audioStreamIndex;
    AVCodecContext * pAudioCodecCtx;
    struct SwrContext * pAudioSwrCtx;
    AVFrame * _audioFrame;
    float _audioTimeBase;
    
    AVPacket * _packet;
    BOOL _isDecoding;
}
@end

@implementation MHVideoDecoder

-(instancetype)initWith:(MHAudioDecodeParameter *)parameter
{
    self = [super init];
    if (self) {
        _audioParameter = parameter;
        _isDecoding = NO;
        _isEndOfFile = NO;
        _duration = 0.0;
        _position = 0.0;
    }
    return self;
}
-(void)openFile:(NSString *)filePath
{
//    //注册所有编解码器
//    avcodec_register_all();
//    //初始化格式及传输协议
//    av_register_all();
//    //初始化全局网络组件
//    avformat_network_init();
    const char* fileUrl = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    AVDictionary * opts = 0;
    BOOL isTcp = NO;
    if (isTcp) {
        av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    }
    //根据URL打开输入流 并获取头部信息
    pFormatCtx = avformat_alloc_context();
    int result = avformat_open_input(&pFormatCtx, fileUrl, NULL, &opts);
    if (result != 0) {
        NSLog(@"Could not open file");
        avformat_free_context(pFormatCtx);
        return;
    }
    
    //检索视频流信息
    result = avformat_find_stream_info(pFormatCtx, NULL);
    if (result < 0) {
        NSLog(@"avformat_find_stream_info error, %s", av_err2str(result));
        return;
    }
    //打印文件信息
    av_dump_format(pFormatCtx, 0, fileUrl, false);
    //找到视频音频流索引位置
    result = [self findVideoAduioStreamIndex];
    if (result < 0) {
        NSLog(@"Could not find video audio stream");
        return;
    }
    
    // 打开视频流
    result = [self openVideoStream];
    if (result < 0) {
        NSLog(@"open video stream fail ...");
        return;
    }
    // 打开音频流
    result = [self openAudioStream];
    if (result < 0) {
        NSLog(@"open audio stream fail ...");
    }
    //获取视频时长
    if (pFormatCtx->duration == AV_NOPTS_VALUE) {
        _duration = MAXFLOAT;
    }else{
        _duration = (float)(pFormatCtx->duration / AV_TIME_BASE);
    }
    //初始化 AVPacket
    _packet = av_packet_alloc();
    //文件打开
    _isFileOpend = YES;
}
#pragma mark - 确认音视频流下标
-(int)findVideoAduioStreamIndex
{
    _videoStreamIndex = _audioStreamIndex = -1;
    for (int i = 0; i < pFormatCtx->nb_streams; i ++) {
        enum DS_AVMediaType codecType = pFormatCtx->streams[i]->codecpar->codec_type;
        if (codecType == AVMEDIA_TYPE_VIDEO) {
            NSLog(@"Find video stream");
            _videoStreamIndex = i;
        }else if (codecType == AVMEDIA_TYPE_AUDIO) {
            NSLog(@"Find audio stream");
            _audioStreamIndex = i;
        }
    }
    if (_videoStreamIndex == -1 && _audioStreamIndex == -1) {
        return -1;
    }
    return 0;
}
#pragma mark - 根据流下标 获取编解码器
-(AVCodecContext *)setupAVCodecContext:(int)streamIndex
{
    if (streamIndex < 0) {
        return NULL;
    }
    //获取一个指向视频音频流编解码器的信息
    AVCodecParameters *codecpar = pFormatCtx->streams[streamIndex]->codecpar;
    //根据解码器信息，获取解码器ID，查找解码器
    AVCodec * pCodec = avcodec_find_decoder(codecpar->codec_id);
    if (pCodec == NULL) {
        NSLog(@"Could not find audio AVCodec");
        return NULL;
    }
    //解码器上下文
    AVCodecContext * codecCtx = avcodec_alloc_context3(pCodec);
    if (avcodec_parameters_to_context(codecCtx, codecpar) < 0) {
        NSLog(@"Could not set AVCodecContext");
        return NULL;
    }
    //打开解码器
    if(avcodec_open2(codecCtx, pCodec, NULL) < 0) {
        NSLog(@"Could not open avcodec");
        return NULL;
    }
    return codecCtx;
}
#pragma mark - 打开视频流
-(int)openVideoStream
{
    pVideoCodecCtx = [self setupAVCodecContext:_videoStreamIndex];
    if (pVideoCodecCtx == NULL) {
        return -1;
    }
    
    pVideoSwsCtx = sws_getContext(pVideoCodecCtx->width,
                            pVideoCodecCtx->height,
                            pVideoCodecCtx->pix_fmt,
                            pVideoCodecCtx->width,
                            pVideoCodecCtx->height,
                            AV_PIX_FMT_YUV420P,
                            SWS_BICUBIC, NULL, NULL, NULL);
    
    _tempVideoFrame = av_frame_alloc();
    //初始化yuv420p视频像素数据格式缓冲区(一帧数据)
    _videoFrame = alloc_image(AV_PIX_FMT_YUV420P, pVideoCodecCtx->width, pVideoCodecCtx->height);
    
    AVStream * videoStream = pFormatCtx->streams[_videoStreamIndex];
    avStreamFPSTimeBase(videoStream, 0.04, &_fps, &_videoTimeBase);
    NSLog(@"video----fps:%f timeBase:%f",_fps,_videoTimeBase);
    return 0;
}
#pragma mark - 打开音频流
-(int)openAudioStream
{
    pAudioCodecCtx = [self setupAVCodecContext:_audioStreamIndex];
    if (pAudioCodecCtx == NULL) {
        return -1;
    }
    
    pAudioSwrCtx = swr_alloc_set_opts(NULL,
                                      av_get_default_channel_layout(_audioParameter.channels),
                                      AV_SAMPLE_FMT_S16,
                                      _audioParameter.sampleRate,
                                      av_get_default_channel_layout(pAudioCodecCtx->channels),
                                      pAudioCodecCtx->sample_fmt,
                                      pAudioCodecCtx->sample_rate, 0, NULL);
    swr_init(pAudioSwrCtx);
    _audioFrame = av_frame_alloc();
    
    AVStream * audioStream = pFormatCtx->streams[_audioStreamIndex];
    avStreamFPSTimeBase(audioStream, 0.025, 0, &_audioTimeBase);
    NSLog(@"audio----timeBase:%f",_videoTimeBase);
    return 0;
}
#pragma mark - 初始化视频帧数格式缓冲区
AVFrame * alloc_image(enum AVPixelFormat pix_fmt, int width, int height)
{
    AVFrame *frame ;
    uint8_t *frame_buf;
    int size;
    
    frame = av_frame_alloc();
    frame->width = width;
    frame->height = height;
    frame->format = pix_fmt;
    if (!frame) return NULL;
    size = av_image_get_buffer_size(pix_fmt, width, height, 1);
    frame_buf = (uint8_t *)av_malloc(size);
    if (!frame_buf){
        av_frame_free(&frame);
        return NULL;
    }
    av_image_fill_arrays(frame->data, frame->linesize, frame_buf, pix_fmt, width, height, 1);
    return frame;
}
-(NSArray *)decodeFrames:(CGFloat)minDuration
{
    if (_isDecoding || !_isFileOpend) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    _isDecoding = YES;
    av_packet_unref(_packet);
    bool finished = false;
    float decodedDuration = 0;
    while (!_isEndOfFile && !finished) {
        @autoreleasepool {
            int re = av_read_frame(pFormatCtx, _packet);
            if (re < 0) {
                NSLog(@"read the next frame of a stream on error or end of file");
                finished = true;
                _isEndOfFile = YES;
                continue;
            }
            MHMovieFrame * frame;
            if (_packet->stream_index == _videoStreamIndex) {
                frame = [self decodeVideo:_packet];
                _position = frame.position;
            }else if (_packet->stream_index == _audioStreamIndex) {
                frame = [self decodeAudio:_packet];
            }
            if (frame) {
                //NSLog(@"当前帧的时间戳:%f, 当前帧的持续时间:%f", frame.position, frame.duration);
                [result addObject:frame];
                decodedDuration += frame.duration;
                if (decodedDuration > minDuration) {
                    finished = YES;
                }
            }
        }
    }
    _isDecoding = NO;
    return result;
}
-(void)updatePosition:(float)position
{
    _position = position;
    _isEndOfFile = NO;
    if (_videoStreamIndex != -1) {
        int64_t ts = (int64_t)(position / _videoTimeBase);
        avformat_seek_file(pFormatCtx, _videoStreamIndex, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(pVideoCodecCtx);
    }
    if (_audioStreamIndex != -1) {
        int64_t ts = (int64_t)(position / _audioTimeBase);
        avformat_seek_file(pFormatCtx, _audioStreamIndex, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(pAudioCodecCtx);
    }
}
-(MHVideoFrame *)decodeVideo:(AVPacket *)packet
{
    //视频--解码
    av_frame_unref(_tempVideoFrame);
    int re = avcodec_send_packet(pVideoCodecCtx, packet);
    if (re != 0) {
        NSLog(@"video avcodec_send_packet failed : %s",av_err2str(re));
        return nil;
    }
    re = avcodec_receive_frame(pVideoCodecCtx, _tempVideoFrame);
    if (re != 0) {
        NSLog(@"video avcodec_receive_frame failed : %s",av_err2str(re));
        return nil;
    }
    //解码成功--进行类型转换: 将解码出来的视频像素点数据格式->统一转类型为yuv420P
    sws_scale(pVideoSwsCtx,
              (const uint8_t *const *)_tempVideoFrame->data,
              _tempVideoFrame->linesize,
              0,
              pVideoCodecCtx->height,
              _videoFrame->data,
              _videoFrame->linesize);
    _videoFrame->best_effort_timestamp = _tempVideoFrame->best_effort_timestamp;
    _videoFrame->pkt_duration = _tempVideoFrame->pkt_duration;
    _videoFrame->repeat_pict = _tempVideoFrame->repeat_pict;
    
    MHVideoFrame * frame = [self handleVideoFrame];
    return frame;
}
-(MHVideoFrame *)handleVideoFrame
{
    if (!_videoFrame->data[0]) {
        return nil;
    }
    MHVideoFrame * frame = [[MHVideoFrame alloc] init];
    frame.luma = [frame copyFrameData:_videoFrame->data[0] lineSize:_videoFrame->linesize[0] width:_videoFrame->width height:_videoFrame->height];
    frame.chromaB = [frame copyFrameData:_videoFrame->data[1] lineSize:_videoFrame->linesize[1] width:_videoFrame->width/2 height:_videoFrame->height/2];
    frame.chromaR = [frame copyFrameData:_videoFrame->data[2] lineSize:_videoFrame->linesize[2] width:_videoFrame->width/2 height:_videoFrame->height/2];
    frame.width = _videoFrame->width;
    frame.height = _videoFrame->height;
    // 以流中的时间为基础 预估的时间戳
    frame.position = _videoFrame->best_effort_timestamp * _videoTimeBase;
    //当前帧的持续时间
    int64_t frameDuration = _videoFrame->pkt_duration;
    if (frameDuration) {
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
    }else{
        frame.duration = 1.0 / _fps;
    }
    return frame;
}
-(MHAudioFrame *)decodeAudio:(AVPacket *)packet
{
    av_frame_unref(_audioFrame);
    int re = avcodec_send_packet(pAudioCodecCtx, packet);
    if (re != 0) {
        NSLog(@"audio avcodec_send_packet failed : %s",av_err2str(re));
        return nil;
    }
    re = avcodec_receive_frame(pAudioCodecCtx, _audioFrame);
    if (re != 0) {
        NSLog(@"audio avcodec_receive_frame failed : %s",av_err2str(re));
        return nil;
    }
    MHAudioFrame * frame = [self handleAudioFrame];
    if (frame.samples == NULL) {
        return nil;
    }
    return frame;
}
-(MHAudioFrame *)handleAudioFrame
{
    if (!_audioFrame->data[0]) {
        return nil;
    }
    int numChannels = _audioParameter.channels;
    int ratio = MAX(1, _audioParameter.sampleRate/pAudioCodecCtx->sample_rate) * MAX(1, _audioParameter.channels/pAudioCodecCtx->channels) * 2;
    int bufSize = av_samples_get_buffer_size(NULL,
                                                   numChannels,
                                                   _audioFrame->nb_samples*ratio,
                                                   AV_SAMPLE_FMT_S16,
                                                   1);
    void * swrBuffer = (void *)malloc(bufSize);
    Byte * outBuf[2] = {swrBuffer, 0};
    int numSamples = swr_convert(pAudioSwrCtx, outBuf, _audioFrame->nb_samples*ratio, (const uint8_t **)_audioFrame->data, _audioFrame->nb_samples);
    if (numSamples < 0) {
        NSLog(@"failed to reSet audio sample");
        return nil;
    }

    int numElements = numSamples * numChannels;
    void * data = (void *)malloc(numElements * sizeof(float));

    float scale = 1.0 / (float)INT16_MAX;
    vDSP_vflt16((SInt16 *)swrBuffer, 1, data, 1, numElements);
    vDSP_vsmul(data, 1, &scale, data, 1, numElements);

//    int numElements = _audioParameter.samplingRate * _audioParameter.numOutputChannels;
//    void * data = (void *)malloc(numElements * sizeof(float));
//    memcpy(data, _audioFrame->data, numElements * sizeof(float));
    
    MHAudioFrame * frame = [[MHAudioFrame alloc] init];
    frame.position = _audioFrame->best_effort_timestamp * _audioTimeBase;
    frame.duration = _audioFrame->pkt_duration * _audioTimeBase;
    frame.samples = data;
    frame.samplesLength = numElements * sizeof(float);
    if (frame.duration == 0) {
        frame.duration = frame.samplesLength / (sizeof(float) * numChannels * _audioParameter.sampleRate);
    }
    
    free(swrBuffer);
    swrBuffer = NULL;
    return frame;
}
-(void)destoryDecoder
{
    _isEndOfFile = YES;
    av_packet_free(&_packet);
    av_frame_free(&_tempVideoFrame);
    av_frame_free(&_videoFrame);
    av_frame_free(&_audioFrame);
    avcodec_close(pVideoCodecCtx);
    pVideoCodecCtx = NULL;
    avcodec_close(pAudioCodecCtx);
    pAudioCodecCtx = NULL;
    sws_freeContext(pVideoSwsCtx);
    swr_free(&pAudioSwrCtx);
    avformat_close_input(&pFormatCtx);
    avformat_free_context(pFormatCtx);
    pFormatCtx = NULL;
}
-(void)dealloc
{
    NSLog(@"MHVideoDecoder--dealloc");
}
static void avStreamFPSTimeBase(AVStream *st, float defaultTimeBase, float *pFPS, float *pTimeBase)
{
    float fps, timebase;
    // ffmpeg提供了一个把AVRatioal结构转换成double的函数
    // 默认0.04 意思就是25帧
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else
        timebase = defaultTimeBase;

    // 平均帧率
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;

    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}
@end
