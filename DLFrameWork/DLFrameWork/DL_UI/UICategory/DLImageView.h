
///----------------------------------
///  @name 扩展图片, 含有进度
///----------------------------------

#import <UIKit/UIKit.h>

typedef enum {
    DLColorizedProgressViewDirectionBottomToTop,
    DLColorizedProgressViewDirectionTopToBottom,
    DLColorizedProgressViewDirectionLeftToRight,
    DLColorizedProgressViewDirectionRightToLeft,
    DLColorizedProgressViewDirectionNone
} DLColorizedProgressViewDirection;

typedef void (^DLColorizedCompletionBlock)(CGFloat);

@interface DLImageView : UIView


// The full-color image
@property (nonatomic, retain) UIImage *image;

// From 0.0 to 1.0
@property (nonatomic, assign) CGFloat progress;

// Default is bottom to top
@property (nonatomic, assign) DLColorizedProgressViewDirection direction;

// The duration of the progress bar animation, in seconds, to go from 0% to 100% uninterrupted.
// The update animation speed is based on this value. Default is 1 second.
@property (nonatomic, assign) CGFloat totalAnimationDuration;

// When animating, there is a delay between when the target progress is set and
// when the actual progress catches up. This block will be invoked when the progress bar
// has completed animating. It returns the current progress.
@property (nonatomic, copy) DLColorizedCompletionBlock completionBlock;

// Initialize with an image and set the bounds to the image's size
- (id)initWithImage:(UIImage *)image;

// Set the progress with an animation
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

// Cancels a running animation
- (void)stopAnimation;

// Adjusts the frame to fit the image
- (void)sizeToFit;

@end
