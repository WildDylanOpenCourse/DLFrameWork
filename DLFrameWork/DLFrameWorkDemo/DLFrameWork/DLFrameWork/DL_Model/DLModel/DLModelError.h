#import <Foundation/Foundation.h>

typedef NS_ENUM(int, kDLModelErrorTypes)
{
    kDLModelErrorInvalidData = 1,
    kDLModelErrorBadResponse = 2,
    kDLModelErrorBadJSON = 3,
    kDLModelErrorModelIsInvalid = 4,
    kDLModelErrorNilInput = 5
};

extern NSString* const DLModelErrorDomain;
extern NSString* const kDLModelMissingKeys;
extern NSString* const kDLModelTypeMismatch;
extern NSString* const kDLModelKeyPath;

@interface DLModelError : NSError

@property (strong, nonatomic) NSHTTPURLResponse* httpResponse;

+(id)errorInvalidDataWithMessage:(NSString*)message;
+(id)errorInvalidDataWithMissingKeys:(NSSet*)keys;
+(id)errorInvalidDataWithTypeMismatch:(NSString*)mismatchDescription;
+(id)errorBadResponse;
+(id)errorBadJSON;
+(id)errorModelIsInvalid;
+(id)errorInputIsNil;
- (instancetype)errorByPrependingKeyPathComponent:(NSString*)component;

@end
