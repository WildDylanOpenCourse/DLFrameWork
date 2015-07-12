//
//  DLFrame_Marco.h
//  DLFrameWork
//
//  Created by XueYulun on 15/7/3.
//  Copyright (c) 2015年 __Dylan. All rights reserved.
//

#import "metamacros.h"

///------------------------------------------------------------------------
// NSString *UTF8StringPath = @keypath(str.lowercaseString.UTF8String);
// => @"lowercaseString.UTF8String"
// NSString *versionPath = @keypath(NSObject, version);
// => @"version"
// NSString *lowercaseStringPath = @keypath(NSString.new, lowercaseString);
// => @"lowercaseString"
///------------------------------------------------------------------------

#define keypath(...) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-repeated-use-of-weak\"") \
metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__))\
                        (keypath1(__VA_ARGS__))\
                        (keypath2(__VA_ARGS__))
_Pragma("clang diagnostic pop") \

#define keypath1(PATH) \
(((void)(NO && ((void)PATH, NO)), strchr(# PATH, '.') + 1))

#define keypath2(OBJ, PATH) \
(((void)(NO && ((void)OBJ.PATH, NO)), # PATH))

