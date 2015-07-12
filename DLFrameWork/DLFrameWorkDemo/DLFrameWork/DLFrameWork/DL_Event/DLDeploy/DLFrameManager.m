//
//  DLFrameManager.m
//
//
//  Created by XueYulun on 15/7/7.
//
//

#import "DLFrameManager.h"

@interface DLFrameManager ()

@prop_strong(NSString *, DeviceToken);
@prop_strong(DLFramePinger *, pinger);

@end

@implementation DLFrameManager

@def_singleton(DLFrameManager);

- (NSString *)systemVersion {
    
    return [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
}

- (NSString *)hardwareString {
    
    return [UIDeviceUtil hardwareString];
}

- (void)SetLogEnabled: (BOOL)enabled {
 
    // @ 打印标志
    
    [DLFrameDebug sharedInstance].enabled = enabled;
    [self PrintDescript];
}

- (NSString *)SDKVersion {
    
    return @__DLFRAME_VERSION__;
}

- (DLFramePinger *)pinger {
    
    if (!_pinger) {
        
        _pinger = [[DLFramePinger alloc] initWithHost:@"www.baidu.com"];
        _pinger.averageNumberOfPings = 4;
    }
    
    return _pinger;
}

- (void)PingWith: (NSString *)host {
    
    [self.pinger stopPinging];
    self.pinger.domainOrIp = host;
    [self.pinger startPinging];
}


- (void)SetPingWithDelegate: (id<DLFramePingerDelegate>)delegate {
    
    [self.pinger setDelegate:delegate];
}

#pragma mark -
#pragma mark Remote Notifications

- (void)RegisterRemoteNotification {
    
#ifdef __IPHONE_8_0
    UIUserNotificationSettings *uns = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[UIApplication sharedApplication] registerUserNotificationSettings:uns];
#else
    UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge);
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
#endif
    
}

- (NSString *)DeviceToken:(NSData *)data {
    
    NSString *token = [[data description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString * _deviceToken = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.DeviceToken = _deviceToken;
    
    return _deviceToken;
}

static NSString * const LaunchIdentifier = @"LaunchYetIdentifier_LocalPlistFileKey";

- (BOOL)NowFirstLaunch {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:LaunchIdentifier];
}

- (void)SetLaunchStatu: (BOOL)isLaunch {
    
    [[NSUserDefaults standardUserDefaults] setBool:isLaunch forKey:LaunchIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)PrintDescript {
    
    DLogOut(@"\nDLFramework:\n     SDKVersion:     %@\n     DeviceVersion:  %@\n     Hardware:       %@\nMACAddress:%@\n", @__DLFRAME_VERSION__, [self systemVersion], [self hardwareString], [DLExtension macAddress]);
}

- (void)HandleWindowTouch {
    
    
}

@end
