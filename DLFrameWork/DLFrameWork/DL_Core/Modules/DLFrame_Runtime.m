//
//  DLFrame_Runtime.m
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name code
///----------------------------------

@implementation NSObject(Runtime)

+ (NSArray *)loadedClassNames {
    
    static dispatch_once_t		once;
    static NSMutableArray *		classNames;
    
    dispatch_once( &once, ^
                  {
                      classNames = [[NSMutableArray alloc] init];
                      
                      unsigned int 	classesCount = 0;
                      Class *		classes = objc_copyClassList( &classesCount );
                      
                      for ( unsigned int i = 0; i < classesCount; ++i )
                      {
                          Class classType = classes[i];
                          
                          if ( class_isMetaClass( classType ) )
                              continue;
                          
                          Class superClass = class_getSuperclass( classType );
                          
                          if ( nil == superClass )
                              continue;
                          
                          [classNames addObject:[NSString stringWithUTF8String:class_getName(classType)]];
                      }
                      
                      [classNames sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                          return [obj1 compare:obj2];
                      }];
                      
                      free( classes );
                  });
    
    return classNames;
}

+ (NSArray *)subClasses
{
    NSMutableArray * results = [[NSMutableArray alloc] init];
    
    for ( NSString * className in [self loadedClassNames] ) {
        
        Class classType = NSClassFromString( className );
        if ( classType == self )
            continue;
        
        if ( NO == [classType isSubclassOfClass:self] )
            continue;
        
        [results addObject:[classType description]];
    }
    
    return results;
}


+ (NSArray *)methods {
    
    NSMutableArray * methodNames = [[NSMutableArray alloc] init];
    
    Class thisClass = self;
    
    while ( NULL != thisClass ) {
        
        unsigned int	methodCount = 0;
        Method *		methodList = class_copyMethodList( thisClass, &methodCount );
        
        for ( unsigned int i = 0; i < methodCount; ++i ) {
            
            SEL selector = method_getName( methodList[i] );
            if ( selector ) {
                
                const char * cstrName = sel_getName(selector);
                if ( NULL == cstrName )
                    continue;
                
                NSString * selectorName = [NSString stringWithUTF8String:cstrName];
                if ( NULL == selectorName )
                    continue;
                
                [methodNames addObject:selectorName];
            }
        }
        
        free( methodList );
        
        thisClass = class_getSuperclass( thisClass );
        if ( thisClass == [NSObject class] ) {
            
            break;
        }
    }
    
    return methodNames;
}

+ (NSArray *)methodsWithPrefix:(NSString *)prefix {
    
    NSArray * methods = [self methods];
    
    if ( nil == methods || 0 == methods.count ) {
        
        return nil;
    }
    
    if ( nil == prefix ) {
        
        return methods;
    }
    
    NSMutableArray * result = [[NSMutableArray alloc] init];
    
    for ( NSString * selectorName in methods ) {
        
        if ( NO == [selectorName hasPrefix:prefix] )
        {
            continue;
        }
        
        [result addObject:selectorName];
    }
    
    [result sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    return result;
}

+ (void *)replaceSelector:(SEL)sel1 withSelector:(SEL)sel2 {
    
    Method method = class_getInstanceMethod( self, sel1 );
    
    IMP implement = (IMP)method_getImplementation( method );
    IMP implement2 = class_getMethodImplementation( self, sel2 );
    
    method_setImplementation( method, implement2 );
    
    return (void *)implement;
}

- (NSMutableDictionary *)classAttributes {
    
    NSMutableDictionary * attributeDict = [NSMutableDictionary dictionary];
    
    NSString *className = NSStringFromClass([self class]);
    const char * cClassName = [className UTF8String];
    id classM = objc_getClass(cClassName);
    unsigned int outCount, i;
    
    objc_property_t * properties = class_copyPropertyList(classM, &outCount);
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString * attributeName = [NSString stringWithUTF8String:property_getName(property)];
        [attributeDict setValue:[self valueForKey:attributeName] forKey:attributeName];
    }
    
    return attributeDict;
}

@end