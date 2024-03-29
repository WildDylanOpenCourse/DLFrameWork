//
//  DLFrameHttpEngin.m
//  
//
//  Created by XueYulun on 15/6/30.
//
//

#import "DLFrameHttpEngin.h"

@interface DLFrameHttpEngin ()

- (DLFrameRequest *)queueRequest: (NSString *)path
                          method: (DLHTTPRequestMethod)method
                      parameters: (NSDictionary *)parameters
                      saveToPath: (NSString *)savePath
                        progress: (void (^)(float))progressBlock
                      completion: (DLHTTPRequestCompletionHandler)completionBlock;

@end

@implementation DLFrameHttpEngin

+ (instancetype)sharedClient {
    return [self sharedClientWithIdentifier:@"master"];
}

+ (instancetype)sharedClientWithIdentifier:(NSString *)identifier {
    DLFrameHttpEngin *sharedClient = [[self sharedClients] objectForKey:identifier];
    
    if(!sharedClient) {
        sharedClient = [[self alloc] init];
        [[self sharedClients] setObject:sharedClient forKey:identifier];
    }
    
    return sharedClient;
}

+ (id)sharedClients {
    static NSMutableDictionary *_sharedClients = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{ _sharedClients = [[NSMutableDictionary alloc] init]; });
    return _sharedClients;
}

- (id)init {
    if (self = [super init]) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.basePath = @"";
    }
    
    return self;
}


#pragma mark - Setters


- (void)setBasicAuthWithUsername:(NSString *)newUsername password:(NSString *)newPassword {
    self.username = newUsername;
    self.password = newPassword;
}

#pragma mark - Request Methods

- (DLFrameRequest*)GET:(NSString *)path parameters:(NSDictionary *)parameters completion:(DLHTTPRequestCompletionHandler)completionBlock {
    return [self queueRequest:path method:DLHTTPRequestMethodGET parameters:parameters saveToPath:nil progress:nil completion:completionBlock];
}

- (DLFrameRequest*)GET:(NSString *)path parameters:(NSDictionary *)parameters saveToPath:(NSString *)savePath progress:(void (^)(float))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock {
    return [self queueRequest:path method:DLHTTPRequestMethodGET parameters:parameters saveToPath:savePath progress:progressBlock completion:completionBlock];
}

- (DLFrameRequest*)POST:(NSString *)path parameters:(NSDictionary *)parameters completion:(DLHTTPRequestCompletionHandler)completionBlock {
    return [self queueRequest:path method:DLHTTPRequestMethodPOST parameters:parameters saveToPath:nil progress:nil completion:completionBlock];
}

- (DLFrameRequest*)POST:(NSString *)path parameters:(NSDictionary *)parameters progress:(void (^)(float))progressBlock completion:(void (^)(id, NSHTTPURLResponse*, NSError *))completionBlock {
    return [self queueRequest:path method:DLHTTPRequestMethodPOST parameters:parameters saveToPath:nil progress:progressBlock completion:completionBlock];
}

#pragma mark - Operation Cancelling

- (void)cancelRequestsWithPath:(NSString *)path {
    [self.operationQueue.operations enumerateObjectsUsingBlock:^(id request, NSUInteger idx, BOOL *stop) {
        NSString *requestPath = [request valueForKey:@"requestPath"];
        if([requestPath isEqualToString:path])
            [request cancel];
    }];
}

- (void)cancelAllRequests {
    [self.operationQueue cancelAllOperations];
}

#pragma mark -

- (NSMutableDictionary *)HTTPHeaderFields {
    if(_HTTPHeaderFields == nil)
        _HTTPHeaderFields = [NSMutableDictionary new];
    
    return _HTTPHeaderFields;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.HTTPHeaderFields setValue:value forKey:field];
}

- (DLFrameRequest*)queueRequest:(NSString*)path
                        method:(DLHTTPRequestMethod)method
                    parameters:(NSDictionary*)parameters
                    saveToPath:(NSString*)savePath
                      progress:(void (^)(float))progressBlock
                    completion:(DLHTTPRequestCompletionHandler)completionBlock  {
    
    NSString *completeURLString = [NSString stringWithFormat:@"%@%@", self.basePath, path];
    id mergedParameters;
    
    if((method == DLHTTPRequestMethodPOST) && self.sendParametersAsJSON && ![parameters isKindOfClass:[NSDictionary class]])
        mergedParameters = parameters;
    else {
        mergedParameters = [NSMutableDictionary dictionary];
        [mergedParameters addEntriesFromDictionary:parameters];
        [mergedParameters addEntriesFromDictionary:self.baseParameters];
    }
    
    DLFrameRequest *requestOperation = [(id<DLFrameRequestPrivateMethods>)[DLFrameRequest alloc] initWithAddress:completeURLString
                                                                                                       method:method
                                                                                                   parameters:mergedParameters
                                                                                                   saveToPath:savePath
                                                                                                     progress:progressBlock
                                                                                                   completion:completionBlock];
    return [self queueRequest:requestOperation];
}

- (DLFrameRequest *)queueRequest:(DLFrameRequest *)requestOperation {
    requestOperation.sendParametersAsJSON = self.sendParametersAsJSON;
    requestOperation.cachePolicy = self.cachePolicy;
    requestOperation.userAgent = self.userAgent;
    requestOperation.timeoutInterval = self.timeoutInterval;
    
    [(id<DLFrameRequestPrivateMethods>)requestOperation setClient:self];
    
    [self.HTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [requestOperation setValue:value forHTTPHeaderField:field];
    }];
    
    if(self.username && self.password)
        [(id<DLFrameRequestPrivateMethods>)requestOperation signRequestWithUsername:self.username password:self.password];
    
    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}


@end
