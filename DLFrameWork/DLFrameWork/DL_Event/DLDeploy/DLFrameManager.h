//
//  DLFrameManager.h
//  
//
//  Created by XueYulun on 15/7/7.
//
//

///----------------------------------
///  @name 管理中心
///----------------------------------

#import "_pragma_push.h"

#import <Foundation/Foundation.h>

@interface DLFrameManager : NSObject

@singleton(DLFrameManager);

// @ 系统版本, 硬件版本

- (NSString *)systemVersion;
- (NSString *)hardwareString;

// @ 打开Log

- (void)SetLogEnabled: (BOOL)enabled;

// @ 当前SDK版本

- (NSString *)SDKVersion;

// @ ping目标域, 设置代理

- (void)PingWith: (NSString *)host;
- (void)SetPingWithDelegate: (id<DLFramePingerDelegate>)delegate;

// @ 推送Token相关

- (void)RegisterRemoteNotification;
- (NSString *)DeviceToken: (NSData *)data;

// @ 获取当前推送TokenStr

@prop_readonly(NSString *, DeviceToken);

// @ 首次启动应用程序

- (BOOL)NowFirstLaunch;
- (void)SetLaunchStatu: (BOOL)isLaunch;

// @ 开始截获Touch时间喽

- (void)HandleWindowTouch;

@end

#import "_pragma_pop.h"