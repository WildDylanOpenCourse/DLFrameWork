
///----------------------------------
///  @name Navigation扩展设置
///----------------------------------

#import <UIKit/UIKit.h>

@interface UINavigationBar (DLExtension)
- (void)DLUI_setBackgroundColor:(UIColor *)backgroundColor;
- (void)DLUI_setContentAlpha:(CGFloat)alpha;
- (void)DLUI_setTranslationY:(CGFloat)translationY;
- (void)DLUI_reset;
@end
