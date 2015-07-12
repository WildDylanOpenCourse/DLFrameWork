#import <Foundation/Foundation.h>

enum kCustomizationTypes {
    kNotInspected = 0,
    kCustom,
    kNo
    };

typedef enum kCustomizationTypes PropertySetterType;
typedef enum kCustomizationTypes PropertyGetterType;

@interface DLModelClassProperty : NSObject

@property (copy, nonatomic) NSString* name;
@property (assign, nonatomic) Class type;
@property (strong, nonatomic) NSString* structName;
@property (copy, nonatomic) NSString* protocol;

@property (assign, nonatomic) BOOL isOptional;
@property (assign, nonatomic) BOOL isStandardJSONType;
@property (assign, nonatomic) BOOL isMutable;
@property (assign, nonatomic) BOOL convertsOnDemand;
@property (assign, nonatomic) BOOL isIndex;

@property (assign, nonatomic) PropertyGetterType getterType;
@property (assign, nonatomic) SEL customGetter;
@property (assign, nonatomic) PropertySetterType setterType;
@property (assign, nonatomic) SEL customSetter;

@end
