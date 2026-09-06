#import "SabellaKSPlayerWorkaround.h"

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import <objc/runtime.h>

#if TARGET_OS_TV

static void SabellaKSPlayerSetContext(id self, SEL _cmd, void *context) {
    (void)self;
    (void)_cmd;
    (void)context;
}

void SabellaInstallKSPlayerWorkaround(void) {
    Class cls = objc_getClass("OS_dispatch_mach_msg");
    if (!cls) {
        return;
    }

    SEL selector = sel_registerName("_setContext:");
    if (!class_respondsToSelector(cls, selector)) {
        class_addMethod(cls, selector, (IMP)SabellaKSPlayerSetContext, "v@:^v");
    }
}

@interface SabellaKSPlayerWorkaroundLoader : NSObject
@end

@implementation SabellaKSPlayerWorkaroundLoader

+ (void)load {
    SabellaInstallKSPlayerWorkaround();
}

@end

#else

void SabellaInstallKSPlayerWorkaround(void) {}

#endif
