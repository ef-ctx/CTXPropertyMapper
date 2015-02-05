//
//  CTXPropertyMapper.m
//  CTXFramework
//
//  Created by Mario on 09/12/2014.
//  Copyright (c) 2014 EF. All rights reserved.
//

#import "CTXPropertyMapper.h"
#import "CTXPropertyDescriptor.h"
#import "CTXPropertyMapperErrors.h"
#import "objc/runtime.h"

@interface NSObject (Properties)

+ (NSDictionary *)propertiesDictionaryFromClass:(Class)clazz;
- (id)wrappedValueForKey:(NSString *)key;

@end


@interface CTXPropertyMapperSimpleModelFactory : NSObject<CTXPropertyMapperModelFactoryProtocol>

@end

@interface CTXPropertyMapper()

@property (nonatomic, strong) id<CTXPropertyMapperModelFactoryProtocol> modelFactory;
@property (nonatomic, strong) NSMutableDictionary *cachedPropertiesByClass;
@property (nonatomic, strong) NSMutableDictionary *mappingsByClass;

@end


@implementation CTXPropertyMapper

#pragma mark - Public Methods

- (instancetype)init
{
    if (self = [super init]) {
        _mappingsByClass = [NSMutableDictionary dictionary];
        _cachedPropertiesByClass = [NSMutableDictionary dictionary];
        _modelFactory = [[CTXPropertyMapperSimpleModelFactory alloc] init];
    }
    return self;
}

- (instancetype)initWithModelFactory:(id<CTXPropertyMapperModelFactoryProtocol>)modelFactory
{
    NSParameterAssert(modelFactory);
    
    if (self = [super init]) {
        _mappingsByClass = [NSMutableDictionary dictionary];
        _cachedPropertiesByClass = [NSMutableDictionary dictionary];
        _modelFactory = modelFactory;
    }
    return self;
}

- (BOOL)addMappings:(NSDictionary *)mappings forClass:(Class)clazz
{
    return [self addMappings:mappings forClass:clazz error:nil];
}

- (BOOL)addMappings:(NSDictionary *)mappings forClass:(Class)clazz error:(NSError *__autoreleasing*)error
{
    __block NSError *mappingError;
    
    NSDictionary *properties = [self propertiesForClass:clazz];
    
    [mappings enumerateKeysAndObjectsUsingBlock:^(id key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
        
        if (![key isKindOfClass:[NSString class]] || ![descriptor isKindOfClass:[CTXPropertyDescriptor class]]) {
            mappingError = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
                                               code:CTXPropertyMapperErrorCodeInvalidMapperFormat
                                           userInfo:@{NSLocalizedDescriptionKey:CTXPropertyMapperErrorDescription[CTXPropertyMapperErrorCodeInvalidMapperFormat]}];
            *stop = YES;
        } else if (!properties[descriptor.propertyName]) {
            NSString *author = [NSString stringWithFormat:CTXPropertyMapperErrorDescription[CTXPropertyMapperErrorCodeUnknownProperty],
                                descriptor.propertyName, [clazz description]];
            mappingError = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
                                               code:CTXPropertyMapperErrorCodeUnknownProperty
                                           userInfo:@{NSLocalizedDescriptionKey:author}];
            *stop = YES;
        }
    }];
    
    if (error != NULL) {
        *error = mappingError;
    }
    
    if (!mappingError) {
        self.mappingsByClass[[clazz description]] = mappings;
    }
    
    return !mappingError;
}

- (void)addMappingsFromPropertyMapper:(CTXPropertyMapper *)propertyMapper
{
    [self.mappingsByClass addEntriesFromDictionary:[propertyMapper mappingsByClass]];
}

- (id)createObjectWithClass:(Class)clazz fromDictionary:(NSDictionary *)dictionary
{
    return [self createObjectWithClass:clazz fromDictionary:dictionary errors:nil];
}

- (id)createObjectWithClass:(Class)clazz fromDictionary:(NSDictionary *)dictionary errors:(NSArray *__autoreleasing*)errors
{
    NSDictionary *mappings = self.mappingsByClass[clazz.description];
    NSArray *validationErrors = nil;
    
    if (!mappings) {
        NSString *description = [NSString stringWithFormat:CTXPropertyMapperErrorDescription[CTXPropertyMapperErrorCodeMapperDidNotFound],
                                 [clazz description]];
        
        NSError *error = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
                                             code:CTXPropertyMapperErrorCodeMapperDidNotFound
                                         userInfo:@{NSLocalizedDescriptionKey:description}];
        validationErrors = @[error];
    } else {
        validationErrors = [self _validateMapping:mappings withValues:dictionary];
    }
    
    if (validationErrors.count > 0) {
        if (errors != NULL) {
            *errors = validationErrors;
        }
        return nil;
    }
    
    return [self _createObjectWithClass:clazz fromDictionary:dictionary];
}

- (NSDictionary *)exportObject:(id)object
{
    return [self exportObject:object withOptions:CTXPropertyMapperExportOptionExcludeNullValue];
}

- (NSDictionary *)exportObject:(id)object withOptions:(enum CTXPropertyMapperExportOption)options
{
    NSDictionary *mappings = self.mappingsByClass[[object class].description];
    NSMutableDictionary *exportedObject = [NSMutableDictionary dictionary];
    
    [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
        if ((descriptor.mode & CTXPropertyMapperCodificationModeEncode) == CTXPropertyMapperCodificationModeEncode) {
            NSArray *parts = [key componentsSeparatedByString:@"."];
            __block NSMutableDictionary *currentDictionary = exportedObject;
            [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, BOOL *stop) {
                if (idx == parts.count - 1) {
                    id value = [self _getSafeValueForKey:descriptor.propertyName atObject:object];
                    if (!value && options == CTXPropertyMapperExportOptionIncludeNullValue) {
                        value = [NSNull  null];
                    }
                    
                    switch (descriptor.type) {
                        case CTXPropertyDescriptorTypeDirect:
                        {
                            [currentDictionary setValue:value forKey:part];
                        } break;
                        case CTXPropertyDescriptorTypeClass:
                        {
                            if ([value isKindOfClass:NSSet.class]) {
                                NSMutableArray *items = [NSMutableArray array];
                                [(NSSet *)value enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                    [items addObject:[self exportObject:obj]];
                                }];
                                [currentDictionary setValue:items forKey:part];
                            }else if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSOrderedSet.class]) {
                                NSMutableArray *items = [NSMutableArray array];
                                [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                    [items addObject:[self exportObject:obj]];
                                }];
                                [currentDictionary setValue:items forKey:part];
                            } else {
                                [currentDictionary setValue:[self exportObject:value] forKey:part];
                            }
                        } break;
                        case CTXPropertyDescriptorTypeSymmetricalBlock:
                        {
                            [currentDictionary setValue:descriptor.encodingBlock(value, key) forKey:part];
                        } break;
                        case CTXPropertyDescriptorTypeAsymmetricalBlock:
                        {
                            [currentDictionary setValue:descriptor.encodingGenerationBlock(object) forKey:part];
                        } break;
                    }
                } else {
                    if (![currentDictionary valueForKey:part]) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        [currentDictionary setValue:dict forKey:part];
                        currentDictionary = dict;
                    }
                }
            }];
        }
    }];
    
    return exportedObject;
}

+ (NSDictionary *)generateMappingsFromClass:(Class)clazz
{
    NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
    
    NSArray *allowedTypes = @[@"NSNumber", @"NSString", @"c", @"d", @"i", @"f", @"l", @"s", @"I"];
    
    NSDictionary *properties = [NSObject propertiesDictionaryFromClass:clazz];
    
    for (NSString *property in [properties allKeys]) {
        NSString *type = properties[property];
        
        if ([allowedTypes containsObject:type]) {
            [mappings setValue:[[CTXPropertyDescriptor alloc] initWithPropertyName:property] forKey:property];
        }
    }
    
    return mappings;
}

+ (NSDictionary *)generateMappingsWithKeys:(NSArray *)keys
{
    NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
    for (NSString *key in keys) {
        [mappings setValue:[[CTXPropertyDescriptor alloc] initWithPropertyName:key] forKey:key];
    }
    return mappings;
}

#pragma mark - Private Methods

- (NSDictionary *)propertiesForClass:(Class)clazz
{
    NSDictionary *properties = self.cachedPropertiesByClass[[clazz description]];
    
    if (!properties) {
        
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
        
        Class currentClass = clazz;
        while (currentClass) {
            [mutableDictionary addEntriesFromDictionary:[NSObject propertiesDictionaryFromClass:currentClass]];
            currentClass = class_getSuperclass(currentClass);
        }
        
        properties = mutableDictionary;
        
        self.cachedPropertiesByClass[[clazz description]] = properties;
    }
    
    return properties;
}

- (id)_getSafeValueForKey:(NSString *)key atObject:(id)object
{
    if (!key) {
        return nil;
    }
    
    //TODO: Improve getValue verification, do not allowing unexpected properties like blocks and selectors
    return [object wrappedValueForKey:key];
}

- (void)_setSafeValue:(id)value forKey:(NSString *)key toObject:(id)object
{
    if (value == nil || value == [NSNull null]) {
        [object setValue:nil forKey:key];
        return;
    }
    
    //TODO: Improve setValue verification
    
    if ([value isKindOfClass:NSArray.class]) {
        NSDictionary *properties = [self propertiesForClass:[object class]];
        //TODO: Actually doesn't support subclasses of the follow entities
        if ([properties[key] isEqualToString:[NSArray description]] || [properties[key] isEqualToString:[NSMutableArray description]]) {
            [object setValue:value forKey:key];
        } else if ([properties[key] isEqualToString:[NSSet description]] || [properties[key] isEqualToString:[NSMutableSet description]]) {
            [object setValue:[NSMutableSet setWithArray:value] forKey:key];
        } else if ([properties[key] isEqualToString:[NSOrderedSet description]] || [properties[key] isEqualToString:[NSMutableOrderedSet description]]){
            [object setValue:[NSMutableOrderedSet orderedSetWithArray:value] forKey:key];
        }
        
    } else {
        [object setValue:value forKey:key];
    }
}


- (id)_createObjectWithClass:(Class)clazz fromDictionary:(NSDictionary *)dictionary
{
    NSDictionary *mappings = self.mappingsByClass[[clazz description]];
    
    id instance = [self.modelFactory instanceForClass:clazz withDictionary:dictionary];
    
    [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
        if ([dictionary valueForKeyPath:key] &&
            (descriptor.mode & CTXPropertyMapperCodificationModeDecode) == CTXPropertyMapperCodificationModeDecode) {
            switch (descriptor.type) {
                case CTXPropertyDescriptorTypeDirect:
                {
                    [self _setSafeValue:[dictionary valueForKeyPath:key] forKey:descriptor.propertyName toObject:instance];
                } break;
                case CTXPropertyDescriptorTypeClass:
                {
                    id value = [dictionary valueForKeyPath:key];
                    if ([value isKindOfClass:NSDictionary.class]) {
                        id subInstance = [self _createObjectWithClass:descriptor.propertyClass fromDictionary:value];
                        [self _setSafeValue:subInstance forKey:descriptor.propertyName toObject:instance];
                    } else if ([value isKindOfClass:NSArray.class]) {
                        NSMutableArray *items = [NSMutableArray array];
                        [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            [items addObject:[self _createObjectWithClass:descriptor.propertyClass fromDictionary:obj]];
                        }];
                        [self _setSafeValue:items forKey:descriptor.propertyName toObject:instance];
                    }
                } break;
                case CTXPropertyDescriptorTypeSymmetricalBlock:
                {
                    [self _setSafeValue:descriptor.decodingBlock([dictionary valueForKeyPath:key], descriptor.propertyName) forKey:descriptor.propertyName toObject:instance];
                } break;
                case CTXPropertyDescriptorTypeAsymmetricalBlock:
                {
                    descriptor.decodingConsumerBlock([dictionary valueForKeyPath:key], instance);
                } break;
            }
        }
    }];
    
    return instance;
}

#pragma mark - Validations

- (NSArray *)_validateMapping:(NSDictionary *)mapping withValues:(id)values
{
    NSParameterAssert(mapping);

    if (!values) {
        return nil;
    }

    if ([values isKindOfClass:NSDictionary.class]) {
        return [self _validateMapping:mapping withValuesDictionary:values];
    } else if ([values isKindOfClass:NSArray.class]) {
        return [self _validateMapping:mapping withValuesArray:values];
    }
    return nil;
}

- (NSArray *)_validateMapping:(NSDictionary *)mapping withValuesArray:(NSArray *)values
{
    NSParameterAssert([values isKindOfClass:NSArray.class]);
    
    NSMutableArray *errors = [NSMutableArray new];
    
    [values enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
        if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSDictionary.class]) {
            NSArray *validationErrors = [self _validateMapping:mapping withValues:value];
            if (validationErrors) {
                [errors addObjectsFromArray:validationErrors];
            }
        }
    }];
    
    return errors;
}

- (NSArray *)_validateMapping:(NSDictionary *)mapping withValuesDictionary:(NSDictionary *)values
{
    NSParameterAssert([values isKindOfClass:NSDictionary.class]);
    
    NSMutableArray *errors = [NSMutableArray new];
    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
        id value = [values valueForKeyPath:key];
        if ([value isKindOfClass:NSNull.class]) {
            value = nil;
        }
        
        switch (descriptor.type) {
            case CTXPropertyDescriptorTypeClass:
            {
                NSDictionary *submapping = self.mappingsByClass[[descriptor.propertyClass description]];
                
                if (submapping) {
                    NSArray *validationErrors = [self _validateMapping:submapping withValues:value];
                    if (validationErrors) {
                        [errors addObjectsFromArray:validationErrors];
                    }
                } else {
                    NSString *description = [NSString stringWithFormat:CTXPropertyMapperErrorDescription[CTXPropertyMapperErrorCodeMapperDidNotFound], [descriptor.propertyClass description]];
                    
                    NSError *error = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
                                                         code:CTXPropertyMapperErrorCodeMapperDidNotFound
                                                     userInfo:@{NSLocalizedDescriptionKey:description}];
                    [errors addObject:error];
                }
            } break;
            default:
            {
                NSArray *validationErrors = [descriptor validateValue:value];
                if (validationErrors.count > 0) {
                    [errors addObjectsFromArray:validationErrors];
                }
            } break;
        }
    }];
    
    return errors;
}

@end


@implementation CTXPropertyMapperSimpleModelFactory

- (id)instanceForClass:(Class)class withDictionary:(NSDictionary *)dictionary
{
	return [[class alloc] init];
}

@end


@implementation NSObject (Properties)

NSString * getPropertyType(objc_property_t property) {
	const char *attributes = property_getAttributes(property);
	char buffer[1 + strlen(attributes)];
	strcpy(buffer, attributes);
	char *state = buffer, *attribute;
	while ((attribute = strsep(&state, ",")) != NULL) {
		if (attribute[0] == 'T' && attribute[1] != '@') {
			// it's a C primitive type:
			/*
			 if you want a list of what will be returned for these primitives, search online for
			 "objective-c" "Property Attribute Description Examples"
			 apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
			 */
			return [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
		}
		else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
			// it's an ObjC id type:
			return @"id";
		}
		else if (attribute[0] == 'T' && attribute[1] == '@' && attribute[2] == '?') {
			// it's an ObjC id type:
			return @"block";
		}
		else if (attribute[0] == 'T' && attribute[1] == '@') {
			// it's another ObjC object type:
			return [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
		}
	}
	return @"";
}

+ (NSDictionary *)propertiesDictionaryFromClass:(Class)clazz
{
	NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
	
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(clazz, &outCount);
	for (i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propName = property_getName(property);
		if(propName) {
			NSString *propertyName = [NSString stringWithUTF8String:propName];
			NSString *propertyType = getPropertyType(property);
			[results setObject:propertyType forKey:propertyName];
		}
	}
	free(properties);
	
	return [NSDictionary dictionaryWithDictionary:results];
}

- (id)wrappedValueForKey:(NSString *)key
{
	NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:NSSelectorFromString(key)];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:NSSelectorFromString(key)];
	[invocation setTarget:self];
	[invocation invoke];
	
#define WRAP_AND_RETURN(type) do { type val = 0; [invocation getReturnValue:&val]; return @(val); } while (0)
	
	const char *returnType = [signature methodReturnType];
	
	if (returnType[0] == _C_CONST){
		return nil;
	} else if (strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0) {
		__autoreleasing id returnObj;
		[invocation getReturnValue:&returnObj];
		return returnObj;
	} else if (strcmp(returnType, @encode(SEL)) == 0) {
		SEL selector = 0;
		[invocation getReturnValue:&selector];
		return NSStringFromSelector(selector);
	} else if (strcmp(returnType, @encode(Class)) == 0) {
		__autoreleasing Class theClass = Nil;
		[invocation getReturnValue:&theClass];
		return theClass;
	} else if (strcmp(returnType, @encode(char)) == 0) {
		WRAP_AND_RETURN(char);
	} else if (strcmp(returnType, @encode(int)) == 0) {
		WRAP_AND_RETURN(int);
	} else if (strcmp(returnType, @encode(short)) == 0) {
		WRAP_AND_RETURN(short);
	} else if (strcmp(returnType, @encode(long)) == 0) {
		WRAP_AND_RETURN(long);
	} else if (strcmp(returnType, @encode(long long)) == 0) {
		WRAP_AND_RETURN(long long);
	} else if (strcmp(returnType, @encode(unsigned char)) == 0) {
		WRAP_AND_RETURN(unsigned char);
	} else if (strcmp(returnType, @encode(unsigned int)) == 0) {
		WRAP_AND_RETURN(unsigned int);
	} else if (strcmp(returnType, @encode(unsigned short)) == 0) {
		WRAP_AND_RETURN(unsigned short);
	} else if (strcmp(returnType, @encode(unsigned long)) == 0) {
		WRAP_AND_RETURN(unsigned long);
	} else if (strcmp(returnType, @encode(unsigned long long)) == 0) {
		WRAP_AND_RETURN(unsigned long long);
	} else if (strcmp(returnType, @encode(float)) == 0) {
		WRAP_AND_RETURN(float);
	} else if (strcmp(returnType, @encode(double)) == 0) {
		WRAP_AND_RETURN(double);
	} else if (strcmp(returnType, @encode(BOOL)) == 0) {
		WRAP_AND_RETURN(BOOL);
	} else if (strcmp(returnType, @encode(bool)) == 0) {
		WRAP_AND_RETURN(BOOL);
	} else if (strcmp(returnType, @encode(char *)) == 0) {
		WRAP_AND_RETURN(const char *);
	} else if (strcmp(returnType, @encode(void (^)(void))) == 0) {
		__unsafe_unretained id block = nil;
		[invocation getReturnValue:&block];
		return block;
	} else {
		NSUInteger valueSize = 0;
		NSGetSizeAndAlignment(returnType, &valueSize, NULL);
		
		unsigned char valueBytes[valueSize];
		[invocation getReturnValue:valueBytes];
		
		return [NSValue valueWithBytes:valueBytes objCType:returnType];
	}
	
	return nil;
}

@end
