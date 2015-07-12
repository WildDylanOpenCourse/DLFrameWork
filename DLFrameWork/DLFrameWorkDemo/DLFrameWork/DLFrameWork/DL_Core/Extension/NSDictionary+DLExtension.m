#import "NSDictionary+DLExtension.h"

@implementation NSDictionary (DLExtension)

-(NSData*)data {
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return data;
}

- (NSString *)dictionaryToJson {
    return [NSDictionary dictionaryToJson:self];
}

+ (NSString *)dictionaryToJson:(NSDictionary *)dictionary {
    NSString *json     = nil;
    NSError  *error    = nil;
    NSData   *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        return @"{}";
    } else if (!error) {
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    } else {
        return error.localizedDescription;
    }
}


@end

@implementation NSMutableDictionary (DLExtension)

- (void)safeSetObject:(id)anObject forKey:(id < NSCopying >)aKey {
    if (!anObject || !aKey) {
        return ;
    }
    
    [self setObject:anObject forKey:aKey];
}

- (void)safeRemoveObjectForKey:(id)aKey {
    if(!aKey)
        return;
    
    [self removeObjectForKey:aKey];
}


@end