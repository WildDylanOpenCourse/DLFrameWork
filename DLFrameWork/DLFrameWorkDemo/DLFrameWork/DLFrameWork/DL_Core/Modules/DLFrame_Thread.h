//
//  DLFrame_Thread.h
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name 常用线程
///----------------------------------

#pragma mark -

// 主队列
#undef	dispatch_async_foreground
#define dispatch_async_foreground( block ) \
dispatch_async( dispatch_get_main_queue(), block )

#undef	dispatch_after_foreground
#define dispatch_after_foreground( seconds, block ) \
{ \
dispatch_time_t __time = dispatch_time( DISPATCH_TIME_NOW, seconds * 1ull * NSEC_PER_SEC ); \
dispatch_after( __time, dispatch_get_main_queue(), block ); \
}

// 自己建的后台并行队列
#undef	dispatch_async_background
#define dispatch_async_background( block )      dispatch_async_background_concurrent( block )

#undef	dispatch_async_background_concurrent
#define dispatch_async_background_concurrent( block ) \
dispatch_async( [DLFrameGCD sharedInstance].backConcurrentQueue, block )

#undef	dispatch_after_background_concurrent
#define dispatch_after_background_concurrent( seconds, block ) \
{ \
dispatch_time_t __time = dispatch_time( DISPATCH_TIME_NOW, seconds * 1ull * NSEC_PER_SEC ); \
dispatch_after( __time, [DLFrameGCD sharedInstance].backConcurrentQueue, block ); \
}

// 自己建的后台串行队列
#undef	dispatch_async_background_serial
#define dispatch_async_background_serial( block ) \
dispatch_async( [DLFrameGCD sharedInstance].backSerialQueue, block )

#undef	dispatch_after_background_serial
#define dispatch_after_background_serial( seconds, block ) \
{ \
dispatch_time_t __time = dispatch_time( DISPATCH_TIME_NOW, seconds * 1ull * NSEC_PER_SEC ); \
dispatch_after( __time, [DLFrameGCD sharedInstance].backSerialQueue, block ); \
}

// 自己建写的文件用的串行队列
#undef	dispatch_async_background_writeFile
#define dispatch_async_background_writeFile( block ) \
dispatch_async( [DLFrameGCD sharedInstance].writeFileQueue, block )


// barrier
#undef	dispatch_barrier_async_foreground
#define dispatch_barrier_async_foreground( seconds, block ) \
dispatch_barrier_async( [DLFrameGCD sharedInstance].backConcurrentQueue, ^{   \
dispatch_async_foreground( block );   \
});

#undef	dispatch_barrier_async_background_concurrent
#define dispatch_barrier_async_background_concurrent( seconds, block ) \
dispatch_barrier_async( [DLFrameGCD sharedInstance].backConcurrentQueue, block )

#pragma mark -

@interface DLFrameGCD : NSObject

@singleton( DLFrameGCD )

/*!
 *  线程
 */
@prop_readonly(dispatch_queue_t, foreQueue );
@prop_readonly(dispatch_queue_t, backSerialQueue );
@prop_readonly(dispatch_queue_t, backConcurrentQueue );
@prop_readonly(dispatch_queue_t, writeFileQueue );

@end

///----------------------------------
///  @name protocal
///----------------------------------

@protocol NSLockProtocol <NSObject>
@optional

- (void)lock;
- (void)unlock;
@end
