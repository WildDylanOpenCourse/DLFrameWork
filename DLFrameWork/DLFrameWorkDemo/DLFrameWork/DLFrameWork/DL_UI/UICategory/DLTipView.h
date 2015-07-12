
///----------------------------------
///  @name 提示
///----------------------------------

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DLTipArrowOrientation){
    DL_ARROW_ORI_UP = 0,
    DL_ARROW_ORI_DOWN,
    DL_ARROW_ORI_LEFT,
    DL_ARROW_ORI_RIGHT
};

@interface DLTipView : UIView


/**
 * @param rect frame
 * @param text text
 * @param textFont text font
 * @param arrowMargin boult position
 * @param orientation boult direction
 */
- (id)initWithRect:(CGRect)rect
              text:(NSString *)text
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation;

/**
 * @param rightIcon right image icon
 */
- (id)initWithRect:(CGRect)rect
         textArray:(NSArray *)textArray
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation
         rightIcon:(NSString*)rightIcon;

/**
 * @param textLabelOrigin label position
 */
- (id)initWithRect:(CGRect)rect
         textArray:(NSArray *)textArray
          textFont:(UIFont *)textFont
       arrowMargin:(CGFloat)margin
  arrowOrientation:(DLTipArrowOrientation)orientation
         rightIcon:(NSString *)rightIcon
   textLabelOrigin:(CGPoint)textOrigin;

/**
 *  Dismiss
 */
- (void)dismissTip;


@end
