#import "DLModel.h"

#pragma mark - definitions

extern NSString* const kHTTPMethodGET;
extern NSString* const kHTTPMethodPOST;

extern NSString* const kContentTypeAutomatic;
extern NSString* const kContentTypeJSON;
extern NSString* const kContentTypeWWWEncoded;

typedef void (^JSONObjectBlock)(id json, DLModelError* err);

@interface DLHTTPClient : NSObject

+(NSMutableDictionary*)requestHeaders;

+(void)setDefaultTextEncoding:(NSStringEncoding)encoding;
+(void)setCachingPolicy:(NSURLRequestCachePolicy)policy;
+(void)setTimeoutInSeconds:(int)seconds;
+(void)setRequestContentType:(NSString*)contentTypeString;

+(void)getJSONFromURLWithString:(NSString*)urlString completion:(JSONObjectBlock)completeBlock;
+(void)getJSONFromURLWithString:(NSString*)urlString params:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock;

+(void)JSONFromURLWithString:(NSString*)urlString method:(NSString*)method params:(NSDictionary*)params orBodyString:(NSString*)bodyString completion:(JSONObjectBlock)completeBlock;
+(void)JSONFromURLWithString:(NSString*)urlString method:(NSString*)method params:(NSDictionary*)params orBodyString:(NSString*)bodyString headers:(NSDictionary*)headers completion:(JSONObjectBlock)completeBlock;
+(void)JSONFromURLWithString:(NSString*)urlString method:(NSString*)method params:(NSDictionary *)params orBodyData:(NSData*)bodyData headers:(NSDictionary*)headers completion:(JSONObjectBlock)completeBlock;

+(void)postJSONFromURLWithString:(NSString*)urlString params:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock;
+(void)postJSONFromURLWithString:(NSString*)urlString bodyString:(NSString*)bodyString completion:(JSONObjectBlock)completeBlock;
+(void)postJSONFromURLWithString:(NSString*)urlString bodyData:(NSData*)bodyData completion:(JSONObjectBlock)completeBlock;


@end
