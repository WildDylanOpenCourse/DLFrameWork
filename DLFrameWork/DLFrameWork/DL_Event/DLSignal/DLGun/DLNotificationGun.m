//
//  DLNotificationGun.m
//  
//
//  Created by XueYulun on 15/7/7.
//
//

#import "DLNotificationGun.h"

@implementation DLNotificationGun

- (instancetype)initWithTarget:(id)target keypath:(NSString *)keyPath {
    
    self = [super init];
    if (self) {
        
        self.target = target;
        self.keyPath = keyPath;
    }
    
    return self;
}

@end
