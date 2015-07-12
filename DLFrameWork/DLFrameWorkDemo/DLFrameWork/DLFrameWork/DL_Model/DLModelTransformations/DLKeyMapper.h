#import <Foundation/Foundation.h>

typedef NSString* (^DLModelKeyMapBlock)(NSString* keyName);

@interface DLKeyMapper : NSObject

@property (readonly, nonatomic) DLModelKeyMapBlock JSONToModelKeyBlock;
@property (readonly, nonatomic) DLModelKeyMapBlock modelToJSONKeyBlock;

-(NSString*)convertValue:(NSString*)value isImportingToModel:(BOOL)importing;

-(instancetype)initWithJSONToModelBlock:(DLModelKeyMapBlock)toModel
                       modelToJSONBlock:(DLModelKeyMapBlock)toJSON;
-(instancetype)initWithDictionary:(NSDictionary*)map;

+(instancetype)mapperFromUnderscoreCaseToCamelCase;
+(instancetype)mapperFromUpperCaseToLowerCase;

@end
