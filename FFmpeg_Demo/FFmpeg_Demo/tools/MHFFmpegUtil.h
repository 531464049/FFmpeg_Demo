//
//  MHFFmpegUtil.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/12.
//

#import <Foundation/Foundation.h>

#include <stdio.h>
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

NS_ASSUME_NONNULL_BEGIN

@interface MHFFmpegUtil : NSObject

@end

NS_ASSUME_NONNULL_END
