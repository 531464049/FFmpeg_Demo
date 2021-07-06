//
//  MHAudioRecoder.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHAudioRecoder : NSObject

-(instancetype)initWithPath:(NSString *)path;
-(void)start;
-(void)stop;

@end

NS_ASSUME_NONNULL_END
