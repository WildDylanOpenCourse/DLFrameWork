#import "DLModelArray.h"
#import "DLModel.h"

@implementation DLModelArray
{
    NSMutableArray* _storage;
    Class _targetClass;
}

-(id)initWithArray:(NSArray *)array modelClass:(Class)cls
{
    self = [super init];
    
    if (self) {
        _storage = [NSMutableArray arrayWithArray:array];
        _targetClass = cls;
    }
    return self;
}

-(id)firstObject
{
    return [self objectAtIndex:0];
}

-(id)lastObject
{
    return [self objectAtIndex:_storage.count - 1];
}

-(id)objectAtIndex:(NSUInteger)index
{
	return [self objectAtIndexedSubscript:index];
}

-(id)objectAtIndexedSubscript:(NSUInteger)index
{
    id object = _storage[index];
    if (![object isMemberOfClass:_targetClass]) {
        NSError* err = nil;
        object = [[_targetClass alloc] initWithDictionary:object error:&err];
        if (object) {
            _storage[index] = object;
        }
    }
    return object;
}

-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation invokeWithTarget:_storage];
}

-(id)forwardingTargetForSelector:(SEL)selector
{
    static NSArray* overridenMethods = nil;
    if (!overridenMethods) overridenMethods = @[@"initWithArray:modelClass:",@"objectAtIndex:",@"objectAtIndexedSubscript:", @"count",@"modelWithIndexValue:",@"description",@"mutableCopy",@"firstObject",@"lastObject",@"countByEnumeratingWithState:objects:count:"];
    if ([overridenMethods containsObject:NSStringFromSelector(selector)]) {
        return self;
    }
    return _storage;
}

-(NSUInteger)count
{
    return _storage.count;
}

-(id)modelWithIndexValue:(id)indexValue
{
    if (self.count==0) return nil;
    if (![_storage[0] indexPropertyName]) return nil;
    
    for (DLModel* model in _storage) {
        if ([[model valueForKey:model.indexPropertyName] isEqual:indexValue]) {
            return model;
        }
    }
    
    return nil;
}

-(id)mutableCopy
{
    //it's already mutable
    return self;
}

#pragma mark - description
-(NSString*)description
{
    NSMutableString* res = [NSMutableString stringWithFormat:@"<DLModelArray[%@]>\n", [_targetClass description]];
    for (id m in _storage) {
        [res appendString: [m description]];
        [res appendString: @",\n"];
    }
    [res appendFormat:@"\n</DLModelArray>"];
    return res;
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								 objects:(id __unsafe_unretained [])stackbuf
								   count:(NSUInteger)stackbufLength
{
    NSUInteger count = 0;
    
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    
    if (countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[0];
    }
	
    if (countOfItemsAlreadyEnumerated < [self count]) {
        state->itemsPtr = stackbuf;
        while ((countOfItemsAlreadyEnumerated < [self count]) && (count < stackbufLength)) {
            stackbuf[count] = [self objectAtIndex:countOfItemsAlreadyEnumerated];
            countOfItemsAlreadyEnumerated++;
            count++;
        }
    } else {
        count = 0;
    }
	
    state->state = countOfItemsAlreadyEnumerated;
    
    return count;
}

@end
