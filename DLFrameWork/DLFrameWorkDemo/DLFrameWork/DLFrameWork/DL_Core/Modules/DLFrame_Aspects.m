#import "DLFrame_Aspects.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define DLFrame_AspectLog(...)
//#define DLFrame_AspectLog(...) do { NSLog(__VA_ARGS__); }while(0)
#define DLFrame_AspectLogError(...) do { NSLog(__VA_ARGS__); }while(0)

// Block internals.
typedef NS_OPTIONS(int, DLFrame_AspectBlockFlags) {
	DLFrame_AspectBlockFlagsHasCopyDisposeHelpers = (1 << 25),
	DLFrame_AspectBlockFlagsHasSignature          = (1 << 30)
};
typedef struct _DLFrame_AspectBlock {
	__unused Class isa;
	DLFrame_AspectBlockFlags flags;
	__unused int reserved;
	void (__unused *invoke)(struct _DLFrame_AspectBlock *block, ...);
	struct {
		unsigned long int reserved;
		unsigned long int size;
		// requires DLFrame_AspectBlockFlagsHasCopyDisposeHelpers
		void (*copy)(void *dst, const void *src);
		void (*dispose)(const void *);
		// requires DLFrame_AspectBlockFlagsHasSignature
		const char *signature;
		const char *layout;
	} *descriptor;
	// imported variables
} *DLFrame_AspectBlockRef;

@interface DLFrame_AspectInfo : NSObject <DLFrame_AspectInfo>
- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation;
@property (nonatomic, unsafe_unretained, readonly) id instance;
@property (nonatomic, strong, readonly) NSArray *arguments;
@property (nonatomic, strong, readonly) NSInvocation *originalInvocation;
@end

// Tracks a single DLFrame_Aspect.
@interface DLFrame_AspectIdentifier : NSObject
+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(DLFrame_AspectOptions)options block:(id)block error:(NSError **)error;
- (BOOL)invokeWithInfo:(id<DLFrame_AspectInfo>)info;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id block;
@property (nonatomic, strong) NSMethodSignature *blockSignature;
@property (nonatomic, weak) id object;
@property (nonatomic, assign) DLFrame_AspectOptions options;
@end

// Tracks all DLFrame_Aspects for an object/class.
@interface DLFrame_AspectsContainer : NSObject
- (void)addDLFrame_Aspect:(DLFrame_AspectIdentifier *)DLFrame_Aspect withOptions:(DLFrame_AspectOptions)injectPosition;
- (BOOL)removeDLFrame_Aspect:(id)DLFrame_Aspect;
- (BOOL)hasDLFrame_Aspects;
@property (atomic, copy) NSArray *beforeDLFrame_Aspects;
@property (atomic, copy) NSArray *insteadDLFrame_Aspects;
@property (atomic, copy) NSArray *afterDLFrame_Aspects;
@end

@interface DLFrame_AspectTracker : NSObject
- (id)initWithTrackedClass:(Class)trackedClass parent:(DLFrame_AspectTracker *)parent;
@property (nonatomic, strong) Class trackedClass;
@property (nonatomic, strong) NSMutableSet *selectorNames;
@property (nonatomic, weak) DLFrame_AspectTracker *parentEntry;
@end

@interface NSInvocation (DLFrame_Aspects)
- (NSArray *)DLFrame_Aspects_arguments;
@end

#define DLFrame_AspectPositionFilter 0x07

#define DLFrame_AspectError(errorCode, errorDescription) do { \
DLFrame_AspectLogError(@"DLFrame_Aspects: %@", errorDescription); \
if (error) { *error = [NSError errorWithDomain:DLFrame_AspectErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorDescription}]; }}while(0)

NSString *const DLFrame_AspectErrorDomain = @"DLFrame_AspectErrorDomain";
static NSString *const DLFrame_AspectsSubclassSuffix = @"_DLFrame_Aspects_";
static NSString *const DLFrame_AspectsMessagePrefix = @"DLFrame_Aspects_";

@implementation NSObject (DLFrame_Aspects)

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public DLFrame_Aspects API

+ (id<DLFrame_AspectToken>)DLFrame_Aspect_hookSelector:(SEL)selector
                      withOptions:(DLFrame_AspectOptions)options
                       usingBlock:(id)block
                            error:(NSError **)error {
    return DLFrame_Aspect_add((id)self, selector, options, block, error);
}

/// @return A token which allows to later deregister the DLFrame_Aspect.
- (id<DLFrame_AspectToken>)DLFrame_Aspect_hookSelector:(SEL)selector
                      withOptions:(DLFrame_AspectOptions)options
                       usingBlock:(id)block
                            error:(NSError **)error {
    return DLFrame_Aspect_add(self, selector, options, block, error);
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Helper

static id DLFrame_Aspect_add(id self, SEL selector, DLFrame_AspectOptions options, id block, NSError **error) {
    NSCParameterAssert(self);
    NSCParameterAssert(selector);
    NSCParameterAssert(block);

    __block DLFrame_AspectIdentifier *identifier = nil;
    DLFrame_Aspect_performLocked(^{
        if (DLFrame_Aspect_isSelectorAllowedAndTrack(self, selector, options, error)) {
            DLFrame_AspectsContainer *DLFrame_AspectContainer = DLFrame_Aspect_getContainerForObject(self, selector);
            identifier = [DLFrame_AspectIdentifier identifierWithSelector:selector object:self options:options block:block error:error];
            if (identifier) {
                [DLFrame_AspectContainer addDLFrame_Aspect:identifier withOptions:options];

                // Modify the class to allow message interception.
                DLFrame_Aspect_prepareClassAndHookSelector(self, selector, error);
            }
        }
    });
    return identifier;
}

static BOOL DLFrame_Aspect_remove(DLFrame_AspectIdentifier *DLFrame_Aspect, NSError **error) {
    NSCAssert([DLFrame_Aspect isKindOfClass:DLFrame_AspectIdentifier.class], @"Must have correct type.");

    __block BOOL success = NO;
    DLFrame_Aspect_performLocked(^{
        id self = DLFrame_Aspect.object; // strongify
        if (self) {
            DLFrame_AspectsContainer *DLFrame_AspectContainer = DLFrame_Aspect_getContainerForObject(self, DLFrame_Aspect.selector);
            success = [DLFrame_AspectContainer removeDLFrame_Aspect:DLFrame_Aspect];

            DLFrame_Aspect_cleanupHookedClassAndSelector(self, DLFrame_Aspect.selector);
            // destroy token
            DLFrame_Aspect.object = nil;
            DLFrame_Aspect.block = nil;
            DLFrame_Aspect.selector = NULL;
        }else {
            NSString *errrorDesc = [NSString stringWithFormat:@"Unable to deregister hook. Object already deallocated: %@", DLFrame_Aspect];
            DLFrame_AspectError(DLFrame_AspectErrorRemoveObjectAlreadyDeallocated, errrorDesc);
        }
    });
    return success;
}

static void DLFrame_Aspect_performLocked(dispatch_block_t block) {
    static OSSpinLock DLFrame_Aspect_lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&DLFrame_Aspect_lock);
    block();
    OSSpinLockUnlock(&DLFrame_Aspect_lock);
}

static SEL DLFrame_Aspect_aliasForSelector(SEL selector) {
    NSCParameterAssert(selector);
	return NSSelectorFromString([DLFrame_AspectsMessagePrefix stringByAppendingFormat:@"_%@", NSStringFromSelector(selector)]);
}

static NSMethodSignature *DLFrame_Aspect_blockMethodSignature(id block, NSError **error) {
    DLFrame_AspectBlockRef layout = (__bridge void *)block;
	if (!(layout->flags & DLFrame_AspectBlockFlagsHasSignature)) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.", block];
        DLFrame_AspectError(DLFrame_AspectErrorMissingBlockSignature, description);
        return nil;
    }
	void *desc = layout->descriptor;
	desc += 2 * sizeof(unsigned long int);
	if (layout->flags & DLFrame_AspectBlockFlagsHasCopyDisposeHelpers) {
		desc += 2 * sizeof(void *);
    }
	if (!desc) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't has a type signature.", block];
        DLFrame_AspectError(DLFrame_AspectErrorMissingBlockSignature, description);
        return nil;
    }
	const char *signature = (*(const char **)desc);
	return [NSMethodSignature signatureWithObjCTypes:signature];
}

static BOOL DLFrame_Aspect_isCompatibleBlockSignature(NSMethodSignature *blockSignature, id object, SEL selector, NSError **error) {
    NSCParameterAssert(blockSignature);
    NSCParameterAssert(object);
    NSCParameterAssert(selector);

    BOOL signaturesMatch = YES;
    NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:selector];
    if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
        signaturesMatch = NO;
    }else {
        if (blockSignature.numberOfArguments > 1) {
            const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
            if (blockType[0] != '@') {
                signaturesMatch = NO;
            }
        }
        // Argument 0 is self/block, argument 1 is SEL or id<DLFrame_AspectInfo>. We start comparing at argument 2.
        // The block can have less arguments than the method, that's ok.
        if (signaturesMatch) {
            for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
                const char *methodType = [methodSignature getArgumentTypeAtIndex:idx];
                const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
                // Only compare parameter, not the optional type data.
                if (!methodType || !blockType || methodType[0] != blockType[0]) {
                    signaturesMatch = NO; break;
                }
            }
        }
    }

    if (!signaturesMatch) {
        NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
        DLFrame_AspectError(DLFrame_AspectErrorIncompatibleBlockSignature, description);
        return NO;
    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class + Selector Preparation

static BOOL DLFrame_Aspect_isMsgForwardIMP(IMP impl) {
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}

static IMP DLFrame_Aspect_getMsgForwardIMP(NSObject *self, SEL selector) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // As an ugly internal runtime implementation detail in the 32bit runtime, we need to determine of the method we hook returns a struct or anything larger than id.
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    Method method = class_getInstanceMethod(self.class, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);

            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (__unused NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}

static void DLFrame_Aspect_prepareClassAndHookSelector(NSObject *self, SEL selector, NSError **error) {
    NSCParameterAssert(selector);
    Class klass = DLFrame_Aspect_hookClass(self, error);
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    if (!DLFrame_Aspect_isMsgForwardIMP(targetMethodIMP)) {
        // Make a method alias for the existing method implementation, it not already copied.
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = DLFrame_Aspect_aliasForSelector(selector);
        if (![klass instancesRespondToSelector:aliasSelector]) {
            __unused BOOL addedAlias = class_addMethod(klass, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);
        }

        // We use forwardInvocation to hook in.
        class_replaceMethod(klass, selector, DLFrame_Aspect_getMsgForwardIMP(self, selector), typeEncoding);
        DLFrame_AspectLog(@"DLFrame_Aspects: Installed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }
}

// Will undo the runtime changes made.
static void DLFrame_Aspect_cleanupHookedClassAndSelector(NSObject *self, SEL selector) {
    NSCParameterAssert(self);
    NSCParameterAssert(selector);

	Class klass = object_getClass(self);
    BOOL isMetaClass = class_isMetaClass(klass);
    if (isMetaClass) {
        klass = (Class)self;
    }

    // Check if the method is marked as forwarded and undo that.
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    if (DLFrame_Aspect_isMsgForwardIMP(targetMethodIMP)) {
        // Restore the original method implementation.
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = DLFrame_Aspect_aliasForSelector(selector);
        Method originalMethod = class_getInstanceMethod(klass, aliasSelector);
        IMP originalIMP = method_getImplementation(originalMethod);
        NSCAssert(originalMethod, @"Original implementation for %@ not found %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);

        class_replaceMethod(klass, selector, originalIMP, typeEncoding);
        DLFrame_AspectLog(@"DLFrame_Aspects: Removed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }

    // Deregister global tracked selector
    DLFrame_Aspect_deregisterTrackedSelector(self, selector);

    // Get the DLFrame_Aspect container and check if there are any hooks remaining. Clean up if there are not.
    DLFrame_AspectsContainer *container = DLFrame_Aspect_getContainerForObject(self, selector);
    if (!container.hasDLFrame_Aspects) {
        // Destroy the container
        DLFrame_Aspect_destroyContainerForObject(self, selector);

        // Figure out how the class was modified to undo the changes.
        NSString *className = NSStringFromClass(klass);
        if ([className hasSuffix:DLFrame_AspectsSubclassSuffix]) {
            Class originalClass = NSClassFromString([className stringByReplacingOccurrencesOfString:DLFrame_AspectsSubclassSuffix withString:@""]);
            NSCAssert(originalClass != nil, @"Original class must exist");
            object_setClass(self, originalClass);
            DLFrame_AspectLog(@"DLFrame_Aspects: %@ has been restored.", NSStringFromClass(originalClass));

            // We can only dispose the class pair if we can ensure that no instances exist using our subclass.
            // Since we don't globally track this, we can't ensure this - but there's also not much overhead in keeping it around.
            //objc_disposeClassPair(object.class);
        }else {
            // Class is most likely swizzled in place. Undo that.
            if (isMetaClass) {
                DLFrame_Aspect_undoSwizzleClassInPlace((Class)self);
            }else if (self.class != klass) {
            	DLFrame_Aspect_undoSwizzleClassInPlace(klass);
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Hook Class

static Class DLFrame_Aspect_hookClass(NSObject *self, NSError **error) {
    NSCParameterAssert(self);
	Class statedClass = self.class;
	Class baseClass = object_getClass(self);
	NSString *className = NSStringFromClass(baseClass);

    // Already subclassed
	if ([className hasSuffix:DLFrame_AspectsSubclassSuffix]) {
		return baseClass;

        // We swizzle a class object, not a single object.
	}else if (class_isMetaClass(baseClass)) {
        return DLFrame_Aspect_swizzleClassInPlace((Class)self);
        // Probably a KVO'ed class. Swizzle in place. Also swizzle meta classes in place.
    }else if (statedClass != baseClass) {
        return DLFrame_Aspect_swizzleClassInPlace(baseClass);
    }

    // Default case. Create dynamic subclass.
	const char *subclassName = [className stringByAppendingString:DLFrame_AspectsSubclassSuffix].UTF8String;
	Class subclass = objc_getClass(subclassName);

	if (subclass == nil) {
		subclass = objc_allocateClassPair(baseClass, subclassName, 0);
		if (subclass == nil) {
            NSString *errrorDesc = [NSString stringWithFormat:@"objc_allocateClassPair failed to allocate class %s.", subclassName];
            DLFrame_AspectError(DLFrame_AspectErrorFailedToAllocateClassPair, errrorDesc);
            return nil;
        }

		DLFrame_Aspect_swizzleForwardInvocation(subclass);
		DLFrame_Aspect_hookedGetClass(subclass, statedClass);
		DLFrame_Aspect_hookedGetClass(object_getClass(subclass), statedClass);
		objc_registerClassPair(subclass);
	}

	object_setClass(self, subclass);
	return subclass;
}

static NSString *const DLFrame_AspectsForwardInvocationSelectorName = @"__DLFrame_Aspects_forwardInvocation:";
static void DLFrame_Aspect_swizzleForwardInvocation(Class klass) {
    NSCParameterAssert(klass);
    // If there is no method, replace will act like class_addMethod.
    IMP originalImplementation = class_replaceMethod(klass, @selector(forwardInvocation:), (IMP)__DLFrame_AspectS_ARE_BEING_CALLED__, "v@:@");
    if (originalImplementation) {
        class_addMethod(klass, NSSelectorFromString(DLFrame_AspectsForwardInvocationSelectorName), originalImplementation, "v@:@");
    }
    DLFrame_AspectLog(@"DLFrame_Aspects: %@ is now DLFrame_Aspect aware.", NSStringFromClass(klass));
}

static void DLFrame_Aspect_undoSwizzleForwardInvocation(Class klass) {
    NSCParameterAssert(klass);
    Method originalMethod = class_getInstanceMethod(klass, NSSelectorFromString(DLFrame_AspectsForwardInvocationSelectorName));
    Method objectMethod = class_getInstanceMethod(NSObject.class, @selector(forwardInvocation:));
    // There is no class_removeMethod, so the best we can do is to retore the original implementation, or use a dummy.
    IMP originalImplementation = method_getImplementation(originalMethod ?: objectMethod);
    class_replaceMethod(klass, @selector(forwardInvocation:), originalImplementation, "v@:@");

    DLFrame_AspectLog(@"DLFrame_Aspects: %@ has been restored.", NSStringFromClass(klass));
}

static void DLFrame_Aspect_hookedGetClass(Class class, Class statedClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
	Method method = class_getInstanceMethod(class, @selector(class));
	IMP newIMP = imp_implementationWithBlock(^(id self) {
		return statedClass;
	});
	class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Swizzle Class In Place

static void _DLFrame_Aspect_modifySwizzledClasses(void (^block)(NSMutableSet *swizzledClasses)) {
    static NSMutableSet *swizzledClasses;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClasses = [NSMutableSet new];
    });
    @synchronized(swizzledClasses) {
        block(swizzledClasses);
    }
}

static Class DLFrame_Aspect_swizzleClassInPlace(Class klass) {
    NSCParameterAssert(klass);
    NSString *className = NSStringFromClass(klass);

    _DLFrame_Aspect_modifySwizzledClasses(^(NSMutableSet *swizzledClasses) {
        if (![swizzledClasses containsObject:className]) {
            DLFrame_Aspect_swizzleForwardInvocation(klass);
            [swizzledClasses addObject:className];
        }
    });
    return klass;
}

static void DLFrame_Aspect_undoSwizzleClassInPlace(Class klass) {
    NSCParameterAssert(klass);
    NSString *className = NSStringFromClass(klass);

    _DLFrame_Aspect_modifySwizzledClasses(^(NSMutableSet *swizzledClasses) {
        if ([swizzledClasses containsObject:className]) {
            DLFrame_Aspect_undoSwizzleForwardInvocation(klass);
            [swizzledClasses removeObject:className];
        }
    });
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DLFrame_Aspect Invoke Point

// This is a macro so we get a cleaner stack trace.
#define DLFrame_Aspect_invoke(DLFrame_Aspects, info) \
for (DLFrame_AspectIdentifier *DLFrame_Aspect in DLFrame_Aspects) {\
    [DLFrame_Aspect invokeWithInfo:info];\
    if (DLFrame_Aspect.options & DLFrame_AspectOptionAutomaticRemoval) { \
        DLFrame_AspectsToRemove = [DLFrame_AspectsToRemove?:@[] arrayByAddingObject:DLFrame_Aspect]; \
    } \
}

// This is the swizzled forwardInvocation: method.
static void __DLFrame_AspectS_ARE_BEING_CALLED__(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation) {
    NSCParameterAssert(self);
    NSCParameterAssert(invocation);
    SEL originalSelector = invocation.selector;
	SEL aliasSelector = DLFrame_Aspect_aliasForSelector(invocation.selector);
    invocation.selector = aliasSelector;
    DLFrame_AspectsContainer *objectContainer = objc_getAssociatedObject(self, aliasSelector);
    DLFrame_AspectsContainer *classContainer = DLFrame_Aspect_getContainerForClass(object_getClass(self), aliasSelector);
    DLFrame_AspectInfo *info = [[DLFrame_AspectInfo alloc] initWithInstance:self invocation:invocation];
    NSArray *DLFrame_AspectsToRemove = nil;

    // Before hooks.
    DLFrame_Aspect_invoke(classContainer.beforeDLFrame_Aspects, info);
    DLFrame_Aspect_invoke(objectContainer.beforeDLFrame_Aspects, info);

    // Instead hooks.
    BOOL respondsToAlias = YES;
    if (objectContainer.insteadDLFrame_Aspects.count || classContainer.insteadDLFrame_Aspects.count) {
        DLFrame_Aspect_invoke(classContainer.insteadDLFrame_Aspects, info);
        DLFrame_Aspect_invoke(objectContainer.insteadDLFrame_Aspects, info);
    }else {
        Class klass = object_getClass(invocation.target);
        do {
            if ((respondsToAlias = [klass instancesRespondToSelector:aliasSelector])) {
                [invocation invoke];
                break;
            }
        }while (!respondsToAlias && (klass = class_getSuperclass(klass)));
    }

    // After hooks.
    DLFrame_Aspect_invoke(classContainer.afterDLFrame_Aspects, info);
    DLFrame_Aspect_invoke(objectContainer.afterDLFrame_Aspects, info);

    // If no hooks are installed, call original implementation (usually to throw an exception)
    if (!respondsToAlias) {
        invocation.selector = originalSelector;
        SEL originalForwardInvocationSEL = NSSelectorFromString(DLFrame_AspectsForwardInvocationSelectorName);
        if ([self respondsToSelector:originalForwardInvocationSEL]) {
            ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(self, originalForwardInvocationSEL, invocation);
        }else {
            [self doesNotRecognizeSelector:invocation.selector];
        }
    }

    // Remove any hooks that are queued for deregistration.
    [DLFrame_AspectsToRemove makeObjectsPerformSelector:@selector(remove)];
}
#undef DLFrame_Aspect_invoke

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DLFrame_Aspect Container Management

// Loads or creates the DLFrame_Aspect container.
static DLFrame_AspectsContainer *DLFrame_Aspect_getContainerForObject(NSObject *self, SEL selector) {
    NSCParameterAssert(self);
    SEL aliasSelector = DLFrame_Aspect_aliasForSelector(selector);
    DLFrame_AspectsContainer *DLFrame_AspectContainer = objc_getAssociatedObject(self, aliasSelector);
    if (!DLFrame_AspectContainer) {
        DLFrame_AspectContainer = [DLFrame_AspectsContainer new];
        objc_setAssociatedObject(self, aliasSelector, DLFrame_AspectContainer, OBJC_ASSOCIATION_RETAIN);
    }
    return DLFrame_AspectContainer;
}

static DLFrame_AspectsContainer *DLFrame_Aspect_getContainerForClass(Class klass, SEL selector) {
    NSCParameterAssert(klass);
    DLFrame_AspectsContainer *classContainer = nil;
    do {
        classContainer = objc_getAssociatedObject(klass, selector);
        if (classContainer.hasDLFrame_Aspects) break;
    }while ((klass = class_getSuperclass(klass)));

    return classContainer;
}

static void DLFrame_Aspect_destroyContainerForObject(id<NSObject> self, SEL selector) {
    NSCParameterAssert(self);
    SEL aliasSelector = DLFrame_Aspect_aliasForSelector(selector);
    objc_setAssociatedObject(self, aliasSelector, nil, OBJC_ASSOCIATION_RETAIN);
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Selector Blacklist Checking

static NSMutableDictionary *DLFrame_Aspect_getSwizzledClassesDict() {
    static NSMutableDictionary *swizzledClassesDict;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClassesDict = [NSMutableDictionary new];
    });
    return swizzledClassesDict;
}

static BOOL DLFrame_Aspect_isSelectorAllowedAndTrack(NSObject *self, SEL selector, DLFrame_AspectOptions options, NSError **error) {
    static NSSet *disallowedSelectorList;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        disallowedSelectorList = [NSSet setWithObjects:@"retain", @"release", @"autorelease", @"forwardInvocation:", nil];
    });

    // Check against the blacklist.
    NSString *selectorName = NSStringFromSelector(selector);
    if ([disallowedSelectorList containsObject:selectorName]) {
        NSString *errorDescription = [NSString stringWithFormat:@"Selector %@ is blacklisted.", selectorName];
        DLFrame_AspectError(DLFrame_AspectErrorSelectorBlacklisted, errorDescription);
        return NO;
    }

    // Additional checks.
    DLFrame_AspectOptions position = options&DLFrame_AspectPositionFilter;
    if ([selectorName isEqualToString:@"dealloc"] && position != DLFrame_AspectPositionBefore) {
        NSString *errorDesc = @"DLFrame_AspectPositionBefore is the only valid position when hooking dealloc.";
        DLFrame_AspectError(DLFrame_AspectErrorSelectorDeallocPosition, errorDesc);
        return NO;
    }

    if (![self respondsToSelector:selector] && ![self.class instancesRespondToSelector:selector]) {
        NSString *errorDesc = [NSString stringWithFormat:@"Unable to find selector -[%@ %@].", NSStringFromClass(self.class), selectorName];
        DLFrame_AspectError(DLFrame_AspectErrorDoesNotRespondToSelector, errorDesc);
        return NO;
    }

    // Search for the current class and the class hierarchy IF we are modifying a class object
    if (class_isMetaClass(object_getClass(self))) {
        Class klass = [self class];
        NSMutableDictionary *swizzledClassesDict = DLFrame_Aspect_getSwizzledClassesDict();
        Class currentClass = [self class];
        do {
            DLFrame_AspectTracker *tracker = swizzledClassesDict[currentClass];
            if ([tracker.selectorNames containsObject:selectorName]) {

                // Find the topmost class for the log.
                if (tracker.parentEntry) {
                    DLFrame_AspectTracker *topmostEntry = tracker.parentEntry;
                    while (topmostEntry.parentEntry) {
                        topmostEntry = topmostEntry.parentEntry;
                    }
                    NSString *errorDescription = [NSString stringWithFormat:@"Error: %@ already hooked in %@. A method can only be hooked once per class hierarchy.", selectorName, NSStringFromClass(topmostEntry.trackedClass)];
                    DLFrame_AspectError(DLFrame_AspectErrorSelectorAlreadyHookedInClassHierarchy, errorDescription);
                    return NO;
                }else if (klass == currentClass) {
                    // Already modified and topmost!
                    return YES;
                }
            }
        }while ((currentClass = class_getSuperclass(currentClass)));

        // Add the selector as being modified.
        currentClass = klass;
        DLFrame_AspectTracker *parentTracker = nil;
        do {
            DLFrame_AspectTracker *tracker = swizzledClassesDict[currentClass];
            if (!tracker) {
                tracker = [[DLFrame_AspectTracker alloc] initWithTrackedClass:currentClass parent:parentTracker];
                swizzledClassesDict[(id<NSCopying>)currentClass] = tracker;
            }
            [tracker.selectorNames addObject:selectorName];
            // All superclasses get marked as having a subclass that is modified.
            parentTracker = tracker;
        }while ((currentClass = class_getSuperclass(currentClass)));
    }

    return YES;
}

static void DLFrame_Aspect_deregisterTrackedSelector(id self, SEL selector) {
    if (!class_isMetaClass(object_getClass(self))) return;

    NSMutableDictionary *swizzledClassesDict = DLFrame_Aspect_getSwizzledClassesDict();
    NSString *selectorName = NSStringFromSelector(selector);
    Class currentClass = [self class];
    do {
        DLFrame_AspectTracker *tracker = swizzledClassesDict[currentClass];
        if (tracker) {
            [tracker.selectorNames removeObject:selectorName];
            if (tracker.selectorNames.count == 0) {
                [swizzledClassesDict removeObjectForKey:tracker];
            }
        }
    }while ((currentClass = class_getSuperclass(currentClass)));
}

@end

@implementation DLFrame_AspectTracker

- (id)initWithTrackedClass:(Class)trackedClass parent:(DLFrame_AspectTracker *)parent {
    if (self = [super init]) {
        _trackedClass = trackedClass;
        _parentEntry = parent;
        _selectorNames = [NSMutableSet new];
    }
    return self;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@, trackedClass: %@, selectorNames:%@, parent:%p>", self.class, self, NSStringFromClass(self.trackedClass), self.selectorNames, self.parentEntry];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInvocation (DLFrame_Aspects)

@implementation NSInvocation (DLFrame_Aspects)

// Thanks to the ReactiveCocoa team for providing a generic solution for this.
- (id)DLFrame_Aspect_argumentAtIndex:(NSUInteger)index {
	const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
	// Skip const type qualifier.
	if (argType[0] == _C_CONST) argType++;

#define WRAP_AND_RETURN(type) do { type val = 0; [self getArgument:&val atIndex:(NSInteger)index]; return @(val); } while (0)
	if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
		__autoreleasing id returnObj;
		[self getArgument:&returnObj atIndex:(NSInteger)index];
		return returnObj;
	} else if (strcmp(argType, @encode(SEL)) == 0) {
        SEL selector = 0;
        [self getArgument:&selector atIndex:(NSInteger)index];
        return NSStringFromSelector(selector);
    } else if (strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing Class theClass = Nil;
        [self getArgument:&theClass atIndex:(NSInteger)index];
        return theClass;
        // Using this list will box the number with the appropriate constructor, instead of the generic NSValue.
	} else if (strcmp(argType, @encode(char)) == 0) {
		WRAP_AND_RETURN(char);
	} else if (strcmp(argType, @encode(int)) == 0) {
		WRAP_AND_RETURN(int);
	} else if (strcmp(argType, @encode(short)) == 0) {
		WRAP_AND_RETURN(short);
	} else if (strcmp(argType, @encode(long)) == 0) {
		WRAP_AND_RETURN(long);
	} else if (strcmp(argType, @encode(long long)) == 0) {
		WRAP_AND_RETURN(long long);
	} else if (strcmp(argType, @encode(unsigned char)) == 0) {
		WRAP_AND_RETURN(unsigned char);
	} else if (strcmp(argType, @encode(unsigned int)) == 0) {
		WRAP_AND_RETURN(unsigned int);
	} else if (strcmp(argType, @encode(unsigned short)) == 0) {
		WRAP_AND_RETURN(unsigned short);
	} else if (strcmp(argType, @encode(unsigned long)) == 0) {
		WRAP_AND_RETURN(unsigned long);
	} else if (strcmp(argType, @encode(unsigned long long)) == 0) {
		WRAP_AND_RETURN(unsigned long long);
	} else if (strcmp(argType, @encode(float)) == 0) {
		WRAP_AND_RETURN(float);
	} else if (strcmp(argType, @encode(double)) == 0) {
		WRAP_AND_RETURN(double);
	} else if (strcmp(argType, @encode(BOOL)) == 0) {
		WRAP_AND_RETURN(BOOL);
	} else if (strcmp(argType, @encode(bool)) == 0) {
		WRAP_AND_RETURN(BOOL);
	} else if (strcmp(argType, @encode(char *)) == 0) {
		WRAP_AND_RETURN(const char *);
	} else if (strcmp(argType, @encode(void (^)(void))) == 0) {
		__unsafe_unretained id block = nil;
		[self getArgument:&block atIndex:(NSInteger)index];
		return [block copy];
	} else {
		NSUInteger valueSize = 0;
		NSGetSizeAndAlignment(argType, &valueSize, NULL);

		unsigned char valueBytes[valueSize];
		[self getArgument:valueBytes atIndex:(NSInteger)index];

		return [NSValue valueWithBytes:valueBytes objCType:argType];
	}
	return nil;
#undef WRAP_AND_RETURN
}

- (NSArray *)DLFrame_Aspects_arguments {
	NSMutableArray *argumentsArray = [NSMutableArray array];
	for (NSUInteger idx = 2; idx < self.methodSignature.numberOfArguments; idx++) {
		[argumentsArray addObject:[self DLFrame_Aspect_argumentAtIndex:idx] ?: NSNull.null];
	}
	return [argumentsArray copy];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DLFrame_AspectIdentifier

@implementation DLFrame_AspectIdentifier

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(DLFrame_AspectOptions)options block:(id)block error:(NSError **)error {
    NSCParameterAssert(block);
    NSCParameterAssert(selector);
    NSMethodSignature *blockSignature = DLFrame_Aspect_blockMethodSignature(block, error); // TODO: check signature compatibility, etc.
    if (!DLFrame_Aspect_isCompatibleBlockSignature(blockSignature, object, selector, error)) {
        return nil;
    }

    DLFrame_AspectIdentifier *identifier = nil;
    if (blockSignature) {
        identifier = [DLFrame_AspectIdentifier new];
        identifier.selector = selector;
        identifier.block = block;
        identifier.blockSignature = blockSignature;
        identifier.options = options;
        identifier.object = object; // weak
    }
    return identifier;
}

- (BOOL)invokeWithInfo:(id<DLFrame_AspectInfo>)info {
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    NSInvocation *originalInvocation = info.originalInvocation;
    NSUInteger numberOfArguments = self.blockSignature.numberOfArguments;

    // Be extra paranoid. We already check that on hook registration.
    if (numberOfArguments > originalInvocation.methodSignature.numberOfArguments) {
        DLFrame_AspectLogError(@"Block has too many arguments. Not calling %@", info);
        return NO;
    }

    // The `self` of the block will be the DLFrame_AspectInfo. Optional.
    if (numberOfArguments > 1) {
        [blockInvocation setArgument:&info atIndex:1];
    }
    
	void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
		NSUInteger argSize;
		NSGetSizeAndAlignment(type, &argSize, NULL);
        
		if (!(argBuf = reallocf(argBuf, argSize))) {
            DLFrame_AspectLogError(@"Failed to allocate memory for block invocation.");
			return NO;
		}
        
		[originalInvocation getArgument:argBuf atIndex:idx];
		[blockInvocation setArgument:argBuf atIndex:idx];
    }
    
    [blockInvocation invokeWithTarget:self.block];
    
    if (argBuf != NULL) {
        free(argBuf);
    }
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, SEL:%@ object:%@ options:%tu block:%@ (#%tu args)>", self.class, self, NSStringFromSelector(self.selector), self.object, self.options, self.block, self.blockSignature.numberOfArguments];
}

- (BOOL)remove {
    return DLFrame_Aspect_remove(self, NULL);
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DLFrame_AspectsContainer

@implementation DLFrame_AspectsContainer

- (BOOL)hasDLFrame_Aspects {
    return self.beforeDLFrame_Aspects.count > 0 || self.insteadDLFrame_Aspects.count > 0 || self.afterDLFrame_Aspects.count > 0;
}

- (void)addDLFrame_Aspect:(DLFrame_AspectIdentifier *)DLFrame_Aspect withOptions:(DLFrame_AspectOptions)options {
    NSParameterAssert(DLFrame_Aspect);
    NSUInteger position = options&DLFrame_AspectPositionFilter;
    switch (position) {
        case DLFrame_AspectPositionBefore:  self.beforeDLFrame_Aspects  = [(self.beforeDLFrame_Aspects ?:@[]) arrayByAddingObject:DLFrame_Aspect]; break;
        case DLFrame_AspectPositionInstead: self.insteadDLFrame_Aspects = [(self.insteadDLFrame_Aspects?:@[]) arrayByAddingObject:DLFrame_Aspect]; break;
        case DLFrame_AspectPositionAfter:   self.afterDLFrame_Aspects   = [(self.afterDLFrame_Aspects  ?:@[]) arrayByAddingObject:DLFrame_Aspect]; break;
    }
}

- (BOOL)removeDLFrame_Aspect:(id)DLFrame_Aspect {
    for (NSString *DLFrame_AspectArrayName in @[NSStringFromSelector(@selector(beforeDLFrame_Aspects)),
                                        NSStringFromSelector(@selector(insteadDLFrame_Aspects)),
                                        NSStringFromSelector(@selector(afterDLFrame_Aspects))]) {
        NSArray *array = [self valueForKey:DLFrame_AspectArrayName];
        NSUInteger index = [array indexOfObjectIdenticalTo:DLFrame_Aspect];
        if (array && index != NSNotFound) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];
            [newArray removeObjectAtIndex:index];
            [self setValue:newArray forKey:DLFrame_AspectArrayName];
            return YES;
        }
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, before:%@, instead:%@, after:%@>", self.class, self, self.beforeDLFrame_Aspects, self.insteadDLFrame_Aspects, self.afterDLFrame_Aspects];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DLFrame_AspectInfo

@implementation DLFrame_AspectInfo

@synthesize arguments = _arguments;

- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation {
    NSCParameterAssert(instance);
    NSCParameterAssert(invocation);
    if (self = [super init]) {
        _instance = instance;
        _originalInvocation = invocation;
    }
    return self;
}

- (NSArray *)arguments {
    // Lazily evaluate arguments, boxing is expensive.
    if (!_arguments) {
        _arguments = self.originalInvocation.DLFrame_Aspects_arguments;
    }
    return _arguments;
}

@end
