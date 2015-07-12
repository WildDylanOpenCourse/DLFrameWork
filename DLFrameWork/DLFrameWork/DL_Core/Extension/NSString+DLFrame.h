#import <Foundation/Foundation.h>

@interface NSString (DLFrame)

///----------------------------------
///  @name 字符串NSString常用验证扩展
///----------------------------------

- (BOOL)empty;
- (BOOL)notEmpty;
- (BOOL)eq:(NSString *)other;
- (BOOL)equal:(NSString *)other;
- (BOOL)is:(NSString *)other;
- (BOOL)isNot:(NSString *)other;
- (BOOL)isValueOf:(NSArray *)array;
- (BOOL)isValueOf:(NSArray *)array caseInsens:(BOOL)caseInsens;
- (BOOL)isNumber;
- (BOOL)isEmail;
- (BOOL)isUrl;
- (BOOL)isIPAddress;
- (NSString *)substringFromIndex:(NSUInteger)from untilString:(NSString *)string;

@end
