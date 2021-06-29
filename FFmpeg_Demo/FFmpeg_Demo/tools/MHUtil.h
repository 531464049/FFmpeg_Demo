//
//  MHUtil.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHUtil : NSObject

+(NSString *)bundlePath:(NSString *)fileName;

+(NSString *)documentsPath:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
