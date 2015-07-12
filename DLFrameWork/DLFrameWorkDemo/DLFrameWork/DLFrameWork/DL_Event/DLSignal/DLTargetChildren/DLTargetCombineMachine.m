//
//  DLTargetCombineMachine.m
//  
//
//  Created by XueYulun on 15/7/7.
//
//

#import "DLTargetCombineMachine.h"

@implementation DLTargetCombineMachine

- (instancetype)initWithTarget: (id)Target keyPath: (NSString *)keypath {
    
    self = [super init];
    if (self) {
        
        self.signal = [[DLSignal alloc] init];
        self.signal.target = Target;
        self.signal.keyPath = keypath;
    }
    
    return self;
}

- (void)setGun:(DLNotificationGun *)gun {
    
    // 在Set方法完成绑定, 并添加到操作中间站中等待触发。
    
    _gun = gun;
    _gun.signal = self.signal;
    _gun.context = (__bridge void *)self.signal;
    
    // @ Add to Proxy Center
    
    [[DLGunProxy sharedInstance] AddNewGun:_gun];
}

@end
