#import "NSThread+DLExtension.h"

@implementation NSThread (DLExtension)

__unused NS_INLINE void runOnMainThread(void (^block)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

@end
