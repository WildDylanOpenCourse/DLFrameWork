//
//  DLNotificationGun.h
//  
//
//  Created by XueYulun on 15/7/7.
//
//

///----------------------------------
///  @name 被监听
///----------------------------------

#import <Foundation/Foundation.h>

@class DLNotificationGun;

#define DLGun(TARGET, KEYPATH) \
[[DLNotificationGun alloc] initWithTarget:(TARGET) keypath:(@keypath(TARGET, KEYPATH))] // @ 宏定义: 生成Gun对象完成绑定

@class DLSignal;

@interface DLNotificationGun : NSObject

@prop_strong(DLSignal *, signal); // @ 被操作信号
@prop_strong(id, value);          // @ 改变后的值

@prop_strong(NSString *, keyPath);  // @ 被监听的路径
@prop_strong(id, target);           // @ 被监听的对象
@prop_unsafe(void *, context);      // @ 用来做标识, 通常是 `(__bridge void *)signal`

- (instancetype)initWithTarget:(id)target keypath:(NSString *)keyPath;

@end
