#import <Foundation/Foundation.h>

@interface DLModelArray : NSObject <NSFastEnumeration>

- (id)initWithArray:(NSArray *)array modelClass:(Class)cls;

- (id)objectAtIndex:(NSUInteger)index;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (NSUInteger)count;

- (id)firstObject;
- (id)lastObject;

- (id)modelWithIndexValue:(id)indexValue;

@end
