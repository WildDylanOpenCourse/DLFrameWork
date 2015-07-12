#import <Foundation/Foundation.h>
#import "DLModelArray.h"

extern BOOL isNull(id value);

@interface JSONValueTransformer : NSObject

@property (strong, nonatomic, readonly) NSDictionary* primitivesNames;

+(Class)classByResolvingClusterClasses:(Class)sourceClass;

-(NSMutableString*)NSMutableStringFromNSString:(NSString*)string;
-(NSMutableArray*)NSMutableArrayFromNSArray:(NSArray*)array;

-(NSArray*)NSArrayFromDLModelArray:(DLModelArray*)array;
-(NSMutableArray*)NSMutableArrayFromDLModelArray:(DLModelArray*)array;

-(NSMutableDictionary*)NSMutableDictionaryFromNSDictionary:(NSDictionary*)dict;

-(NSSet*)NSSetFromNSArray:(NSArray*)array;
-(NSMutableSet*)NSMutableSetFromNSArray:(NSArray*)array;

-(NSArray*)JSONObjectFromNSSet:(NSSet*)set;

-(NSArray*)JSONObjectFromNSMutableSet:(NSMutableSet*)set;

-(NSNumber*)BOOLFromNSNumber:(NSNumber*)number;
-(NSNumber*)BOOLFromNSString:(NSString*)string;
-(NSNumber*)JSONObjectFromBOOL:(NSNumber*)number;
-(NSNumber*)NSNumberFromNSString:(NSString*)string;

-(NSString*)NSStringFromNSNumber:(NSNumber*)number;
-(NSString*)NSStringFromNSDecimalNumber:(NSDecimalNumber*)number;
-(NSString*)JSONObjectFromNSURL:(NSURL*)url;
-(NSString *)JSONObjectFromNSTimeZone:(NSTimeZone *)timeZone;

-(NSDecimalNumber*)NSDecimalNumberFromNSString:(NSString*)string;

-(NSURL*)NSURLFromNSString:(NSString*)string;

-(NSTimeZone *)NSTimeZoneFromNSString:(NSString*)string;
-(NSDate*)NSDateFromNSNumber:(NSNumber*)number;

@end
