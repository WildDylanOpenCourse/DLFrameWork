
#import <Foundation/Foundation.h>

#import "DLModelError.h"
#import "DLValueTransformer.h"
#import "DLKeyMapper.h"

#pragma mark - Property Protocols

@protocol Ignore
@end

@protocol Optional
@end

@protocol Index
@end

@interface NSObject(DLModelPropertyCompatibility)<Optional, Index, Ignore>
@end

@protocol ConvertOnDemand
@end

@interface NSArray(DLModelPropertyCompatibility)<ConvertOnDemand>
@end

@protocol AbstractDLModelProtocol <NSCopying, NSCoding>

@required

-(instancetype)initWithDictionary:(NSDictionary*)dict error:(NSError**)err;
-(instancetype)initWithData:(NSData*)data error:(NSError**)error;

-(NSDictionary*)toDictionary;
-(NSDictionary*)toDictionaryWithKeys:(NSArray*)propertyNames;

@end

@interface DLModel : NSObject <AbstractDLModelProtocol, NSSecureCoding>

-(instancetype)initWithString:(NSString*)string
                        error:(DLModelError**)err;

-(instancetype)initWithString:(NSString *)string
                usingEncoding:(NSStringEncoding)encoding
                        error:(DLModelError**)err;

-(instancetype)initWithDictionary:(NSDictionary*)dict
                            error:(NSError **)err;

-(instancetype)initWithData:(NSData *)data
                      error:(NSError **)error;

-(NSDictionary*)toDictionary;
-(NSDictionary*)toDictionaryWithKeys:(NSArray*)propertyNames;

-(NSString*)toJSONString;
-(NSString*)toJSONStringWithKeys:(NSArray*)propertyNames;

-(NSData*)toJSONData;
-(NSData*)toJSONDataWithKeys:(NSArray*)propertyNames;

+(NSMutableArray*)arrayOfModelsFromDictionaries:(NSArray*)array;
+(NSMutableArray*)arrayOfModelsFromDictionaries:(NSArray*)array error:(NSError**)err;
+(NSMutableArray*)arrayOfModelsFromData:(NSData*)data error:(NSError**)err;
+(NSMutableArray*)arrayOfDictionariesFromModels:(NSArray*)array;

-(NSString*)indexPropertyName;

-(BOOL)isEqual:(id)object;
-(BOOL)validate:(NSError**)error;

-(NSComparisonResult)compare:(id)object;

+(DLKeyMapper*)keyMapper;

+(void)setGlobalKeyMapper:(DLKeyMapper*)globalKeyMapper;

+(BOOL)propertyIsOptional:(NSString*)propertyName;
+(BOOL)propertyIsIgnored:(NSString*)propertyName;

-(void)mergeFromDictionary:(NSDictionary*)dict useKeyMapping:(BOOL)useKeyMapping;

@end