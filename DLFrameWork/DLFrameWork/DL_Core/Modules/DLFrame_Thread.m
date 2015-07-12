//
//  DLFrame_Thread.m
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name code
///----------------------------------

@implementation DLFrameGCD

@def_singleton( DLFrameGCD )

@def_prop_strong(dispatch_queue_t,			foreQueue );
@def_prop_strong(dispatch_queue_t,			backSerialQueue );
@def_prop_strong(dispatch_queue_t,			backConcurrentQueue );
@def_prop_strong(dispatch_queue_t,			writeFileQueue );

- (id)init
{
    self = [super init];
    if ( self )
    {
        _foreQueue           = dispatch_get_main_queue();
        _backSerialQueue     = dispatch_queue_create( "com.samurai.backSerialQueue", DISPATCH_QUEUE_SERIAL );
        _backConcurrentQueue = dispatch_queue_create( "com.samurai.backConcurrentQueue", DISPATCH_QUEUE_CONCURRENT );
        _writeFileQueue      = dispatch_queue_create( "com.samurai.writeFileQueue", DISPATCH_QUEUE_SERIAL );
    }
    
    return self;
}

@end
