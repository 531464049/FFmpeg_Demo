//
//  MHVideoGLView.h
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/12.
//

#import <UIKit/UIKit.h>
#import "MHDecoderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHVideoGLView : UIView

-(void)render:(MHVideoFrame *)frame;

-(void)destoryPlayer;

@end

NS_ASSUME_NONNULL_END
