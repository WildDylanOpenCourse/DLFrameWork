//
//  DLFrameDebug.h
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name 调试输出
///----------------------------------

#import "_pragma_push.h"

#import <Foundation/Foundation.h>

#define	DLogOut(format,...);      if([DLFrameDebug sharedInstance].enabled)NSLog(format, ##__VA_ARGS__);
#define DLogOutMethodFun          if([DLFrameDebug sharedInstance].enabled)NSLog( @"[%@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
#define DLogError(format,...);    if([DLFrameDebug sharedInstance].enabled)NSLog(@"[error][%s][%d]" format,__func__,__LINE__,##__VA_ARGS__);
#define DLogWaring(format,...);   if([DLFrameDebug sharedInstance].enabled)NSLog(@"[waring][%s][%d]" format,__func__,__LINE__,##__VA_ARGS__);

@interface DLFrameDebug : NSObject

@singleton(DLFrameDebug)

/*!
 *  是否打开log
 */
@prop_assign(BOOL, enabled)

@end

#import "_pragma_pop.h"
