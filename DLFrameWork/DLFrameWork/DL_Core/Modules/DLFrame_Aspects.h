
///----------------------------------
///  @name Method Hook
///----------------------------------

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, DLFrame_AspectOptions) {
    DLFrame_AspectPositionAfter   = 0,            /// Called after the original implementation (default)
    DLFrame_AspectPositionInstead = 1,            /// Will replace the original implementation.
    DLFrame_AspectPositionBefore  = 2,            /// Called before the original implementation.
    
    DLFrame_AspectOptionAutomaticRemoval = 1 << 3 /// Will remove the hook after the first execution.
};

@protocol DLFrame_AspectToken <NSObject>

/// @return YES if deregistration is successful, otherwise NO.
- (BOOL)remove;

@end

@protocol DLFrame_AspectInfo <NSObject>

- (id)instance;

- (NSInvocation *)originalInvocation;

/// All method arguments, boxed. This is lazily evaluated.
- (NSArray *)arguments;

@end

/**
 DLFrame_Aspects uses Objective-C message forwarding to hook into messages. This will create some overhead. Don't add DLFrame_Aspects to methods that are called a lot. DLFrame_Aspects is meant for view/controller code that is not called a 1000 times per second.

 Adding DLFrame_Aspects returns an opaque token which can be used to deregister again. All calls are thread safe.
 */
@interface NSObject (DLFrame_Aspects)

/// Adds a block of code before/instead/after the current `selector` for a specific class.
///
/// @param block DLFrame_Aspects replicates the type signature of the method being hooked.
/// The first parameter will be `id<DLFrame_AspectInfo>`, followed by all parameters of the method.
/// These parameters are optional and will be filled to match the block signature.
/// You can even use an empty block, or one that simple gets `id<DLFrame_AspectInfo>`.
///
/// @note Hooking static methods is not supported.
/// @return A token which allows to later deregister the DLFrame_Aspect.
+ (id<DLFrame_AspectToken>)DLFrame_Aspect_hookSelector:(SEL)selector
                           withOptions:(DLFrame_AspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

/// Adds a block of code before/instead/after the current `selector` for a specific instance.
- (id<DLFrame_AspectToken>)DLFrame_Aspect_hookSelector:(SEL)selector
                           withOptions:(DLFrame_AspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

@end


typedef NS_ENUM(NSUInteger, DLFrame_AspectErrorCode) {
    DLFrame_AspectErrorSelectorBlacklisted,                   /// Selectors like release, retain, autorelease are blacklisted.
    DLFrame_AspectErrorDoesNotRespondToSelector,              /// Selector could not be found.
    DLFrame_AspectErrorSelectorDeallocPosition,               /// When hooking dealloc, only DLFrame_AspectPositionBefore is allowed.
    DLFrame_AspectErrorSelectorAlreadyHookedInClassHierarchy, /// Statically hooking the same method in subclasses is not allowed.
    DLFrame_AspectErrorFailedToAllocateClassPair,             /// The runtime failed creating a class pair.
    DLFrame_AspectErrorMissingBlockSignature,                 /// The block misses compile time signature info and can't be called.
    DLFrame_AspectErrorIncompatibleBlockSignature,            /// The block signature does not match the method or is too large.

    DLFrame_AspectErrorRemoveObjectAlreadyDeallocated = 100   /// (for removing) The object hooked is already deallocated.
};

extern NSString *const DLFrame_AspectErrorDomain;
