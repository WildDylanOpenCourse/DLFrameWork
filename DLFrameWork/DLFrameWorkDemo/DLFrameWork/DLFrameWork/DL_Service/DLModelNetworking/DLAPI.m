#import "DLAPI.h"

#pragma mark - helper error model class
@interface DLAPIRPCErrorModel: DLModel
@property (assign, nonatomic) int code;
@property (strong, nonatomic) NSString* message;
@property (strong, nonatomic) id<Optional> data;
@end

#pragma mark - static variables

static DLAPI* sharedInstance = nil;
static long jsonRpcId = 0;

#pragma mark - DLAPI() private interface

@interface DLAPI ()
@property (strong, nonatomic) NSString* baseURLString;
@end

#pragma mark - DLAPI implementation

@implementation DLAPI

#pragma mark - initialize

+(void)initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[DLAPI alloc] init];
    });
}

#pragma mark - api config methods

+(void)setAPIBaseURLWithString:(NSString*)base
{
    sharedInstance.baseURLString = base;
}

+(void)setContentType:(NSString*)ctype
{
    [DLHTTPClient setRequestContentType: ctype];
}

#pragma mark - GET methods
+(void)getWithPath:(NSString*)path andParams:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock
{
    NSString* fullURL = [NSString stringWithFormat:@"%@%@", sharedInstance.baseURLString, path];
    
    [DLHTTPClient getJSONFromURLWithString: fullURL params:params completion:^(NSDictionary *json, DLModelError *e) {
        completeBlock(json, e);
    }];
}

#pragma mark - POST methods
+(void)postWithPath:(NSString*)path andParams:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock
{
    NSString* fullURL = [NSString stringWithFormat:@"%@%@", sharedInstance.baseURLString, path];
    
    [DLHTTPClient postJSONFromURLWithString: fullURL params:params completion:^(NSDictionary *json, DLModelError *e) {
        completeBlock(json, e);
    }];
}

#pragma mark - RPC methods
+(void)__rpcRequestWithObject:(id)jsonObject completion:(JSONObjectBlock)completeBlock
{
    
    NSData* jsonRequestData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                              options:kNilOptions
                                                                error:nil];
    NSString* jsonRequestString = [[NSString alloc] initWithData:jsonRequestData encoding: NSUTF8StringEncoding];

    NSAssert(sharedInstance.baseURLString, @"API base URL not set");
    [DLHTTPClient postJSONFromURLWithString: sharedInstance.baseURLString
                                   bodyString: jsonRequestString
                                   completion:^(NSDictionary *json, DLModelError* e) {

                                       if (completeBlock) {

                                           NSDictionary* result = json[@"result"];

                                           if (!result) {
                                               DLAPIRPCErrorModel* error = [[DLAPIRPCErrorModel alloc] initWithDictionary:json[@"error"] error:nil];
                                               if (error) {

                                                   if (!error.message) error.message = @"Generic json rpc error";
                                                   e = [DLModelError errorWithDomain:DLModelErrorDomain
                                                                                  code:error.code
                                                                              userInfo: @{ NSLocalizedDescriptionKey : error.message}];
                                               } else {

                                                   e = [DLModelError errorBadResponse];
                                               }
                                           }
                                           
                                           completeBlock(result, e);
                                       }
                                   }];
}

+(void)rpcWithMethodName:(NSString*)method andArguments:(NSArray*)args completion:(JSONObjectBlock)completeBlock
{
    NSAssert(method, @"No method specified");
    if (!args) args = @[];
    
    [self __rpcRequestWithObject:@{

                                  @"id": @(++jsonRpcId),
                                  @"params": args,
                                  @"method": method
     } completion:completeBlock];
}

+(void)rpc2WithMethodName:(NSString*)method andParams:(id)params completion:(JSONObjectBlock)completeBlock
{
    NSAssert(method, @"No method specified");
    if (!params) params = @[];
    
    [self __rpcRequestWithObject:@{

                                  @"jsonrpc": @"2.0",
                                  @"id": @(++jsonRpcId),
                                  @"params": params,
                                  @"method": method
     } completion:completeBlock];
}

@end

#pragma mark - helper rpc error model class implementation
@implementation DLAPIRPCErrorModel
@end
