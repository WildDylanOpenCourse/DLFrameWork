#import "DLKeyMapper.h"

@interface DLKeyMapper()
@property (nonatomic, strong) NSMutableDictionary *toModelMap;
@property (nonatomic, strong) NSMutableDictionary *toJSONMap;
@end

@implementation DLKeyMapper

-(instancetype)init
{
    self = [super init];
    if (self) {
        //initialization
        self.toModelMap = [NSMutableDictionary dictionary];
        self.toJSONMap  = [NSMutableDictionary dictionary];
    }
    return self;
}

-(instancetype)initWithJSONToModelBlock:(DLModelKeyMapBlock)toModel
                       modelToJSONBlock:(DLModelKeyMapBlock)toJSON
{
    self = [self init];
    
    if (self) {
        __weak DLKeyMapper *myself = self;
        //the json to model convertion block
        _JSONToModelKeyBlock = ^NSString*(NSString* keyName) {

            //try to return cached transformed key
            if (myself.toModelMap[keyName]) return myself.toModelMap[keyName];
            
            //try to convert the key, and store in the cache
            NSString* result = toModel(keyName);
            myself.toModelMap[keyName] = result;
            return result;
        };
        
        _modelToJSONKeyBlock = ^NSString*(NSString* keyName) {
            
            //try to return cached transformed key
            if (myself.toJSONMap[keyName]) return myself.toJSONMap[keyName];
            
            //try to convert the key, and store in the cache
            NSString* result = toJSON(keyName);
            myself.toJSONMap[keyName] = result;
            return result;
            
        };
        
    }
    
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary*)map
{
    self = [super init];
    if (self) {
        //initialize

        NSMutableDictionary* userToModelMap = [NSMutableDictionary dictionaryWithDictionary: map];
        NSMutableDictionary* userToJSONMap  = [NSMutableDictionary dictionaryWithObjects:map.allKeys forKeys:map.allValues];
        
        _JSONToModelKeyBlock = ^NSString*(NSString* keyName) {
            NSString* result = [userToModelMap valueForKeyPath: keyName];
            return result?result:keyName;
        };
        
        _modelToJSONKeyBlock = ^NSString*(NSString* keyName) {
            NSString* result = [userToJSONMap valueForKeyPath: keyName];
            return result?result:keyName;
        };
    }
    
    return self;
}

-(NSString*)convertValue:(NSString*)value isImportingToModel:(BOOL)importing
{
    return !importing?_JSONToModelKeyBlock(value):_modelToJSONKeyBlock(value);
}

+(instancetype)mapperFromUnderscoreCaseToCamelCase
{
    DLModelKeyMapBlock toModel = ^ NSString* (NSString* keyName) {

        //bail early if no transformation required
        if ([keyName rangeOfString:@"_"].location==NSNotFound) return keyName;

        //derive camel case out of underscore case
        NSString* camelCase = [keyName capitalizedString];
        camelCase = [camelCase stringByReplacingOccurrencesOfString:@"_" withString:@""];
        camelCase = [camelCase stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[camelCase substringToIndex:1] lowercaseString] ];
        
        return camelCase;
    };

    DLModelKeyMapBlock toJSON = ^ NSString* (NSString* keyName) {
        
        NSMutableString* result = [NSMutableString stringWithString:keyName];
        NSRange upperCharRange = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];

        //handle upper case chars
        while ( upperCharRange.location!=NSNotFound) {

            NSString* lowerChar = [[result substringWithRange:upperCharRange] lowercaseString];
            [result replaceCharactersInRange:upperCharRange
                                  withString:[NSString stringWithFormat:@"_%@", lowerChar]];
            upperCharRange = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
        }

        //handle numbers
        NSRange digitsRange = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
        while ( digitsRange.location!=NSNotFound) {
            
            NSRange digitsRangeEnd = [result rangeOfString:@"\\D" options:NSRegularExpressionSearch range:NSMakeRange(digitsRange.location, result.length-digitsRange.location)];
            if (digitsRangeEnd.location == NSNotFound) {
                //spands till the end of the key name
                digitsRangeEnd = NSMakeRange(result.length, 1);
            }
            
            NSRange replaceRange = NSMakeRange(digitsRange.location, digitsRangeEnd.location - digitsRange.location);
            NSString* digits = [result substringWithRange:replaceRange];
            
            [result replaceCharactersInRange:replaceRange withString:[NSString stringWithFormat:@"_%@", digits]];
            digitsRange = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:kNilOptions range:NSMakeRange(digitsRangeEnd.location+1, result.length-digitsRangeEnd.location-1)];
        }
        
        return result;
    };

    return [[self alloc] initWithJSONToModelBlock:toModel
                                 modelToJSONBlock:toJSON];
    
}

+(instancetype)mapperFromUpperCaseToLowerCase
{
    DLModelKeyMapBlock toModel = ^ NSString* (NSString* keyName) {
        NSString*lowercaseString = [keyName lowercaseString];
        return lowercaseString;
    };

    DLModelKeyMapBlock toJSON = ^ NSString* (NSString* keyName) {

        NSString *uppercaseString = [keyName uppercaseString];

        return uppercaseString;
    };

    return [[self alloc] initWithJSONToModelBlock:toModel
                                 modelToJSONBlock:toJSON];

}

@end
