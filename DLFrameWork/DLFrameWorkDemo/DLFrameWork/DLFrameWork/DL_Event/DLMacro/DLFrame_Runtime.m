#import "DLFrame_Runtime.h"
#import <ctype.h>
#import <libkern/OSAtomic.h>
#import <objc/message.h>
#import <pthread.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

typedef NSMethodSignature *(*methodSignatureForSelectorIMP)(id, SEL, SEL);
typedef void (^DLFrame_specialProtocolInjectionBlock)(Class);

typedef struct {
    SEL name;
    const char *types;
} DLFrame_methodDescription;

typedef struct {
    __unsafe_unretained Protocol *protocol;
    void *injectionBlock;
    BOOL ready;
} EXTSpecialProtocol;

static EXTSpecialProtocol * restrict specialProtocols = NULL;

static size_t specialProtocolCount = 0;

static size_t specialProtocolCapacity = 0;

static size_t specialProtocolsReady = 0;

static pthread_mutex_t specialProtocolsLock = PTHREAD_MUTEX_INITIALIZER;

static void DLFrame_injectSpecialProtocols (void) {

    qsort_b(specialProtocols, specialProtocolCount, sizeof(EXTSpecialProtocol), ^(const void *a, const void *b){
        if (a == b)
            return 0;
        
        const EXTSpecialProtocol *protoA = a;
        const EXTSpecialProtocol *protoB = b;
        
        int (^protocolInjectionPriority)(const EXTSpecialProtocol *) = ^(const EXTSpecialProtocol *specialProtocol){
            int runningTotal = 0;
            
            for (size_t i = 0;i < specialProtocolCount;++i) {
                if (specialProtocol == specialProtocols + i)
                    continue;
                
                if (protocol_conformsToProtocol(specialProtocol->protocol, specialProtocols[i].protocol))
                    runningTotal++;
            }
            
            return runningTotal;
        };
        
        return protocolInjectionPriority(protoB) - protocolInjectionPriority(protoA);
    });
    
    unsigned classCount = objc_getClassList(NULL, 0);
    if (!classCount) {
        fprintf(stderr, "ERROR: No classes registered with the runtime\n");
        return;
    }
    
    Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
    if (!allClasses) {
        fprintf(stderr, "ERROR: Could not allocate space for %u classes\n", classCount);
        return;
    }
    
    classCount = objc_getClassList(allClasses, classCount);
    
    @autoreleasepool {
        for (size_t i = 0;i < specialProtocolCount;++i) {
            Protocol *protocol = specialProtocols[i].protocol;
            
            DLFrame_specialProtocolInjectionBlock injectionBlock = (__bridge_transfer id)specialProtocols[i].injectionBlock;
            specialProtocols[i].injectionBlock = NULL;
            
            for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
                Class class = allClasses[classIndex];
                
                if (!class_conformsToProtocol(class, protocol))
                    continue;
                
                injectionBlock(class);
            }
        }
    }
    
    free(allClasses);
    
    free(specialProtocols); specialProtocols = NULL;
    specialProtocolCount = 0;
    specialProtocolCapacity = 0;
    specialProtocolsReady = 0;
}

unsigned DLFrame_injectMethods (
                            Class aClass,
                            Method *methods,
                            unsigned count,
                            DLFrame_methodInjectionBehavior behavior,
                            DLFrame_failedMethodCallback failedToAddCallback
                            ) {
    unsigned successes = 0;
    
    @autoreleasepool {
        BOOL isMeta = class_isMetaClass(aClass);
        
        if (!isMeta) {
            behavior &= ~(DLFrame_methodInjectionIgnoreLoad | DLFrame_methodInjectionIgnoreInitialize);
        }
        
        for (unsigned methodIndex = 0;methodIndex < count;++methodIndex) {
            Method method = methods[methodIndex];
            SEL methodName = method_getName(method);
            
            if (behavior & DLFrame_methodInjectionIgnoreLoad) {
                if (methodName == @selector(load)) {
                    ++successes;
                    continue;
                }
            }
            
            if (behavior & DLFrame_methodInjectionIgnoreInitialize) {
                if (methodName == @selector(initialize)) {
                    ++successes;
                    continue;
                }
            }
            
            BOOL success = YES;
            IMP impl = method_getImplementation(method);
            const char *type = method_getTypeEncoding(method);
            
            switch (behavior & DLFrame_methodInjectionOverwriteBehaviorMask) {
                case DLFrame_methodInjectionFailOnExisting:
                    success = class_addMethod(aClass, methodName, impl, type);
                    break;
                    
                case DLFrame_methodInjectionFailOnAnyExisting:
                    if (class_getInstanceMethod(aClass, methodName)) {
                        success = NO;
                        break;
                    }
                    
                case DLFrame_methodInjectionReplace:
                    class_replaceMethod(aClass, methodName, impl, type);
                    break;
                    
                case DLFrame_methodInjectionFailOnSuperclassExisting:
                {
                    Class superclass = class_getSuperclass(aClass);
                    if (superclass && class_getInstanceMethod(superclass, methodName))
                        success = NO;
                    else
                        class_replaceMethod(aClass, methodName, impl, type);
                }
                    
                    break;
                    
                default:
                    fprintf(stderr, "ERROR: Unrecognized method injection behavior: %i\n", (int)(behavior & DLFrame_methodInjectionOverwriteBehaviorMask));
            }
            
            if (success)
                ++successes;
            else
                failedToAddCallback(aClass, method);
        }
    }
    
    return successes;
}

BOOL DLFrame_injectMethodsFromClass (
                                 Class srcClass,
                                 Class dstClass,
                                 DLFrame_methodInjectionBehavior behavior,
                                 DLFrame_failedMethodCallback failedToAddCallback)
{
    unsigned count, addedCount;
    BOOL success = YES;
    
    count = 0;
    Method *instanceMethods = class_copyMethodList(srcClass, &count);
    
    addedCount = DLFrame_injectMethods(
                                   dstClass,
                                   instanceMethods,
                                   count,
                                   behavior,
                                   failedToAddCallback
                                   );
    
    free(instanceMethods);
    if (addedCount < count)
        success = NO;
    
    count = 0;
    Method *classMethods = class_copyMethodList(object_getClass(srcClass), &count);
    
    // ignore +load
    behavior |= DLFrame_methodInjectionIgnoreLoad;
    addedCount = DLFrame_injectMethods(
                                   object_getClass(dstClass),
                                   classMethods,
                                   count,
                                   behavior,
                                   failedToAddCallback
                                   );
    
    free(classMethods);
    if (addedCount < count)
        success = NO;
    
    return success;
}

Class DLFrame_classBeforeSuperclass (Class receiver, Class superclass) {
    Class previousClass = nil;
    
    while (![receiver isEqual:superclass]) {
        previousClass = receiver;
        receiver = class_getSuperclass(receiver);
    }
    
    return previousClass;
}

Class *DLFrame_copyClassList (unsigned *count) {
    int classCount = objc_getClassList(NULL, 0);
    if (!classCount) {
        if (count)
            *count = 0;
        
        return NULL;
    }
    
    Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
    if (!allClasses) {
        fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
        if (count)
            *count = 0;
        
        return NULL;
    }
    
    classCount = objc_getClassList(allClasses, classCount);
    allClasses[classCount] = NULL;
    
    @autoreleasepool {
        for (int i = 0;i < classCount;) {
            Class class = allClasses[i];
            BOOL keep = YES;
            
            if (keep)
                keep &= class_respondsToSelector(class, @selector(methodSignatureForSelector:));
            
            if (keep) {
                if (class_respondsToSelector(class, @selector(isProxy)))
                    keep &= ![class isProxy];
            }
            
            if (!keep) {
                if (--classCount > i) {
                    memmove(allClasses + i, allClasses + i + 1, (classCount - i) * sizeof(*allClasses));
                }
                
                continue;
            }
            
            ++i;
        }
    }
    
    if (count)
        *count = (unsigned)classCount;
    
    return allClasses;
}

unsigned DLFrame_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, DLFrame_failedMethodCallback failedToAddCallback) {
    DLFrame_methodInjectionBehavior behavior = DLFrame_methodInjectionFailOnExisting;
    if (checkSuperclasses)
        behavior |= DLFrame_methodInjectionFailOnSuperclassExisting;
    
    return DLFrame_injectMethods(
                             aClass,
                             methods,
                             count,
                             behavior,
                             failedToAddCallback
                             );
}

BOOL DLFrame_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, DLFrame_failedMethodCallback failedToAddCallback) {
    DLFrame_methodInjectionBehavior behavior = DLFrame_methodInjectionFailOnExisting;
    if (checkSuperclasses)
        behavior |= DLFrame_methodInjectionFailOnSuperclassExisting;
    
    return DLFrame_injectMethodsFromClass(srcClass, dstClass, behavior, failedToAddCallback);
}

BOOL DLFrame_classIsKindOfClass (Class receiver, Class aClass) {
    while (receiver) {
        if (receiver == aClass)
            return YES;
        
        receiver = class_getSuperclass(receiver);
    }
    
    return NO;
}

Class *DLFrame_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count) {
    Class *allClasses;
    
    @autoreleasepool {
        unsigned classCount = 0;
        allClasses = DLFrame_copyClassList(&classCount);
        
        if (!allClasses)
            return NULL;
        
        unsigned returnIndex = 0;
        
        for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
            Class cls = allClasses[classIndex];
            if (class_conformsToProtocol(cls, protocol))
                allClasses[returnIndex++] = cls;
        }
        
        allClasses[returnIndex] = NULL;
        if (count)
            *count = returnIndex;
    }
    
    return allClasses;
}

DLFrame_propertyAttributes *DLFrame_copyPropertyAttributes (objc_property_t property) {
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        fprintf(stderr, "ERROR: Could not get attribute string from property %s\n", property_getName(property));
        return NULL;
    }
    
    if (attrString[0] != 'T') {
        fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
        return NULL;
    }
    
    const char *typeString = attrString + 1;
    const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    if (!next) {
        fprintf(stderr, "ERROR: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    size_t typeLength = next - typeString;
    if (!typeLength) {
        fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    DLFrame_propertyAttributes *attributes = calloc(1, sizeof(DLFrame_propertyAttributes) + typeLength + 1);
    if (!attributes) {
        fprintf(stderr, "ERROR: Could not allocate DLFrame_propertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    strncpy(attributes->type, typeString, typeLength);
    attributes->type[typeLength] = '\0';
    
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        const char *className = typeString + 2;
        next = strchr(className, '"');
        
        if (!next) {
            fprintf(stderr, "ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
            return NULL;
        }
        
        if (className != next) {
            size_t classNameLength = next - className;
            char trimmedName[classNameLength + 1];
            
            strncpy(trimmedName, className, classNameLength);
            trimmedName[classNameLength] = '\0';
            
            attributes->objectClass = objc_getClass(trimmedName);
        }
    }
    
    if (*next != '\0') {
        next = strchr(next, ',');
    }
    
    while (next && *next == ',') {
        char flag = next[1];
        next += 2;
        
        switch (flag) {
            case '\0':
                break;
                
            case 'R':
                attributes->readonly = YES;
                break;
                
            case 'C':
                attributes->memoryManagementPolicy = DLFrame_propertyMemoryManagementPolicyCopy;
                break;
                
            case '&':
                attributes->memoryManagementPolicy = DLFrame_propertyMemoryManagementPolicyRetain;
                break;
                
            case 'N':
                attributes->nonatomic = YES;
                break;
                
            case 'G':
            case 'S':
            {
                const char *nextFlag = strchr(next, ',');
                SEL name = NULL;
                
                if (!nextFlag) {
                    const char *selectorString = next;
                    next = "";
                    
                    name = sel_registerName(selectorString);
                } else {
                    size_t selectorLength = nextFlag - next;
                    if (!selectorLength) {
                        fprintf(stderr, "ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                        goto errorOut;
                    }
                    
                    char selectorString[selectorLength + 1];
                    
                    strncpy(selectorString, next, selectorLength);
                    selectorString[selectorLength] = '\0';
                    
                    name = sel_registerName(selectorString);
                    next = nextFlag;
                }
                
                if (flag == 'G')
                    attributes->getter = name;
                else
                    attributes->setter = name;
            }
                
                break;
                
            case 'D':
                attributes->dynamic = YES;
                attributes->ivar = NULL;
                break;
                
            case 'V':
                if (*next == '\0') {
                    attributes->ivar = NULL;
                } else {
                    attributes->ivar = next;
                    next = "";
                }
                
                break;
                
            case 'W':
                attributes->weak = YES;
                break;
                
            case 'P':
                attributes->canBeCollected = YES;
                break;
                
            case 't':
                fprintf(stderr, "ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                
                while (*next != ',' && *next != '\0')
                    ++next;
                
                break;
                
            default:
                fprintf(stderr, "ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property));
        }
    }
    
    if (next && *next != '\0') {
        fprintf(stderr, "Warning: Unparsed data \"%s\" in attribute string \"%s\" for property %s\n", next, attrString, property_getName(property));
    }
    
    if (!attributes->getter) {
        
        attributes->getter = sel_registerName(property_getName(property));
    }
    
    if (!attributes->setter) {
        const char *propertyName = property_getName(property);
        size_t propertyNameLength = strlen(propertyName);
        
        size_t setterLength = propertyNameLength + 4;
        
        char setterName[setterLength + 1];
        strncpy(setterName, "set", 3);
        strncpy(setterName + 3, propertyName, propertyNameLength);
        
        setterName[3] = (char)toupper(setterName[3]);
        
        setterName[setterLength - 1] = ':';
        setterName[setterLength] = '\0';
        
        attributes->setter = sel_registerName(setterName);
    }
    
    return attributes;
    
errorOut:
    free(attributes);
    return NULL;
}

Class *DLFrame_copySubclassList (Class targetClass, unsigned *subclassCount) {
    unsigned classCount = 0;
    Class *allClasses = DLFrame_copyClassList(&classCount);
    if (!allClasses || !classCount) {
        fprintf(stderr, "ERROR: No classes registered with the runtime, cannot find %s!\n", class_getName(targetClass));
        return NULL;
    }
    
    unsigned returnIndex = 0;
    
    BOOL isMeta = class_isMetaClass(targetClass);
    
    for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
        Class cls = allClasses[classIndex];
        Class superclass = class_getSuperclass(cls);
        
        while (superclass != NULL) {
            if (isMeta) {
                if (object_getClass(superclass) == targetClass)
                    break;
            } else if (superclass == targetClass)
                break;
            
            superclass = class_getSuperclass(superclass);
        }
        
        if (!superclass)
            continue;
        
        if (isMeta)
            cls = object_getClass(cls);
        
        allClasses[returnIndex++] = cls;
    }
    
    allClasses[returnIndex] = NULL;
    if (subclassCount)
        *subclassCount = returnIndex;
    
    return allClasses;
}

Method DLFrame_getImmediateInstanceMethod (Class aClass, SEL aSelector) {
    unsigned methodCount = 0;
    Method *methods = class_copyMethodList(aClass, &methodCount);
    Method foundMethod = NULL;
    
    for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
        if (method_getName(methods[methodIndex]) == aSelector) {
            foundMethod = methods[methodIndex];
            break;
        }
    }
    
    free(methods);
    return foundMethod;
}

BOOL DLFrame_getPropertyAccessorsForClass (objc_property_t property, Class aClass, Method *getter, Method *setter) {
    DLFrame_propertyAttributes *attributes = DLFrame_copyPropertyAttributes(property);
    if (!attributes)
        return NO;
    
    SEL getterName = attributes->getter;
    SEL setterName = attributes->setter;
    
    free(attributes);
    attributes = NULL;
    
    @autoreleasepool {
        Method foundGetter = class_getInstanceMethod(aClass, getterName);
        if (!foundGetter) {
            return NO;
        }
        
        if (getter)
            *getter = foundGetter;
        
        if (setter) {
            Method foundSetter = class_getInstanceMethod(aClass, setterName);
            if (foundSetter)
                *setter = foundSetter;
        }
    }
    
    return YES;
}

NSMethodSignature *DLFrame_globalMethodSignatureForSelector (SEL aSelector) {
    NSCParameterAssert(aSelector != NULL);
    
    static const size_t selectorCacheLength = 1 << 8;
    static const uintptr_t selectorCacheMask = (selectorCacheLength - 1);
    static DLFrame_methodDescription volatile methodDescriptionCache[selectorCacheLength];
    
    static OSSpinLock lock = OS_SPINLOCK_INIT;
    
    uintptr_t hash = (uintptr_t)((void *)aSelector) & selectorCacheMask;
    DLFrame_methodDescription methodDesc;
    
    OSSpinLockLock(&lock);
    methodDesc = methodDescriptionCache[hash];
    OSSpinLockUnlock(&lock);
    
    if (methodDesc.name == aSelector) {
        return [NSMethodSignature signatureWithObjCTypes:methodDesc.types];
    }
    
    methodDesc = (DLFrame_methodDescription){.name = NULL, .types = NULL};
    
    uint classCount = 0;
    Class *classes = DLFrame_copyClassList(&classCount);
    
    if (classes) {
        @autoreleasepool {

            for (uint i = 0;i < classCount;++i) {
                Class cls = classes[i];
                
                Method method = class_getInstanceMethod(cls, aSelector);
                if (!method)
                    method = class_getClassMethod(cls, aSelector);
                
                if (method) {
                    methodDesc = (DLFrame_methodDescription){.name = aSelector, .types = method_getTypeEncoding(method)};
                    break;
                }
            }
        }
        free(classes);
    }
    
    if (!methodDesc.name) {
        uint protocolCount = 0;
        Protocol * __unsafe_unretained *protocols = objc_copyProtocolList(&protocolCount);
        if (protocols) {
            struct objc_method_description objcMethodDesc;
            for (uint i = 0;i < protocolCount;++i) {
                objcMethodDesc = protocol_getMethodDescription(protocols[i], aSelector, NO, YES);
                if (!objcMethodDesc.name)
                    objcMethodDesc = protocol_getMethodDescription(protocols[i], aSelector, NO, NO);
                
                if (objcMethodDesc.name) {
                    methodDesc = (DLFrame_methodDescription){.name = objcMethodDesc.name, .types = objcMethodDesc.types};
                    break;
                }
            }
            free(protocols);
        }
    }
    
    if (methodDesc.name) {

        if (OSSpinLockTry(&lock)) {
            methodDescriptionCache[hash] = methodDesc;
            OSSpinLockUnlock(&lock);
        }

        return [NSMethodSignature signatureWithObjCTypes:methodDesc.types];
    } else {
        return nil;
    }
}

BOOL DLFrame_loadSpecialProtocol (Protocol *protocol, void (^injectionBehavior)(Class destinationClass)) {
    @autoreleasepool {
        NSCParameterAssert(protocol != nil);
        NSCParameterAssert(injectionBehavior != nil);
        
        if (pthread_mutex_lock(&specialProtocolsLock) != 0) {
            fprintf(stderr, "ERROR: Could not synchronize on special protocol data\n");
            return NO;
        }
        
        if (specialProtocolCount == SIZE_MAX) {
            pthread_mutex_unlock(&specialProtocolsLock);
            return NO;
        }
        
        if (specialProtocolCount >= specialProtocolCapacity) {
            size_t newCapacity;
            if (specialProtocolCapacity == 0)

                newCapacity = 1;
            else {

                newCapacity = specialProtocolCapacity << 1;
                
                if (newCapacity < specialProtocolCapacity) {
                    newCapacity = SIZE_MAX;
                    
                    if (newCapacity <= specialProtocolCapacity) {
                        pthread_mutex_unlock(&specialProtocolsLock);
                        return NO;
                    }
                }
            }
            
            void * restrict ptr = realloc(specialProtocols, sizeof(*specialProtocols) * newCapacity);
            if (!ptr) {
                pthread_mutex_unlock(&specialProtocolsLock);
                return NO;
            }
            
            specialProtocols = ptr;
            specialProtocolCapacity = newCapacity;
        }
        
        assert(specialProtocolCount < specialProtocolCapacity);
        
#ifndef __clang_analyzer__
        DLFrame_specialProtocolInjectionBlock copiedBlock = [injectionBehavior copy];
        
        specialProtocols[specialProtocolCount] = (EXTSpecialProtocol){
            .protocol = protocol,
            .injectionBlock = (__bridge_retained void *)copiedBlock,
            .ready = NO
        };
#endif
        
        ++specialProtocolCount;
        pthread_mutex_unlock(&specialProtocolsLock);
    }
    

    return YES;
}

void DLFrame_specialProtocolReadyForInjection (Protocol *protocol) {
    @autoreleasepool {
        NSCParameterAssert(protocol != nil);
        
        if (pthread_mutex_lock(&specialProtocolsLock) != 0) {
            fprintf(stderr, "ERROR: Could not synchronize on special protocol data\n");
            return;
        }
        
        for (size_t i = 0;i < specialProtocolCount;++i) {
            if (specialProtocols[i].protocol == protocol) {
                if (!specialProtocols[i].ready) {
                    specialProtocols[i].ready = YES;
                    
                    assert(specialProtocolsReady < specialProtocolCount);
                    if (++specialProtocolsReady == specialProtocolCount)
                        DLFrame_injectSpecialProtocols();
                }
                
                break;
            }
        }
        
        pthread_mutex_unlock(&specialProtocolsLock);
    }
}

void DLFrame_removeMethod (Class aClass, SEL methodName) {
    Method existingMethod = DLFrame_getImmediateInstanceMethod(aClass, methodName);
    if (!existingMethod) {
        return;
    }
    
    @autoreleasepool {
        Method superclassMethod = NULL;
        Class superclass = class_getSuperclass(aClass);
        if (superclass)
            superclassMethod = class_getInstanceMethod(superclass, methodName);
        
        if (superclassMethod) {
            method_setImplementation(existingMethod, method_getImplementation(superclassMethod));
        } else {

            IMP forward = class_getMethodImplementation(superclass, methodName);
            
            method_setImplementation(existingMethod, forward);
        }
    }
}

void DLFrame_replaceMethods (Class aClass, Method *methods, unsigned count) {
    DLFrame_injectMethods(
                      aClass,
                      methods,
                      count,
                      DLFrame_methodInjectionReplace,
                      NULL
                      );
}

void DLFrame_replaceMethodsFromClass (Class srcClass, Class dstClass) {
    DLFrame_injectMethodsFromClass(srcClass, dstClass, DLFrame_methodInjectionReplace, NULL);
}

NSString *DLFrame_stringFromTypedBytes (const void *bytes, const char *encoding) {
    switch (*encoding) {
        case 'c': return @(*(char *)bytes).description;
        case 'C': return @(*(unsigned char *)bytes).description;
        case 'i': return @(*(int *)bytes).description;
        case 'I': return @(*(unsigned int *)bytes).description;
        case 's': return @(*(short *)bytes).description;
        case 'S': return @(*(unsigned short *)bytes).description;
        case 'l': return @(*(long *)bytes).description;
        case 'L': return @(*(unsigned long *)bytes).description;
        case 'q': return @(*(long long *)bytes).description;
        case 'Q': return @(*(unsigned long long *)bytes).description;
        case 'f': return @(*(float *)bytes).description;
        case 'd': return @(*(double *)bytes).description;
        case 'B': return @(*(_Bool *)bytes).description;
        case 'v': return @"(void)";
        case '*': return [NSString stringWithFormat:@"\"%s\"", bytes];
            
        case '@':
        case '#': {
            id obj = *(__unsafe_unretained id *)bytes;
            if (obj)
                return [obj description];
            else
                return @"(nil)";
        }
            
        case '?':
        case '^': {
            const void *ptr = *(const void **)bytes;
            if (ptr)
                return [NSString stringWithFormat:@"%p", ptr];
            else
                return @"(null)";
        }
            
        default:
            return [[NSValue valueWithBytes:bytes objCType:encoding] description];
    }
}

