//
//  MHAUGraphPlayer.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHAUGraphPlayer : NSObject

-(instancetype)initWithPath:(NSString *)path;
-(void)play;
-(void)stop;

-(void)setInputSource:(BOOL)isAcc;

@end

NS_ASSUME_NONNULL_END
