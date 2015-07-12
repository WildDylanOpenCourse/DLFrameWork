
///----------------------------------
///  @name 系统相关信息
///----------------------------------

#import <UIKit/UIKit.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface DLExtension : UIDevice

+ (NSUInteger)ramSize;

+ (NSUInteger)cpuNumber;

+ (NSUInteger)totalMemory;

+ (NSUInteger)userMemory;

+ (NSNumber *)totalDiskSpace;

+ (NSNumber *)freeDiskSpace;

+ (NSString *)macAddress;

@end
