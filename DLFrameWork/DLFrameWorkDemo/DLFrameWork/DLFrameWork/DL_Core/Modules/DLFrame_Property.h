//
//  DLFrame_Property.h
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name 属性定义
///----------------------------------

#if __has_feature(objc_arc)

#define	prop_readonly( type, name )		property (nonatomic, readonly) type name;
#define	prop_dynamic( type, name )		property (nonatomic, strong) type name;
#define	prop_assign( type, name )		property (nonatomic, assign) type name;
#define	prop_strong( type, name )		property (nonatomic, strong) type name;
#define	prop_weak( type, name )			property (nonatomic, weak) type name;
#define	prop_copy( type, name )			property (nonatomic, copy) type name;
#define	prop_unsafe( type, name )		property (nonatomic, unsafe_unretained) type name;

#else

#define	prop_readonly( type, name )		property (nonatomic, readonly) type name;
#define	prop_dynamic( type, name )		property (nonatomic, retain) type name;
#define	prop_assign( type, name )		property (nonatomic, assign) type name;
#define	prop_strong( type, name )		property (nonatomic, retain) type name;
#define	prop_weak( type, name )			property (nonatomic, assign) type name;
#define	prop_copy( type, name )			property (nonatomic, copy) type name;
#define	prop_unsafe( type, name )		property (nonatomic, assign) type name;

#endif

#define def_prop_readonly( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_assign( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_strong( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_weak( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_unsafe( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_copy( type, name, ... ) \
synthesize name = _##name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_dynamic( type, name, ... ) \
dynamic name; \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_dynamic_copy( type, name, setName, ... ) \
def_prop_custom( type, name, setName, copy ) \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_dynamic_strong( type, name, setName, ... ) \
def_prop_custom( type, name, setName, retain ) \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_dynamic_weak( type, name, setName, ... ) \
def_prop_custom( type, name, setName, assign ) \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_dynamic_pod( type, name, setName, pod_type ... ) \
dynamic name; \
- (type)name { return (type)[[self getAssociatedObjectForKey:#name] pod_type##Value]; } \
- (void)setName:(type)obj { [self assignAssociatedObject:@((pod_type)obj) forKey:#name]; } \
+ (NSString *)property_##name { return macro_string( macro_join(__VA_ARGS__) ); }

#define def_prop_custom( type, name, setName, attr ) \
dynamic name; \
- (type)name { return [self getAssociatedObjectForKey:#name]; } \
- (void)setName:(type)obj { [self attr##AssociatedObject:obj forKey:#name]; }

@interface NSObject(Property)

///----------------------------------
///  @name 属性获取
///----------------------------------

- (id)getAssociatedObjectForKey:(const char *)key;
- (id)copyAssociatedObject:(id)obj forKey:(const char *)key;
- (id)retainAssociatedObject:(id)obj forKey:(const char *)key;
- (id)assignAssociatedObject:(id)obj forKey:(const char *)key;
- (void)removeAssociatedObjectForKey:(const char *)key;
- (void)removeAllAssociatedObjects;

@end
