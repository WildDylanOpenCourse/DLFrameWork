//
//  DLSignal.h
//  
//
//  Created by XueYulun on 15/6/30.
//
//

typedef void(^OperateBlock)(id value);

#import <Foundation/Foundation.h>

@interface DLSignal : NSObject

@prop_strong(id, target);          // @ 目标
@prop_strong(NSString *, keyPath); // @ 目标路径

@end