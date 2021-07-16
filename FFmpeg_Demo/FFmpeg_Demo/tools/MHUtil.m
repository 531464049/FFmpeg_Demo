//
//  MHUtil.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/6/29.
//

#import "MHUtil.h"

@implementation MHUtil

+(NSString *)bundlePath:(NSString *)fileName {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

+(NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}
+(void)shareDataWithPath:(NSString *)path
{
    NSURL * fileUrl = [NSURL fileURLWithPath:path];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityViewController * actVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileUrl] applicationActivities:nil];
        actVC.completionWithItemsHandler = ^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            
        };
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:actVC animated:YES completion:nil];
    });
}
@end

AudioComponentDescription mh_audioComponentDescription_AppleManufacturer(OSType type, OSType subType)
{
    return mh_audioComponentDescription(type, subType, kAudioUnitManufacturer_Apple);
}
AudioComponentDescription mh_audioComponentDescription(OSType type, OSType subType, OSType manufacturer)
{
    AudioComponentDescription description;
    bzero(&description, sizeof(description));
    description.componentType = type;
    description.componentSubType = subType;
    description.componentManufacturer = manufacturer;
    return description;
}

void CheckStatus(OSStatus status, NSString *message)
{
    if(status != noErr)
    {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            NSLog(@"%@: fail %s", message, fourCC);
        else
            NSLog(@"%@: fail %d", message, (int)status);
    }
}


