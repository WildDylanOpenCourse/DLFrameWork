//
//  DLError.h
//
//  Created by XueYulun on 15/3/24.
//

#import <Foundation/Foundation.h>

@interface DLError : NSObject

+ (void)ErrorMessage: (NSString *)message;

+ (void)Error: (NSError *)error;

+ (void)ThrowException: (NSException *)exception;

+ (void)Assert: (NSInteger)condition desc: (NSString *)descript;

+ (void)throwExceptionWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo;

@prop_strong(NSString *, errorMessage);
@prop_assign(NSInteger, errorCode);
@prop_strong(NSDictionary *, errorInfo);

+ (DLError *)errorWithInfo: (NSDictionary *)info Code: (NSInteger)code;
+ (DLError *)errorWithMessage: (NSString *)message Code: (NSInteger)code;

- (void)showErrorAlert;

- (NSString *)descriptions;

@end
