//
//  DLGunProxy.m
//  
//
//  Created by XueYulun on 15/7/7.
//
//

#import "DLGunProxy.h"

@interface DLGunProxy ()

@prop_strong(NSMutableArray *, gunArray);

@end

@implementation DLGunProxy

@def_singleton(DLGunProxy);

- (void)AddNewGun: (DLNotificationGun *)gun {
    
    // @ 添加Gun到数组。
    
    DLNotificationGun * newGun = gun;
    [self.gunArray addObject:newGun];
    
    // @ 监听。
    
    [newGun.target addObserver:self forKeyPath:newGun.keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:newGun.context];
    
    // @ 当目标为UIControl的时候, 很有可能通过监听不能拿到操作后的值, 只能拿到赋值的操作, 所以要加这个。
    
    if ([newGun.target isKindOfClass:[UIControl class]]) {
        
        [newGun.target addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventAllEvents];
    }
}

- (void)RemoveGun: (DLNotificationGun *)gun {
    
    // @ 移除Gun。
    
    DLNotificationGun * newGun = gun;
    [self.gunArray addObject:newGun];
}

- (void)valueChanged: (id)sender {
    
    // 枚举, 操作一下目标的值, 简单的操作。
    
    [self.gunArray enumerateObjectsUsingBlock:^(DLNotificationGun * obj, NSUInteger idx, BOOL *stop) {
        
        if (obj.target == sender) {
            
            obj.value = [obj.target valueForKeyPath:obj.keyPath];
            [obj.signal.target setValue:obj.value forKeyPath:obj.signal.keyPath];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    // @ 收到动作, 进行简单的赋值操作, （需要独立工具对监听结果做处理Fire）。
    
    __block DLNotificationGun * operateGun = nil;
    [self.gunArray enumerateObjectsUsingBlock:^(DLNotificationGun * enumGun, NSUInteger idx, BOOL *stop) {
        
        if (context == enumGun.context) {
            
            operateGun = enumGun;
        }
    }];
    
    // @ 如果存在的话, 就去操作
    
    if (operateGun) {
        
        operateGun.value = [operateGun.target valueForKeyPath:operateGun.keyPath];
        [operateGun.signal.target setValue:operateGun.value forKeyPath:operateGun.signal.keyPath];
    }
}

- (NSArray *)AllGuns {
    
    return self.gunArray;
}

- (NSMutableArray *)gunArray {
    
    if (!_gunArray) {
        
        _gunArray = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _gunArray;
}

@end
