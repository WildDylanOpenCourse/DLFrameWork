//
//  DLFrameRequest.h
//  
//
//  Created by XueYulun on 15/6/26.
//
//

///----------------------------------
///  @name 网络请求 Request
///----------------------------------

enum {
    DLHTTPRequestMethodGET = 0,
    DLHTTPRequestMethodPOST,
};
typedef NSUInteger DLHTTPRequestMethod;

#import <AvailabilityMacros.h>
#import "DLFrameHttpEngin.h"

@interface DLFrameRequest : NSOperation

+ (DLFrameRequest*)GET:(NSString*)address parameters:(NSDictionary*)parameters completion:(DLHTTPRequestCompletionHandler)block;
+ (DLFrameRequest*)GET:(NSString*)address parameters:(NSDictionary*)parameters saveToPath:(NSString*)savePath progress:(void (^)(float progress))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock;

+ (DLFrameRequest*)POST:(NSString*)address parameters:(NSObject*)parameters completion:(DLHTTPRequestCompletionHandler)block;
+ (DLFrameRequest*)POST:(NSString *)address parameters:(NSObject *)parameters progress:(void (^)(float))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock;

- (DLFrameRequest*)initWithAddress:(NSString*)urlString
                           method:(DLHTTPRequestMethod)method
                       parameters:(NSObject*)parameters
                       completion:(DLHTTPRequestCompletionHandler)completionBlock;

- (void)preprocessParameters;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

+ (void)setDefaultTimeoutInterval:(NSTimeInterval)interval;
+ (void)setDefaultUserAgent:(NSString*)userAgent;

@prop_strong(NSString *, userAgent);
@prop_assign(BOOL, sendParametersAsJSON);
@prop_assign(NSURLRequestCachePolicy, cachePolicy);
@prop_assign(NSUInteger, timeoutInterval);
@prop_strong(NSMutableURLRequest *, operationRequest);

@end

@protocol DLFrameRequestPrivateMethods <NSObject>

@prop_strong(NSString *, requestPath);
@prop_strong(DLFrameHttpEngin *, client);

- (DLFrameRequest*)initWithAddress:(NSString*)urlString
                           method:(DLHTTPRequestMethod)method
                       parameters:(NSObject*)parameters
                       saveToPath:(NSString*)savePath
                         progress:(void (^)(float))progressBlock
                       completion:(DLHTTPRequestCompletionHandler)completionBlock;

- (void)signRequestWithUsername:(NSString*)username password:(NSString*)password;

@end
