//
//  UIButton+MH.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/6.
//

#import "UIButton+MH.h"
#import <objc/runtime.h>

@implementation UIButton (MH)

static const char *UIButton_acceptEventTime = "UIButton_acceptEventTime";

- (NSTimeInterval)mm_acceptEventTime {
    return [objc_getAssociatedObject(self, UIButton_acceptEventTime) doubleValue];
}

- (void)setMm_acceptEventTime:(NSTimeInterval)mm_acceptEventTime {
    objc_setAssociatedObject(self, UIButton_acceptEventTime, @(mm_acceptEventTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+ (void)load {
    //获取这两个方法
    Method systemMethod = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
    SEL sysSEL = @selector(sendAction:to:forEvent:);

    Method myMethod = class_getInstanceMethod(self, @selector(mm_sendAction:to:forEvent:));
    SEL mySEL = @selector(mm_sendAction:to:forEvent:);

    //添加方法进去
    BOOL didAddMethod = class_addMethod(self, sysSEL, method_getImplementation(myMethod), method_getTypeEncoding(myMethod));

    //如果方法已经存在
    if (didAddMethod) {
        class_replaceMethod(self, mySEL, method_getImplementation(systemMethod), method_getTypeEncoding(systemMethod));
    } else {
        method_exchangeImplementations(systemMethod, myMethod);
    }
}

- (void)mm_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    if (NSDate.date.timeIntervalSince1970 - self.mm_acceptEventTime < 0.3) {
        return;
    }
    self.mm_acceptEventTime = NSDate.date.timeIntervalSince1970;
    //震动反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator*impactLight = [[UIImpactFeedbackGenerator alloc]initWithStyle:UIImpactFeedbackStyleMedium];
        [impactLight impactOccurred];
    }
    [self mm_sendAction:action to:target forEvent:event];
}

@end
