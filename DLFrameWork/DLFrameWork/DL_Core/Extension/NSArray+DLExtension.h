
///----------------------------------
///  @name 数组扩展
///----------------------------------

#import <Foundation/Foundation.h>

@interface NSArray (DLExtension)

- (id)safeObjectAtIndex:(NSUInteger)index;

@end

@interface NSMutableArray (DLExtension)

///----------------------------------
///  @name 安全操作
///----------------------------------

-(void)safeAddObject:(id)anObject;
-(bool)safeInsertObject:(id)anObject atIndex:(NSUInteger)index;
-(bool)safeRemoveObjectAtIndex:(NSUInteger)index;
-(bool)safeReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

/*!
 *  排序
 */
+ (NSMutableArray *)sortArrayByKey:(NSString *)key
                             array:(NSMutableArray *)array
                         ascending:(BOOL)ascending;

@end