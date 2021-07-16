//
//  MHVideoDecoder.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "MHDecoderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHVideoDecoder : NSObject

@property(nonatomic,assign,readonly)float duration;
@property(nonatomic,assign,readonly)float position;
@property(nonatomic,assign,readonly)BOOL isFileOpend;
@property(nonatomic,assign,readonly)BOOL isEndOfFile;

-(instancetype)initWith:(MHAudioDecodeParameter *)parameter;

-(void)openFile:(NSString *)filePath;

-(NSArray *)decodeFrames:(CGFloat)minDuration;

-(void)updatePosition:(float)position;

-(void)destoryDecoder;

@end

NS_ASSUME_NONNULL_END
