#import "DLModel+networking.h"
#import "DLHTTPClient.h"

BOOL _isLoading;

@implementation DLModel(Networking)

@dynamic isLoading;

-(BOOL)isLoading
{
    return _isLoading;
}

-(void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;
}

-(instancetype)initFromURLWithString:(NSString *)urlString completion:(DLModelBlock)completeBlock
{
    id placeholder = [super init];
    __block id blockSelf = self;
    
    if (placeholder) {
        //initialization
        self.isLoading = YES;
        
        [DLHTTPClient getJSONFromURLWithString:urlString
                                      completion:^(NSDictionary *json, DLModelError* e) {
                                          
                                          DLModelError* initError = nil;
                                          blockSelf = [self initWithDictionary:json error:&initError];
                                          
                                          if (completeBlock) {
                                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                                                  completeBlock(blockSelf, e?e:initError );
                                              });
                                          }
                                          
                                          self.isLoading = NO;
                                          
                                      }];
    }
    return placeholder;
}

+ (void)getModelFromURLWithString:(NSString*)urlString completion:(DLModelBlock)completeBlock
{
	[DLHTTPClient getJSONFromURLWithString:urlString
								  completion:^(NSDictionary* jsonDict, DLModelError* err)
	{
		DLModel* model = nil;

		if(err == nil)
		{
			model = [[self alloc] initWithDictionary:jsonDict error:&err];
		}

		if(completeBlock != nil)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				completeBlock(model, err);
			});
		}
    }];
}

+ (void)postModel:(DLModel*)post toURLWithString:(NSString*)urlString completion:(DLModelBlock)completeBlock
{
	[DLHTTPClient postJSONFromURLWithString:urlString
								   bodyString:[post toJSONString]
								   completion:^(NSDictionary* jsonDict, DLModelError* err)
	{
		DLModel* model = nil;

		if(err == nil)
		{
			model = [[self alloc] initWithDictionary:jsonDict error:&err];
		}

		if(completeBlock != nil)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				completeBlock(model, err);
			});
		}
	}];
}

@end
