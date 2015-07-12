//
//  DLError.m
//
//  Created by XueYulun on 15/3/24.
//

#import "DLError.h"

@implementation DLError

+ (void)ErrorMessage: (NSString *)message {
    
    DLogOut(@"%@", message);
}

+ (void)Error: (NSError *)error {
    
    DLogOut(@"Domain: %@_ Code: %ld_ Info: %@", error.domain, error.code, error.userInfo);
}

+ (void)ThrowException: (NSException *)exception {
    
    @throw exception;
}

+ (void)Assert: (NSInteger)condition desc: (NSString *)descript {
    
    NSAssert(condition, descript);
}

+ (void)throwExceptionWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo {
    
    @throw [NSException exceptionWithName:name reason:reason userInfo:userInfo];
}

+ (DLError *)errorWithInfo: (NSDictionary *)info  Code: (NSInteger)code{
    
    return [[DLError alloc] initWithMessage:@__DLFRAME_DOMAIN__ Info:info Code:code];
}

+ (DLError *)errorWithMessage: (NSString *)message  Code: (NSInteger)code{
    
    return [[DLError alloc] initWithMessage:message Info:nil Code:code];
}

- (instancetype)initWithMessage: (NSString *)message Info: (NSDictionary *)infoDict Code: (NSInteger)code {
    
    self = [super init];
    if (self) {
        
        self.errorMessage = message;
        self.errorCode = code;
        self.errorInfo = infoDict;
    }
    
    return self;
}

- (void)showErrorAlert {
    
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:self.errorMessage delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
    [alertView show];
}

- (NSString *)descriptions {
    
    return [NSString stringWithFormat:@"Message: %@_ Code: %ld_ Info: %@", self.errorMessage, self.errorCode, self.errorInfo];
}

@end
