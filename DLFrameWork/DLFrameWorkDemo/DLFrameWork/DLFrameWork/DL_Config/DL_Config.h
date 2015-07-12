//
//  DL_Config.h
//  DLFrameWork
//
//  Created by XueYulun on 15/6/25.
//  Copyright (c) 2015年 __Dylan. All rights reserved.
//

#import "_pragma_push.h"

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
#ifndef __IPHONE_6_0
#error "DL_Framework only available in iOS SDK 6.0 and later."
#endif
#endif

///----------------------------------
///  @name  全局配置
///----------------------------------

#define	__DLFRAME_VERSION__	"0.1.0"	 /// 框架主版本号

#define __DLFRAME_DOMAIN__ "DLFramework.com"

#if TARGET_IPHONE_SIMULATOR
    #define __DLFRAME_APP "SIMULATOR"
#else
    #define __DLFRAME_APP "IPHONE"
#endif

#import "DL_Predefine.h"

#import "_pragma_pop.h"