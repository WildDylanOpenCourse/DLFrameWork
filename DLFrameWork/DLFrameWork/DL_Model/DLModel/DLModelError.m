#import "DLModelError.h"

NSString* const DLModelErrorDomain = @"DLModelErrorDomain";
NSString* const kDLModelMissingKeys = @"kDLModelMissingKeys";
NSString* const kDLModelTypeMismatch = @"kDLModelTypeMismatch";
NSString* const kDLModelKeyPath = @"kDLModelKeyPath";

@implementation DLModelError

+(id)errorInvalidDataWithMessage:(NSString*)message
{
	message = [NSString stringWithFormat:@"Invalid JSON data: %@", message];
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:message}];
}

+(id)errorInvalidDataWithMissingKeys:(NSSet *)keys
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON data. Required JSON keys are missing from the input. Check the error user information.",kDLModelMissingKeys:[keys allObjects]}];
}

+(id)errorInvalidDataWithTypeMismatch:(NSString*)mismatchDescription
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON data. The JSON type mismatches the expected type. Check the error user information.",kDLModelTypeMismatch:mismatchDescription}];
}

+(id)errorBadResponse
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorBadResponse
                                  userInfo:@{NSLocalizedDescriptionKey:@"Bad network response. Probably the JSON URL is unreachable."}];
}

+(id)errorBadJSON
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorBadJSON
                                  userInfo:@{NSLocalizedDescriptionKey:@"Malformed JSON. Check the DLModel data input."}];    
}

+(id)errorModelIsInvalid
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorModelIsInvalid
                                  userInfo:@{NSLocalizedDescriptionKey:@"Model does not validate. The custom validation for the input data failed."}];
}

+(id)errorInputIsNil
{
    return [DLModelError errorWithDomain:DLModelErrorDomain
                                      code:kDLModelErrorNilInput
                                  userInfo:@{NSLocalizedDescriptionKey:@"Initializing model with nil input object."}];
}

- (instancetype)errorByPrependingKeyPathComponent:(NSString*)component
{
    // Create a mutable  copy of the user info so that we can add to it and update it
    NSMutableDictionary* userInfo = [self.userInfo mutableCopy];

    // Create or update the key-path
    NSString* existingPath = userInfo[kDLModelKeyPath];
    NSString* separator = [existingPath hasPrefix:@"["] ? @"" : @".";
    NSString* updatedPath = (existingPath == nil) ? component : [component stringByAppendingFormat:@"%@%@", separator, existingPath];
    userInfo[kDLModelKeyPath] = updatedPath;

    // Create the new error
    return [DLModelError errorWithDomain:self.domain
                                      code:self.code
                                  userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

@end
