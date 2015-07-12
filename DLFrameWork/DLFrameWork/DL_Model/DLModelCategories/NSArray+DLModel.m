#import "NSArray+DLModel.h"

@implementation NSArray(DLModel)

- (id)modelWithIndexValue:(id)indexValue
{
    NSAssert(NO, @"call modelWithIndexValue: on a ConvertOnDemand property, which is defined like that: @property (strong, nonatomic) NSArray<MyModel, ConvertOnDemand>* list;");
    return nil;
}

@end
