
///----------------------------------
///  @name 字典与JSON之间常用扩展
///----------------------------------

#import <Foundation/Foundation.h>

@interface NSDictionary (DLExtension)

-(NSData*)data;

- (NSString *)dictionaryToJson;

+ (NSString *)dictionaryToJson:(NSDictionary *)dictionary;

@end

///----------------------------------
///  @name 安全操作字典
///----------------------------------

@interface NSMutableDictionary (DLExtension)

- (void)safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)safeRemoveObjectForKey:(id)aKey;

@end