//
//  UIImage+DLExtension.m
//  DLKit
//
//  Created by XueYulun on 15/3/25.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import "UIImage+DLExtension.h"

@implementation UIImage (DLExtension)

-(UIImage*)safeResizableImageWithCapInsets:(UIEdgeInsets)capInsets {
    float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (osVersion < 6.0) {
        // for iOS < 6.0 fix crash
        return [self stretchableImageWithLeftCapWidth:capInsets.left topCapHeight:capInsets.top];
    }
    else {
        return  [self resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
    }
}

@end
