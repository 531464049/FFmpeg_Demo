//
//  MHVideoDecoder.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "MHDecoderModel.h"

NS_ASSUME_NONNULL_BEGIN

@class MHVideoDecoder;
@protocol MHVideoDecoderDelegate <NSObject>

@end


@interface MHVideoDecoder : NSObject

@property(nonatomic,weak)id <MHVideoDecoderDelegate> delegate;

@property(nonatomic,assign,readonly)BOOL isFileOpend;
@property(nonatomic,assign,readonly)BOOL isEndOfFile;

-(instancetype)initWith:(MHAudioDecodeParameter *)parameter;

-(void)openFile:(NSString *)filePath;

-(NSArray *)decodeFrames:(CGFloat)minDuration;

-(void)destoryDecoder;

@end

NS_ASSUME_NONNULL_END
