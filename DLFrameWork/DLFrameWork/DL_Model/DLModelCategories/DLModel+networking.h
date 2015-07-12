#import "DLModel.h"
#import "DLHTTPClient.h"

typedef void (^DLModelBlock)(id model, DLModelError* err);


@interface DLModel(Networking)

@property (assign, nonatomic) BOOL isLoading;

-(instancetype)initFromURLWithString:(NSString *)urlString completion:(DLModelBlock)completeBlock;

+ (void)getModelFromURLWithString:(NSString*)urlString completion:(DLModelBlock)completeBlock;
+ (void)postModel:(DLModel*)post toURLWithString:(NSString*)urlString completion:(DLModelBlock)completeBlock;


@end
