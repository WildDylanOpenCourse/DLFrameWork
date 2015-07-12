//
//  DLFrame_Runtime.h
//  DLFrameWork
//
//  Created by XueYulun on 15/7/3.
//

#import <objc/runtime.h>

typedef void (*DLFrame_failedMethodCallback)(Class, Method);

///----------------------------------
///  @name 注入方式
///----------------------------------

typedef NS_OPTIONS(NSUInteger, DLFrame_methodInjectionBehavior) {

    DLFrame_methodInjectionReplace                  = 0x00,
    DLFrame_methodInjectionFailOnExisting           = 0x01,
    DLFrame_methodInjectionFailOnSuperclassExisting = 0x02,
    DLFrame_methodInjectionFailOnAnyExisting        = 0x03,
    DLFrame_methodInjectionIgnoreLoad = 1U << 2,
    DLFrame_methodInjectionIgnoreInitialize = 1U << 3
};

static const DLFrame_methodInjectionBehavior DLFrame_methodInjectionOverwriteBehaviorMask = 0x3;

///----------------------------------
///  @name 属性描述
///----------------------------------

typedef enum {
    
    DLFrame_propertyMemoryManagementPolicyAssign = 0,
    DLFrame_propertyMemoryManagementPolicyRetain,
    DLFrame_propertyMemoryManagementPolicyCopy
} DLFrame_propertyMemoryManagementPolicy;

///----------------------------------
///  @name 属性的属性
///----------------------------------

typedef struct {
    BOOL readonly;
    BOOL nonatomic;
    BOOL weak;
    BOOL canBeCollected;
    BOOL dynamic;
    DLFrame_propertyMemoryManagementPolicy memoryManagementPolicy;
    
    // - 只读 ?
    SEL getter;
    SEL setter;
    
    const char *ivar;
    Class objectClass;
    char type[];
} DLFrame_propertyAttributes;

///----------------------------------
///  @name 增加方法
///----------------------------------

unsigned DLFrame_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, DLFrame_failedMethodCallback failedToAddCallback);
BOOL DLFrame_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, DLFrame_failedMethodCallback failedToAddCallback);

///----------------------------------
///  @name 类操作
///----------------------------------

Class DLFrame_classBeforeSuperclass (Class receiver, Class superclass);
BOOL DLFrame_classIsKindOfClass (Class receiver, Class aClass);
Class *DLFrame_copyClassList (unsigned *count);
Class *DLFrame_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count);

///----------------------------------
///  @name 类属性, 子类
///----------------------------------

DLFrame_propertyAttributes *DLFrame_copyPropertyAttributes (objc_property_t property);
Class *DLFrame_copySubclassList (Class aClass, unsigned *subclassCount);

///----------------------------------
///  @name 当前方法
///----------------------------------

Method DLFrame_getImmediateInstanceMethod (Class aClass, SEL aSelector);

///----------------------------------
///  @name 扩展宏
///----------------------------------

#define DLFrame_getIvar(OBJ, IVAR, TYPE) \
((TYPE (*)(id, Ivar)object_getIvar)((OBJ), (IVAR)))

#define DLFrame_getIvarByName(OBJ, NAME, TYPE) \
DLFrame_getIvar((OBJ), class_getInstanceVariable(object_getClass((OBJ)), (NAME)), TYPE)

BOOL DLFrame_getPropertyAccessorsForClass (objc_property_t property, Class aClass, Method *getter, Method *setter);

NSMethodSignature *DLFrame_globalMethodSignatureForSelector (SEL aSelector);

///----------------------------------
///  @name 方法操作
///----------------------------------

unsigned DLFrame_injectMethods (Class aClass, Method *methods, unsigned count, DLFrame_methodInjectionBehavior behavior, DLFrame_failedMethodCallback failedToAddCallback);

BOOL DLFrame_injectMethodsFromClass (Class srcClass, Class dstClass, DLFrame_methodInjectionBehavior behavior, DLFrame_failedMethodCallback failedToAddCallback);

///----------------------------------
///  @name 协议
///----------------------------------

BOOL DLFrame_loadSpecialProtocol (Protocol *protocol, void (^injectionBehavior)(Class destinationClass));

void DLFrame_specialProtocolReadyForInjection (Protocol *protocol);

NSString *DLFrame_stringFromTypedBytes (const void *bytes, const char *encoding);

///----------------------------------
///  @name 方法删除, 替换
///----------------------------------

void DLFrame_removeMethod (Class aClass, SEL methodName);

void DLFrame_replaceMethods (Class aClass, Method *methods, unsigned count);

void DLFrame_replaceMethodsFromClass (Class srcClass, Class dstClass);

