//
//  DLGunProxy.h
//  
//
//  Created by XueYulun on 15/7/7.
//
//

///----------------------------------
///  @name 核心的处理类, 可以理解为中间站
///----------------------------------

#import <Foundation/Foundation.h>

@interface DLGunProxy : NSObject

@singleton(DLGunProxy);

- (void)AddNewGun: (DLNotificationGun *)gun; // @ 增加Gun
- (void)RemoveGun: (DLNotificationGun *)gun; // @ 删除Gun

- (NSArray *)AllGuns;

@end
