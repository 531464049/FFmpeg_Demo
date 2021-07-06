//
//  MHFFmpegHeader.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/1.
//

#ifndef MHFFmpegHeader_h
#define MHFFmpegHeader_h

#include "Mp3Encoder.h"

extern "C" {
    #include "libavcodec/avcodec.h"
    #include "libavformat/avformat.h"
    #include "libavutil/avutil.h"
    #include "libavutil/samplefmt.h"
    #include "libavutil/common.h"
    #include "libavutil/channel_layout.h"
    #include "libavutil/opt.h"
    #include "libavutil/imgutils.h"
    #include "libavutil/mathematics.h"
    #include "libswscale/swscale.h"
    #include "libswresample/swresample.h"
};

//#include "libavcodec/avcodec.h"
//#include "libavformat/avformat.h"
//#include "libavutil/avutil.h"
//#include "libavutil/samplefmt.h"
//#include "libavutil/common.h"
//#include "libavutil/channel_layout.h"
//#include "libavutil/opt.h"
//#include "libavutil/imgutils.h"
//#include "libavutil/mathematics.h"
//#include "libswscale/swscale.h"
//#include "libswresample/swresample.h"

#endif /* MHFFmpegHeader_h */
