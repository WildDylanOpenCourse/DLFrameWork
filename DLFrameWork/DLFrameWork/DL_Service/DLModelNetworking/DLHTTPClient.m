#import "DLHTTPClient.h"

#pragma mark - constants
NSString* const kHTTPMethodGET = @"GET";
NSString* const kHTTPMethodPOST = @"POST";

NSString* const kContentTypeAutomatic    = @"DLModel/automatic";
NSString* const kContentTypeJSON         = @"application/json";
NSString* const kContentTypeWWWEncoded   = @"application/x-www-form-urlencoded";

#pragma mark - static variables

static NSStringEncoding defaultTextEncoding = NSUTF8StringEncoding;
static NSURLRequestCachePolicy defaultCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
static int defaultTimeoutInSeconds = 60;
static NSMutableDictionary* requestHeaders = nil;
static NSString* requestContentType = nil;

#pragma mark - implementation
@implementation DLHTTPClient

#pragma mark - initialization
+(void)initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        requestHeaders = [NSMutableDictionary dictionary];
        requestContentType = kContentTypeAutomatic;
    });
}

#pragma mark - configuration methods
+(NSMutableDictionary*)requestHeaders
{
    return requestHeaders;
}

+(void)setDefaultTextEncoding:(NSStringEncoding)encoding
{
    defaultTextEncoding = encoding;
}

+(void)setCachingPolicy:(NSURLRequestCachePolicy)policy
{
    defaultCachePolicy = policy;
}

+(void)setTimeoutInSeconds:(int)seconds
{
    defaultTimeoutInSeconds = seconds;
}

+(void)setRequestContentType:(NSString*)contentTypeString
{
    requestContentType = contentTypeString;
}

#pragma mark - helper methods
+(NSString*)contentTypeForRequestString:(NSString*)requestString {
    
    NSString* contentType = requestContentType;

    if (requestString.length>0 && [contentType isEqualToString:kContentTypeAutomatic]) {
        //check for "eventual" JSON array or dictionary
        NSString* firstAndLastChar = [NSString stringWithFormat:@"%@%@",
                                      [requestString substringToIndex:1],
                                      [requestString substringFromIndex: requestString.length -1]
                                      ];
        
        if ([firstAndLastChar isEqualToString:@"{}"] || [firstAndLastChar isEqualToString:@"[]"]) {
            //guessing for a JSON request
            contentType = kContentTypeJSON;
        } else {
            //fallback to www form encoded params
            contentType = kContentTypeWWWEncoded;
        }
    }
    
    //type is set, just add charset
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [NSString stringWithFormat:@"%@; charset=%@", contentType, charset];
}

+(NSString*)urlEncode:(id<NSObject>)value
{
    //make sure param is a string
    if ([value isKindOfClass:[NSNumber class]]) {
        value = [(NSNumber*)value stringValue];
    }
    
    NSAssert([value isKindOfClass:[NSString class]], @"request parameters can be only of NSString or NSNumber classes. '%@' is of class %@.", value, [value class]);
        
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (__bridge CFStringRef) value,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8));
}

#pragma mark - networking worker methods
+(NSData*)syncRequestDataFromURL:(NSURL*)url method:(NSString*)method requestBody:(NSData*)bodyData headers:(NSDictionary*)headers etag:(NSString**)etag error:(DLModelError**)err
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: url
                                                                cachePolicy: defaultCachePolicy
                                                            timeoutInterval: defaultTimeoutInSeconds];
	[request setHTTPMethod:method];

    if ([requestContentType isEqualToString:kContentTypeAutomatic]) {
        //automatic content type
        if (bodyData) {
            NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
            [request setValue: [self contentTypeForRequestString: bodyString] forHTTPHeaderField:@"Content-type"];
        }
    } else {
        //user set content type
        [request setValue: requestContentType forHTTPHeaderField:@"Content-type"];
    }
    
    //add all the custom headers defined
    for (NSString* key in [requestHeaders allKeys]) {
        [request setValue:requestHeaders[key] forHTTPHeaderField:key];
    }
    
    //add the custom headers
    for (NSString* key in [headers allKeys]) {
        [request setValue:headers[key] forHTTPHeaderField:key];
    }
    
    if (bodyData) {
        [request setHTTPBody: bodyData];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }
    
    //prepare output
	NSHTTPURLResponse* response = nil;
    
    //fire the request
	NSData *responseData = [NSURLConnection sendSynchronousRequest: request
                                                 returningResponse: &response
                                                             error: err];
    //convert an NSError to a DLModelError
    if (*err != nil) {
        NSError* errObj = *err;
        *err = [DLModelError errorWithDomain:errObj.domain code:errObj.code userInfo:errObj.userInfo];
    }
    
    //special case for http error code 401
    if ([*err code] == kCFURLErrorUserCancelledAuthentication) {
        response = [[NSHTTPURLResponse alloc] initWithURL:url
                                               statusCode:401
                                              HTTPVersion:@"HTTP/1.1"
                                             headerFields:@{}];
    }
    
    //if not OK status set the err to a DLModelError instance
	if (response.statusCode >= 300 || response.statusCode < 200) {
        //create a new error
        if (*err==nil) *err = [DLModelError errorBadResponse];
    }
    
    //if there was an error, include the HTTP response and return
    if (*err) {
        //assign the response to the DLModel instance
        [*err setHttpResponse: [response copy]];

        //empty respone, return nil instead
        if ([responseData length] < 1) {
            return nil;
        }
    }
    
    //return the data fetched from web
    return responseData;
}

+(NSData*)syncRequestDataFromURL:(NSURL*)url method:(NSString*)method params:(NSDictionary*)params headers:(NSDictionary*)headers etag:(NSString**)etag error:(DLModelError**)err
{
    //create the request body
    NSMutableString* paramsString = nil;

    if (params) {
        //build a simple url encoded param string
        paramsString = [NSMutableString stringWithString:@""];
        for (NSString* key in [[params allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            [paramsString appendFormat:@"%@=%@&", key, [self urlEncode:params[key]] ];
        }
        if ([paramsString hasSuffix:@"&"]) {
            paramsString = [[NSMutableString alloc] initWithString: [paramsString substringToIndex: paramsString.length-1]];
        }
    }
    
    //set the request params
    if ([method isEqualToString:kHTTPMethodGET] && params) {

        //add GET params to the query string
        url = [NSURL URLWithString:[NSString stringWithFormat: @"%@%@%@",
                                    [url absoluteString],
                                    [url query] ? @"&" : @"?",
                                    paramsString
                                    ]];
    }
    
    //call the more general synq request method
    return [self syncRequestDataFromURL: url
                                 method: method
                            requestBody: [method isEqualToString:kHTTPMethodPOST]?[paramsString dataUsingEncoding:NSUTF8StringEncoding]:nil
                                headers: headers
                                   etag: etag
                                  error: err];
}

#pragma mark - Async network request
+(void)JSONFromURLWithString:(NSString*)urlString method:(NSString*)method params:(NSDictionary*)params orBodyString:(NSString*)bodyString completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString
                         method:method
                         params:params
                   orBodyString:bodyString
                        headers:nil
                     completion:completeBlock];
}

+(void)JSONFromURLWithString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params orBodyString:(NSString *)bodyString headers:(NSDictionary *)headers completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString
                         method:method
                         params:params
                     orBodyData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]
                        headers:headers
                     completion:completeBlock];
}

+(void)JSONFromURLWithString:(NSString*)urlString method:(NSString*)method params:(NSDictionary *)params orBodyData:(NSData*)bodyData headers:(NSDictionary*)headers completion:(JSONObjectBlock)completeBlock
{
    NSDictionary* customHeaders = headers;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        id jsonObject = nil;
        DLModelError* error = nil;
        NSData* responseData = nil;
        NSString* etag = nil;
        
        @try {
            if (bodyData) {
                responseData = [self syncRequestDataFromURL: [NSURL URLWithString:urlString]
                                                     method: method
                                                requestBody: bodyData
                                                    headers: customHeaders
                                                       etag: &etag
                                                      error: &error];
            } else {
                responseData = [self syncRequestDataFromURL: [NSURL URLWithString:urlString]
                                                     method: method
                                                     params: params
                                                    headers: customHeaders
                                                       etag: &etag
                                                      error: &error];
            }
        }
        @catch (NSException *exception) {
            error = [DLModelError errorBadResponse];
        }
        
        //step 3: if there's no response so far, return a basic error
        if (!responseData && !error) {
            //check for false response, but no network error
            error = [DLModelError errorBadResponse];
        }

        //step 4: if there's a response at this and no errors, convert to object
        if (error==nil) {
			// Note: it is possible to have a valid response with empty response data (204 No Content).
			// So only create the JSON object if there is some response data.
			if(responseData.length > 0)
			{
				//convert to an object
				jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
			}
        }
        //step 4.5: cover an edge case in which meaningful content is return along an error HTTP status code
        else if (error && responseData && jsonObject==nil) {
            //try to get the JSON object, while preserving the origianl error object
            jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        }
        
        //step 5: invoke the complete block
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                completeBlock(jsonObject, error);
            }
        });
    });
}

#pragma mark - request aliases
+(void)getJSONFromURLWithString:(NSString*)urlString completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString method:kHTTPMethodGET
                         params:nil
                   orBodyString:nil completion:^(id json, DLModelError* e) {
                       if (completeBlock) completeBlock(json, e);
                   }];
}

+(void)getJSONFromURLWithString:(NSString*)urlString params:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString method:kHTTPMethodGET
                         params:params
                   orBodyString:nil completion:^(id json, DLModelError* e) {
                       if (completeBlock) completeBlock(json, e);
                   }];
}

+(void)postJSONFromURLWithString:(NSString*)urlString params:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString method:kHTTPMethodPOST
                         params:params
                   orBodyString:nil completion:^(id json, DLModelError* e) {
                       if (completeBlock) completeBlock(json, e);
                   }];

}

+(void)postJSONFromURLWithString:(NSString*)urlString bodyString:(NSString*)bodyString completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString method:kHTTPMethodPOST
                         params:nil
                   orBodyString:bodyString completion:^(id json, DLModelError* e) {
                       if (completeBlock) completeBlock(json, e);
                   }];
}

+(void)postJSONFromURLWithString:(NSString*)urlString bodyData:(NSData*)bodyData completion:(JSONObjectBlock)completeBlock
{
    [self JSONFromURLWithString:urlString method:kHTTPMethodPOST
                         params:nil
                   orBodyString:[[NSString alloc] initWithData:bodyData encoding:defaultTextEncoding]
                                 completion:^(id json, DLModelError* e) {
                       if (completeBlock) completeBlock(json, e);
                   }];
}

@end
