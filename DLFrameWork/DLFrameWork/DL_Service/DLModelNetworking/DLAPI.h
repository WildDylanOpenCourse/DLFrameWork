#import <Foundation/Foundation.h>
#import "DLHTTPClient.h"

///----------------------------------
///  @name 
///----------------------------------

@interface DLAPI : NSObject

+(void)setAPIBaseURLWithString:(NSString*)base;
+(void)setContentType:(NSString*)ctype;

+(void)getWithPath:(NSString*)path andParams:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock;
+(void)postWithPath:(NSString*)path andParams:(NSDictionary*)params completion:(JSONObjectBlock)completeBlock;

/*
 json rpc 是一种以json为消息格式的远程调用服务
 它是一套允许运行在不同操作系统
 不同环境的程序实现基于Internet过程调用的规范和一系列的实现。
 
 这种远程过程调用可以使用http作为传输协议
 也可以使用其它传输协议
 传输的内容是json消息体。
 */
+(void)rpcWithMethodName:(NSString*)method andArguments:(NSArray*)args completion:(JSONObjectBlock)completeBlock;
+(void)rpc2WithMethodName:(NSString*)method andParams:(id)params completion:(JSONObjectBlock)completeBlock;

@end
