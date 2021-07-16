//
//  Mp3Encoder.hpp
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/28.
//

#ifndef Mp3Encoder_h
#define Mp3Encoder_h

#include <stdio.h>
#include "lame.h"

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
}

class Mp3Encoder {
private:
    FILE * pcmFile;
    FILE * mp3File;
    lame_t lameClient;
public:
    bool Init(const char * pcmFilePath,const char * mp3FilePath, int sampleRate, int channels, int bitRate);
    void Encode();
    void Destory();
};

#endif /* Mp3Encoder_hpp */
