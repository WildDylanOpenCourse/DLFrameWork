#import <Foundation/Foundation.h>

@protocol DLFramePingerDelegate;

@interface DLFramePinger : NSObject

@property (nonatomic, weak) id<DLFramePingerDelegate> delegate;
@property (nonatomic, copy) NSString *domainOrIp;

/**
 * ping的次数, 默认为6次
 */
@property (nonatomic, assign) NSUInteger averageNumberOfPings;

/**
 * 两次ping中间等待时间, 默认位1秒
 */
@property (nonatomic, assign) NSTimeInterval pingWaitTime;

/**
 * @param 域名或者IPV4
 */
- (id)initWithHost:(NSString *)domainOrIp;

/**
 * 开始ping目标域
 */
- (void)startPinging;

/**
 * 停止
 */
- (void)stopPinging;

@end

@protocol DLFramePingerDelegate <NSObject>

- (void)pinger:(DLFramePinger *)pinger didUpdateWithAverageSeconds:(NSTimeInterval)seconds;

@optional

- (void)pinger:(DLFramePinger *)pinger didEncounterError:(NSError *)error;

@end
