//
//  MHUtil.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHUtil : NSObject

+(NSString *)bundlePath:(NSString *)fileName;

+(NSString *)documentsPath:(NSString *)fileName;

+(void)shareDataWithPath:(NSString *)path;

@end

AudioComponentDescription mh_audioComponentDescription_AppleManufacturer(OSType type, OSType subType);
AudioComponentDescription mh_audioComponentDescription(OSType type, OSType subType, OSType manufacturer);

void CheckStatus(OSStatus status, NSString *message);



NS_ASSUME_NONNULL_END
