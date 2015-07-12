//
//  DLFrameRequest.m
//  
//
//  Created by XueYulun on 15/6/26.
//
//

#import "DLFrameRequest.h"

@interface NSData (Base64)
- (NSString*)base64EncodingWithLineLength:(unsigned int)lineLength;
- (NSString *)getImageType;
- (BOOL)isJPG;
- (BOOL)isPNG;
- (BOOL)isGIF;
@end

@interface NSString (OAURLEncodingAdditions)
- (NSString*)encodedURLParameterString;
@end

enum {
    DLFrameRequestStateReady = 0,
    DLFrameRequestStateExecuting,
    DLFrameRequestStateFinished
};

typedef NSUInteger DLFrameRequestState;

static NSInteger DLFrameRequestTaskCount = 0;
static NSString *defaultUserAgent;
static NSTimeInterval DLFrameRequestTimeoutInterval = 20;

@interface DLFrameRequest ()

@prop_strong(NSDictionary *, parameters);
@prop_strong(NSMutableData *, operationData);
@prop_strong(NSFileHandle *, operationFileHandle);
@prop_strong(NSURLConnection *, operationConnection);
@prop_strong(NSHTTPURLResponse *, operationURLResponse);
@prop_strong(NSString *, operationSavePath);
@prop_assign(CFRunLoopRef, operationRunLoop);

#if TARGET_OS_IPHONE
@prop_assign(UIBackgroundTaskIdentifier, backgroundTaskIdentifier);
#endif

#if !OS_OBJECT_USE_OBJC
@prop_assign(dispatch_queue_t, saveDataDispatchQueue);
@prop_assign(dispatch_group_t, saveDataDispatchGroup);
#else
@prop_strong(dispatch_queue_t, saveDataDispatchQueue);
@prop_strong(dispatch_group_t, saveDataDispatchGroup);
#endif

@prop_copy(DLHTTPRequestCompletionHandler, operationCompletionBlock);
@prop_copy(void, (^operationProgressBlock)(float progress));

@prop_assign(DLFrameRequestState, state);
@prop_strong(NSString *, requestPath);
@prop_strong(DLFrameHttpEngin *, client);

@prop_strong(NSTimer *, timeoutTimer);

@prop_assign(float, expectedContentLength);
@prop_assign(float, receivedContentLength);

- (void)addParametersToRequest:(NSDictionary*)paramsDict;
- (void)finish;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error;

@end

@implementation DLFrameRequest

@synthesize state = _state;

- (void)dealloc {
    [_operationConnection cancel];
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_saveDataDispatchGroup);
    dispatch_release(_saveDataDispatchQueue);
#endif
}

+ (void)setDefaultTimeoutInterval:(NSTimeInterval)interval {
    DLFrameRequestTimeoutInterval = interval;
}

+ (void)setDefaultUserAgent:(NSString *)userAgent {
    defaultUserAgent = userAgent;
}

- (NSUInteger)timeoutInterval {
    if(_timeoutInterval == 0)
        return DLFrameRequestTimeoutInterval;
    return _timeoutInterval;
}

- (void)increaseDLFrameRequestTaskCount {
    DLFrameRequestTaskCount++;
    [self toggleNetworkActivityIndicator];
}

- (void)decreaseDLFrameRequestTaskCount {
    DLFrameRequestTaskCount = MAX(0, DLFrameRequestTaskCount-1);
    [self toggleNetworkActivityIndicator];
}

- (void)toggleNetworkActivityIndicator {
#if TARGET_OS_IPHONE && !__has_feature(attribute_availability_app_extension)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(DLFrameRequestTaskCount > 0)];
    });
#endif
}

#pragma mark - Convenience Methods

+ (DLFrameRequest*)GET:(NSString *)address parameters:(NSDictionary *)parameters completion:(DLHTTPRequestCompletionHandler)block {
    DLFrameRequest *requestObject = [[self alloc] initWithAddress:address method:DLHTTPRequestMethodGET parameters:parameters saveToPath:nil progress:nil completion:block];
    [requestObject start];
    
    return requestObject;
}

+ (DLFrameRequest*)GET:(NSString *)address parameters:(NSDictionary *)parameters saveToPath:(NSString *)savePath progress:(void (^)(float))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock {
    DLFrameRequest *requestObject = [[self alloc] initWithAddress:address method:DLHTTPRequestMethodGET parameters:parameters saveToPath:savePath progress:progressBlock completion:completionBlock];
    [requestObject start];
    
    return requestObject;
}

+ (DLFrameRequest*)POST:(NSString *)address parameters:(NSObject *)parameters completion:(DLHTTPRequestCompletionHandler)block {
    DLFrameRequest *requestObject = [[self alloc] initWithAddress:address method:DLHTTPRequestMethodPOST parameters:parameters saveToPath:nil progress:nil completion:block];
    [requestObject start];
    
    return requestObject;
}

+ (DLFrameRequest*)POST:(NSString *)address parameters:(NSObject *)parameters progress:(void (^)(float))progressBlock completion:(void (^)(id, NSHTTPURLResponse*, NSError *))completionBlock {
    DLFrameRequest *requestObject = [[self alloc] initWithAddress:address method:DLHTTPRequestMethodPOST parameters:parameters saveToPath:nil progress:progressBlock completion:completionBlock];
    [requestObject start];
    
    return requestObject;
}

#pragma mark -
- (DLFrameRequest*)initWithAddress:(NSString *)urlString method:(DLHTTPRequestMethod)method parameters:(NSDictionary *)parameters completion:(DLHTTPRequestCompletionHandler)completionBlock {
    return [(id<DLFrameRequestPrivateMethods>)self initWithAddress:urlString method:method parameters:parameters saveToPath:nil progress:NULL completion:completionBlock];
}

- (DLFrameRequest*)initWithAddress:(NSString*)urlString method:(DLHTTPRequestMethod)method parameters:(NSDictionary*)parameters saveToPath:(NSString*)savePath progress:(void (^)(float))progressBlock completion:(DLHTTPRequestCompletionHandler)completionBlock  {
    self = [super init];
    self.operationCompletionBlock = completionBlock;
    self.operationProgressBlock = progressBlock;
    self.operationSavePath = savePath;
    
    self.saveDataDispatchGroup = dispatch_group_create();
    self.saveDataDispatchQueue = dispatch_queue_create("com.samvermette.DLFrameRequest", DISPATCH_QUEUE_SERIAL);
    
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    self.operationRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *path = url.path;
    if ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }
    [self setRequestPath:path];
    
    if(method != DLHTTPRequestMethodPOST && !savePath)
        self.operationRequest.HTTPShouldUsePipelining = YES;
    
    if(method == DLHTTPRequestMethodGET)
        [self.operationRequest setHTTPMethod:@"GET"];
    else if(method == DLHTTPRequestMethodPOST)
        [self.operationRequest setHTTPMethod:@"POST"];
    
    self.state = DLFrameRequestStateReady;
    
    self.parameters = parameters;
    
    return self;
}

- (void)preprocessParameters {
    if(self.parameters)
        [self addParametersToRequest:self.parameters];
    self.parameters = nil;
}

- (void)addParametersToRequest:(NSObject*)parameters {
    
    NSString *method = self.operationRequest.HTTPMethod;
    
    if([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
        if(self.sendParametersAsJSON) {
            if([parameters isKindOfClass:[NSArray class]] || [parameters isKindOfClass:[NSDictionary class]]) {
                [self.operationRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                NSError *jsonError;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonError];
                [self.operationRequest setHTTPBody:jsonData];
            }
            else
                [NSException raise:NSInvalidArgumentException format:@"POST and PUT parameters must be provided as NSDictionary or NSArray when sendParametersAsJSON is set to YES."];
        }
        else if([parameters isKindOfClass:[NSDictionary class]]) {
            __block BOOL hasData = NO;
            NSDictionary *paramsDict = (NSDictionary*)parameters;
            
            [paramsDict.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if([obj isKindOfClass:[NSData class]] || [obj isKindOfClass:[NSURL class]])
                    hasData = YES;
                else if(![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]])
                    [NSException raise:NSInvalidArgumentException format:@"%@ requests only accept NSString and NSNumber parameters.", self.operationRequest.HTTPMethod];
            }];
            
            if(!hasData) {
                const char *stringData = [[self parameterStringForDictionary:paramsDict] UTF8String];
                NSMutableData *postData = [NSMutableData dataWithBytes:stringData length:strlen(stringData)];
                [self.operationRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [self.operationRequest setHTTPBody:postData];
            }
            else {
                NSString *boundary = @"DLFrameRequestBoundary";
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
                [self.operationRequest setValue:contentType forHTTPHeaderField: @"Content-Type"];
                
                __block NSMutableData *postData = [NSMutableData data];
                __block int dataIdx = 0;
                
                [paramsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if(![obj isKindOfClass:[NSData class]] && ![obj isKindOfClass:[NSURL class]]) {
                        [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                        [postData appendData:[[NSString stringWithFormat:@"%@", obj] dataUsingEncoding:NSUTF8StringEncoding]];
                        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    } else {
                        NSString *fileName = nil;
                        NSData *data = nil;
                        NSString *imageExtension = nil;
                        if ([obj isKindOfClass:[NSURL class]]) {
                            fileName = [obj lastPathComponent];
                            data = [NSData dataWithContentsOfURL:obj];
                        }
                        else {
                            imageExtension = [obj getImageType];
                            fileName = [NSString stringWithFormat:@"userfile%d%x", dataIdx, (int)[[NSDate date] timeIntervalSince1970]];
                            if (imageExtension != nil)
                                fileName = [fileName stringByAppendingPathExtension:imageExtension];
                            data = obj;
                        }
                        
                        [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"%@\"; filename=\"%@\"\r\n", key, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        if(imageExtension != nil) {
                            [postData appendData:[[NSString stringWithFormat:@"Content-Type: image/%@\r\n\r\n",imageExtension] dataUsingEncoding:NSUTF8StringEncoding]];
                        }
                        else {
                            [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                        }
                        
                        [postData appendData:data];
                        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                        dataIdx++;
                    }
                }];
                
                [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [self.operationRequest setHTTPBody:postData];
            }
        }
        else
            [NSException raise:NSInvalidArgumentException format:@"POST and PUT parameters must be provided as NSDictionary when sendParametersAsJSON is set to NO."];
    }
    else if([parameters isKindOfClass:[NSDictionary class]]) {
        NSDictionary *paramsDict = (NSDictionary*)parameters;
        NSString *baseAddress = self.operationRequest.URL.absoluteString;
        if(paramsDict.count > 0)
            baseAddress = [baseAddress stringByAppendingFormat:@"?%@", [self parameterStringForDictionary:paramsDict]];
        [self.operationRequest setURL:[NSURL URLWithString:baseAddress]];
    }
    else
        [NSException raise:NSInvalidArgumentException format:@"GET and DELETE parameters must be provided as NSDictionary."];
}

- (NSString*)parameterStringForDictionary:(NSDictionary*)parameters {
    NSMutableArray *stringParameters = [NSMutableArray arrayWithCapacity:parameters.count];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([obj isKindOfClass:[NSString class]]) {
            [stringParameters addObject:[NSString stringWithFormat:@"%@=%@", key, [obj encodedURLParameterString]]];
        }
        else if([obj isKindOfClass:[NSNumber class]]) {
            [stringParameters addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
        }
        else
            [NSException raise:NSInvalidArgumentException format:@"%@ requests only accept NSString, NSNumber and NSData parameters.", self.operationRequest.HTTPMethod];
    }];
    
    return [stringParameters componentsJoinedByString:@"&"];
}


- (void)signRequestWithUsername:(NSString*)username password:(NSString*)password  {
    
    // - Authorization - //
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:140]];
    [self.operationRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.operationRequest setValue:value forHTTPHeaderField:field];
}

- (void)setTimeoutTimer:(NSTimer *)newTimer {
    
    if(_timeoutTimer)
        [_timeoutTimer invalidate], _timeoutTimer = nil;
    
    if(newTimer)
        _timeoutTimer = newTimer;
}

#pragma mark - NSOperation methods

- (void)start {
    
    if(self.isCancelled) {
        [self finish];
        return;
    }
    
    [self preprocessParameters];
    
#if TARGET_OS_IPHONE && !__has_feature(attribute_availability_app_extension)
    
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if(self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self increaseDLFrameRequestTaskCount];
    });
    
    if(self.userAgent)
        [self.operationRequest setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    else if(defaultUserAgent)
        [self.operationRequest setValue:defaultUserAgent forHTTPHeaderField:@"User-Agent"];
    
    [self willChangeValueForKey:@"isExecuting"];
    self.state = DLFrameRequestStateExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    
    if(self.operationSavePath) {
        [[NSFileManager defaultManager] createFileAtPath:self.operationSavePath contents:nil attributes:nil];
        self.operationFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.operationSavePath];
    } else {
        self.operationData = [[NSMutableData alloc] init];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutInterval target:self selector:@selector(requestTimeout) userInfo:nil repeats:NO];
        [self.operationRequest setTimeoutInterval:self.timeoutInterval];
    }
    
    [self.operationRequest setCachePolicy:self.cachePolicy];
    self.operationConnection = [[NSURLConnection alloc] initWithRequest:self.operationRequest delegate:self startImmediately:NO];
    
    NSOperationQueue *currentQueue = [NSOperationQueue currentQueue];
    BOOL inBackgroundAndInOperationQueue = (currentQueue != nil && currentQueue != [NSOperationQueue mainQueue]);
    NSRunLoop *targetRunLoop = (inBackgroundAndInOperationQueue) ? [NSRunLoop currentRunLoop] : [NSRunLoop mainRunLoop];
    
    if(self.operationSavePath)
        [self.operationConnection scheduleInRunLoop:targetRunLoop forMode:NSRunLoopCommonModes];
    else
        [self.operationConnection scheduleInRunLoop:targetRunLoop forMode:NSDefaultRunLoopMode];
    
    [self.operationConnection start];
    
#if !(defined DLFrameRequest_DISABLE_LOGGING)
    NSLog(@"[%@] %@", self.operationRequest.HTTPMethod, self.operationRequest.URL.absoluteString);
#endif
    
    if(inBackgroundAndInOperationQueue) {
        self.operationRunLoop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    }
}

- (void)finish {
    [self.operationConnection cancel];
    self.operationConnection = nil;
    
    [self decreaseDLFrameRequestTaskCount];
    
#if TARGET_OS_IPHONE && !__has_feature(attribute_availability_app_extension)
    if(self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.state = DLFrameRequestStateFinished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    if(![self isExecuting])
        return;
    
    [super cancel];
    self.timeoutTimer = nil;
    [self finish];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.state == DLFrameRequestStateFinished;
}

- (BOOL)isExecuting {
    return self.state == DLFrameRequestStateExecuting;
}

- (DLFrameRequestState)state {
    @synchronized(self) {
        return _state;
    }
}

- (void)setState:(DLFrameRequestState)newState {
    @synchronized(self) {
        [self willChangeValueForKey:@"state"];
        _state = newState;
        [self didChangeValueForKey:@"state"];
    }
}

#pragma mark -
#pragma mark Delegate Methods

- (void)requestTimeout {
    
    NSURL *failingURL = self.operationRequest.URL;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"The operation timed out.", NSLocalizedDescriptionKey,
                              failingURL, NSURLErrorFailingURLErrorKey,
                              failingURL.absoluteString, NSURLErrorFailingURLStringErrorKey, nil];
    
    NSError *timeoutError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
    [self connection:nil didFailWithError:timeoutError];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.expectedContentLength = response.expectedContentLength;
    self.receivedContentLength = 0;
    self.operationURLResponse = (NSHTTPURLResponse*)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    dispatch_group_async(self.saveDataDispatchGroup, self.saveDataDispatchQueue, ^{
        if(self.operationSavePath) {
            @try {
                [self.operationFileHandle writeData:data];
            }
            @catch (NSException *exception) {
                [self.operationConnection cancel];
                NSError *writeError = [NSError errorWithDomain:@"DLFrameRequestWriteError" code:0 userInfo:exception.userInfo];
                [self callCompletionBlockWithResponse:nil error:writeError];
            }
        }
        else
            [self.operationData appendData:data];
    });
    
    if(self.operationProgressBlock) {
        
        if(self.expectedContentLength != -1) {
            self.receivedContentLength += data.length;
            self.operationProgressBlock(self.receivedContentLength/self.expectedContentLength);
        } else {
            
            self.operationProgressBlock(-1);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(self.operationProgressBlock && [self.operationRequest.HTTPMethod isEqualToString:@"POST"]) {
        self.operationProgressBlock((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    dispatch_group_notify(self.saveDataDispatchGroup, self.saveDataDispatchQueue, ^{
        
        id response = [NSData dataWithData:self.operationData];
        NSError *error = nil;
        
        if ([[self.operationURLResponse MIMEType] isEqualToString:@"application/json"]) {
            if(self.operationData && self.operationData.length > 0) {
                
                NSString *utf8String = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
                if (utf8String == nil) {
                    utf8String = [[NSString alloc] initWithData:response encoding:NSASCIIStringEncoding];
                }
                
                NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[utf8String dataUsingEncoding:NSUTF8StringEncoding]
                                                                           options:NSJSONReadingAllowFragments error:&error];
                
                if(jsonObject)
                    response = jsonObject;
            }
        }
        
        [self callCompletionBlockWithResponse:response error:error];
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self callCompletionBlockWithResponse:nil error:error];
}

- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error {
    self.timeoutTimer = nil;
    
    if(self.operationRunLoop)
        CFRunLoopStop(self.operationRunLoop);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *serverError = error;
        
        if(!serverError) {
            if(self.operationURLResponse.statusCode == 500) {
                serverError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorBadServerResponse
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"Bad Server Response.", NSLocalizedDescriptionKey,
                                                        self.operationRequest.URL, NSURLErrorFailingURLErrorKey,
                                                        self.operationRequest.URL.absoluteString, NSURLErrorFailingURLStringErrorKey, nil]];
            }
            else if(self.operationURLResponse.statusCode > 299) {
                serverError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:self.operationURLResponse.statusCode
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        self.operationRequest.URL, NSURLErrorFailingURLErrorKey,
                                                        self.operationRequest.URL.absoluteString, NSURLErrorFailingURLStringErrorKey, nil]];
                
            }
        }
        
        if(self.operationCompletionBlock && !self.isCancelled)
            self.operationCompletionBlock(response, self.operationURLResponse, serverError);
        
        [self finish];
    });
}

@end


@implementation NSString (DLFrameRequest)

- (NSString*)encodedURLParameterString {
    NSString *result = (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                            (__bridge CFStringRef)self,
                                                                                            NULL,
                                                                                            CFSTR(":/=,!$&'()*+;[]@#?^%\"`<>{}\\|~ "),
                                                                                            kCFStringEncodingUTF8);
    return result;
}

@end

static char encodingTable[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

@implementation NSData (DLFrameRequest)

- (NSString *)base64EncodingWithLineLength:(unsigned int) lineLength {
    const unsigned char	*bytes = [self bytes];
    NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];
    unsigned long ixtext = 0;
    unsigned long lentext = [self length];
    long ctremaining = 0;
    unsigned char inbuf[3], outbuf[4];
    short i = 0;
    unsigned int charsonline = 0;
    short ctcopy = 0;
    unsigned long ix = 0;
    
    while( YES ) {
        ctremaining = lentext - ixtext;
        if( ctremaining <= 0 ) break;
        
        for( i = 0; i < 3; i++ ) {
            ix = ixtext + i;
            if( ix < lentext ) inbuf[i] = bytes[ix];
            else inbuf [i] = 0;
        }
        
        outbuf [0] = (inbuf [0] & 0xFC) >> 2;
        outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
        outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
        outbuf [3] = inbuf [2] & 0x3F;
        ctcopy = 4;
        
        switch( ctremaining ) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for( i = 0; i < ctcopy; i++ )
            [result appendFormat:@"%c", encodingTable[outbuf[i]]];
        
        for( i = ctcopy; i < 4; i++ )
            [result appendFormat:@"%c",'='];
        
        ixtext += 3;
        charsonline += 4;
    }
    
    return result;
}

- (BOOL)isJPG {
    if (self.length > 4) {
        unsigned char buffer[4];
        [self getBytes:&buffer length:4];
        
        return buffer[0]==0xff &&
        buffer[1]==0xd8 &&
        buffer[2]==0xff &&
        buffer[3]==0xe0;
    }
    
    return NO;
}

- (BOOL)isPNG {
    if (self.length > 4) {
        unsigned char buffer[4];
        [self getBytes:&buffer length:4];
        
        return buffer[0]==0x89 &&
        buffer[1]==0x50 &&
        buffer[2]==0x4e &&
        buffer[3]==0x47;
    }
    
    return NO;
}

- (BOOL)isGIF {
    if(self.length >3) {
        unsigned char buffer[4];
        [self getBytes:&buffer length:4];
        
        return buffer[0]==0x47 &&
        buffer[1]==0x49 &&
        buffer[2]==0x46; //Signature ASCII 'G','I','F'
    }
    return  NO;
}

- (NSString *)getImageType {
    NSString *ret;
    if([self isJPG]) {
        ret=@"jpg";
    }
    else if([self isGIF]) {
        ret=@"gif";
    }
    else if([self isPNG]) {
        ret=@"png";
    }
    else {
        ret=nil;
    }
    return ret;
}

@end