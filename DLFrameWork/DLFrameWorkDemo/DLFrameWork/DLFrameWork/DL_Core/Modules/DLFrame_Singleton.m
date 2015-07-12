//
//  DLFrame_Singleton.m
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name code
///----------------------------------

#pragma mark -

@implementation NSObject(Singleton)

+ (id)sharedInstance {
    
    return nil;
}

- (id)sharedInstance {
    
    return nil;
}

+ (id)sharedInstanceOrNew {
    
    id obj = [self sharedInstance];
    
    if ( nil == obj ) {
        
        obj = [[self alloc] init];
    }
    
    return obj;
}

- (id)sharedInstanceOrNew {
    
    return [[self class] sharedInstanceOrNew];
}

@end

