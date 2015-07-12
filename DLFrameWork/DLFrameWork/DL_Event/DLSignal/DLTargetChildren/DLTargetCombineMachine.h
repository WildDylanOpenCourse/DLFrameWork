//
//  DLTargetCombineMachine.h
//  
//
//  Created by XueYulun on 15/7/7.
//
//

#import <Foundation/Foundation.h>

@class DLSignal, DLNotificationGun, DLTargetCombineMachine;

#define DLBind(TARGET, KEYPATH) \
[[DLTargetCombineMachine alloc] initWithTarget:(TARGET) keyPath:(@keypath(TARGET, KEYPATH))].gun // @ 宏定义, 快速生成中继对象, 完成Signal与Gun的绑定接口的开放

@interface DLTargetCombineMachine : NSObject

@prop_strong(DLSignal *, signal);       // @ 目标
@prop_strong(DLNotificationGun *, gun); // @ 枪

- (instancetype)initWithTarget: (id)Target keyPath: (NSString *)keypath;

@end
