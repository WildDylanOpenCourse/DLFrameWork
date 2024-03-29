//
//  UIView+DLExtension.m
//  DLKit
//
//  Created by XueYulun on 15/3/25.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import "UIView+DLExtension.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define kAnimationDidStopNotification              @"kAnimationDidStopNotification"

#define kAnimationDidStartNotification              @"kAnimationDidStartNotification"

NSString *const kDLAnimationFlyOut = @"kDLAnimationFlyOut";
NSString *const kDLAnimationTypeOut = @"kDLAnimationTypeOut";
NSString *const kDLAnimationTargetViewKey = @"kDLAnimationTargetViewKey";
NSString *const kDLAnimationCallerDelegateKey = @"kDLAnimationCallerDelegateKey";
NSString *const kDLAnimationCallerStartSelectorKey = @"kDLAnimationCallerStartSelectorKey";
NSString *const kDLAnimationCallerStopSelectorKey = @"kDLAnimationCallerStopSelectorKey";
NSString *const kDLAnimationName = @"kDLAnimationName";
NSString *const kDLAnimationType = @"kDLAnimationType";

@implementation UIView (DLExtension)

- (CGPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)top {
    return self.origin.y;
}

- (void)setTop:(CGFloat)top {
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)left {
    return self.origin.x;
}

- (void)setLeft:(CGFloat)left {
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)right {
    return self.left + self.width;
}

- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom {
    return self.top + self.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)width {
    return self.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return self.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)x {
    return self.center.x;
}

- (void)setX:(CGFloat)x {
    self.center = CGPointMake(x, self.center.y);
}

- (CGFloat)y {
    return self.center.y;
}

- (void)setY:(CGFloat)y {
    self.center = CGPointMake(self.center.x, y);
}

- (CGSize)boundsSize {
    return self.bounds.size;
}

- (void)setBoundsSize:(CGSize)size {
    CGRect bounds = self.bounds;
    bounds.size = size;
    self.bounds = bounds;
}

- (CGFloat)boundsWidth {
    return self.boundsSize.width;
}

- (void)setBoundsWidth:(CGFloat)width {
    CGRect bounds = self.bounds;
    bounds.size.width = width;
    self.bounds = bounds;
}

- (CGFloat)boundsHeight {
    return self.boundsSize.height;
}

- (void)setBoundsHeight:(CGFloat)height {
    CGRect bounds = self.bounds;
    bounds.size.height = height;
    self.bounds = bounds;
}

- (CGRect)contentBounds {
    return CGRectMake(0.0f, 0.0f, self.boundsWidth, self.boundsHeight);
}

- (CGPoint)contentCenter {
    return CGPointMake(self.boundsWidth/2.0f, self.boundsHeight/2.0f);
}

// Animations
- (void)shakeView {
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    shake.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f)], [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f)]];
    shake.autoreverses = YES;
    shake.repeatCount = 2.0f;
    shake.duration = 0.07f;
    
    [self.layer addAnimation:shake forKey:nil];
}

@end

#pragma clang diagnostic pop