#import "DLModelClassProperty.h"

@implementation DLModelClassProperty

-(NSString*)description
{
    //build the properties string for the current class property
    NSMutableArray* properties = [NSMutableArray arrayWithCapacity:8];
    
    if (self.isIndex) [properties addObject:@"Index"];
    if (self.isOptional) [properties addObject:@"Optional"];
    if (self.isMutable) [properties addObject:@"Mutable"];
    if (self.convertsOnDemand) [properties addObject:@"ConvertOnDemand"];
    if (self.isStandardJSONType) [properties addObject:@"Standard JSON type"];
    if (self.customSetter) [properties addObject:[NSString stringWithFormat: @"Setter = %@", NSStringFromSelector(self.customSetter)]];
    if (self.customGetter) [properties addObject:[NSString stringWithFormat: @"Getter = %@", NSStringFromSelector(self.customGetter)]];
    
    NSString* propertiesString = @"";
    if (properties.count>0) {
        propertiesString = [NSString stringWithFormat:@"(%@)", [properties componentsJoinedByString:@", "]];
    }
    
    //return the name, type and additional properties
    return [NSString stringWithFormat:@"@property %@%@ %@ %@",
            self.type?[NSString stringWithFormat:@"%@*",self.type]:(self.structName?self.structName:@"primitive"),
            self.protocol?[NSString stringWithFormat:@"<%@>", self.protocol]:@"",
            self.name,
            propertiesString
            ];
}

@end
