//
//  DLFrame_Singleton.h
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name 快速单例
///----------------------------------

#pragma mark -

#undef	singleton
#define singleton( __class ) \
property (nonatomic, readonly) __class * sharedInstance; \
- (__class *)sharedInstance; \
+ (__class *)sharedInstance;

#undef	def_singleton
#define def_singleton( __class ) \
dynamic sharedInstance; \
- (__class *)sharedInstance \
{ \
return [__class sharedInstance]; \
} \
+ (__class *)sharedInstance \
{ \
static dispatch_once_t once; \
static __strong id __singleton__ = nil; \
dispatch_once( &once, ^{ __singleton__ = [[__class alloc] init]; } ); \
return __singleton__; \
}

///----------------------------------
///  @name NSObject 扩展, 子类需要重载
///----------------------------------

#pragma mark -

@interface NSObject(Singleton)

+ (id)sharedInstance;
- (id)sharedInstance;

+ (id)sharedInstanceOrNew;
- (id)sharedInstanceOrNew;

@end
