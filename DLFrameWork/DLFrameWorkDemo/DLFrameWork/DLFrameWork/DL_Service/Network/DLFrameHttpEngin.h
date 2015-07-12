//
//  DLFrameHttpEngin.h
//  
//
//  Created by XueYulun on 15/6/30.
//
//

///----------------------------------
///  @name 网络请求 Engin/Client
///----------------------------------

typedef void (^DLHTTPRequestCompletionHandler)(id response, NSHTTPURLResponse * urlResponse, NSError * error);

#import <Foundation/Foundation.h>

@class DLFrameRequest;

@interface DLFrameHttpEngin : NSObject

@prop_strong(NSOperationQueue * , operationQueue);

+ (instancetype)sharedClient;
+ (instancetype)sharedClientWithIdentifier: (NSString *)identifier;

- (void)setBasicAuthWithUsername: (NSString *)username password: (NSString *)password;
- (void)setValue: (NSString *)value forHTTPHeaderField: (NSString *)field;

- (DLFrameRequest *)GET: (NSString *)path parameters: (NSDictionary*)parameters completion: (DLHTTPRequestCompletionHandler)completionBlock;
- (DLFrameRequest *)GET: (NSString *)path parameters: (NSDictionary*)parameters saveToPath: (NSString *)savePath progress: (void (^)(float progress))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock;

- (DLFrameRequest *)POST: (NSString *)path parameters: (NSObject *)parameters completion: (DLHTTPRequestCompletionHandler)completionBlock;
- (DLFrameRequest *)POST: (NSString *)path parameters: (NSObject *)parameters progress: (void (^)(float progress))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock;

- (void)cancelRequestsWithPath: (NSString*)path;
- (void)cancelAllRequests;
- (DLFrameRequest *)queueRequest: (DLFrameRequest *)requestOperation;

@prop_assign(BOOL, sendParametersAsJSON);
@prop_assign(NSURLRequestCachePolicy, cachePolicy);
@prop_assign(NSUInteger, timeoutInterval);

@prop_strong(NSDictionary *, baseParameters);
@prop_strong(NSString *, username);
@prop_strong(NSString *, password);
@prop_strong(NSString *, basePath);
@prop_strong(NSString *, userAgent);

@prop_strong(NSMutableDictionary *, HTTPHeaderFields);

@end
