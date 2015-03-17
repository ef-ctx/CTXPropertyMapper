//
//  CTXPropertyMapper.m
//  CTXFramework
//
//  Created by Mario on 09/12/2014.
//  Copyright (c) 2015 EF. All rights reserved.
//

#import "CTXPropertyMapper.h"
#import "CTXPropertyDescriptor.h"
#import "CTXPropertyMapperErrors.h"
#import "objc/runtime.h"

@interface NSObject (Properties)

+ (NSDictionary *)propertiesDictionaryFromClass:(Class)clazz;
- (id)wrappedValueForKey:(NSString *)key;

@end


@interface NSDictionary (CTXMutableDeepCopy)

- (NSMutableDictionary *)ctx_deepCopy;
- (NSMutableDictionary *)ctx_mutableDeepCopy;

@end


@interface NSMutableDictionary (CTXSetSafeValueForKey)

- (void)ctx_setSafeValue:(id)value forKey:(NSString *)key;

@end


@interface NSArray (CTXMutableDeepCopy)

- (NSMutableArray *)ctx_deepCopy;
- (NSMutableArray *)ctx_mutableDeepCopy;

@end


@interface NSMutableArray (CTXSetSafeValueForKey)

- (void)ctx_safeAddObject:(id)object;

@end


@interface CTXPropertyMapperSimpleModelFactory : NSObject<CTXPropertyMapperModelFactoryProtocol>

@end

@interface CTXPropertyMapper()

@property (nonatomic, strong) id<CTXPropertyMapperModelFactoryProtocol> modelFactory;
@property (nonatomic, strong) NSMutableDictionary *cachedPropertiesByClass;
@property (nonatomic, strong) NSMutableDictionary *mappingsByClass;

@property (nonatomic, strong) NSMapTable *finalMappingEncodersByClass;
@property (nonatomic, strong) NSMapTable *finalMappingDecodersByClass;
@property (nonatomic, strong) NSMutableDictionary *finalMappingDecoderOptionByClass;

@end


@implementation CTXPropertyMapper

#pragma mark - Public Methods

- (instancetype)init
{
	if (self = [super init]) {
		_mappingsByClass = [NSMutableDictionary dictionary];
		_cachedPropertiesByClass = [NSMutableDictionary dictionary];
		_modelFactory = [[CTXPropertyMapperSimpleModelFactory alloc] init];
		
		_finalMappingEncodersByClass = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsCopyIn];
		_finalMappingDecodersByClass = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsCopyIn];
		_finalMappingDecoderOptionByClass = [NSMutableDictionary dictionary];
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
	NSError *mappingError = [self _validateMappings:mappings forClass:clazz];
	
	if (error != NULL) {
		*error = mappingError;
	}
	
    if (!mappingError) {
        if (!self.mappingsByClass[[clazz description]]) {
            self.mappingsByClass[[clazz description]] = [NSMutableDictionary dictionary];
        }
        [self.mappingsByClass[[clazz description]] addEntriesFromDictionary:mappings];
    }
    
    return !mappingError;
}

- (void)addMappingsFromPropertyMapper:(CTXPropertyMapper *)propertyMapper
{
    [self.mappingsByClass addEntriesFromDictionary:[propertyMapper mappingsByClass]];
	
	for(NSString *className in propertyMapper.finalMappingEncodersByClass.keyEnumerator) {
		[self.finalMappingEncodersByClass setObject:[propertyMapper.finalMappingEncodersByClass objectForKey:className] forKey:className];
	}
	
	for(NSString *className in propertyMapper.finalMappingDecodersByClass.keyEnumerator) {
		[self.finalMappingDecodersByClass setObject:[propertyMapper.finalMappingDecodersByClass objectForKey:className] forKey:className];
	}
	
	[propertyMapper.finalMappingDecoderOptionByClass enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[self.finalMappingDecoderOptionByClass setObject:obj forKey:key];
	}];
}

- (BOOL)setMappings:(NSDictionary *)mappings forClass:(Class)clazz
{
	return [self setMappings:mappings forClass:clazz error:nil];
}

- (BOOL)setMappings:(NSDictionary *)mappings forClass:(Class)clazz error:(NSError *__autoreleasing*)error
{
	NSError *mappingError = [self _validateMappings:mappings forClass:clazz];
	
	if (error != NULL) {
		*error = mappingError;
	}
	
	if (!mappingError) {
		self.mappingsByClass[[clazz description]] = [mappings copy];
	}
	
	return !mappingError;
}

- (void)setFinalMappingEncoder:(CTXFinalMappingEncoderBlock)encoder forClass:(Class)clazz
{
	[self.finalMappingEncodersByClass setObject:encoder forKey:[clazz description]];
}

- (void)setFinalMappingDecoder:(CTXFinalMappingDecoderBlock)decoder forClass:(Class)clazz withOption:(CTXPropertyMapperFinalMappingDecoderOption)option
{
	[self.finalMappingDecodersByClass setObject:decoder forKey:[clazz description]];
	[self.finalMappingDecoderOptionByClass setObject:@(option) forKey:[clazz description]];
}

- (BOOL)removeMappingsForClass:(Class)clazz
{
	BOOL success = NO;
	
	if (self.mappingsByClass[[clazz description]]) {
		[self.mappingsByClass removeObjectForKey:[clazz description]];
		success = YES;
	}
	
	if([self.finalMappingEncodersByClass objectForKey:[clazz description]]) {
		[self.finalMappingEncodersByClass removeObjectForKey:[clazz description]];
		success = YES;
	}
	
	if([self.finalMappingDecodersByClass objectForKey:[clazz description]]) {
		[self.finalMappingDecodersByClass removeObjectForKey:[clazz description]];
		[self.finalMappingDecoderOptionByClass removeObjectForKey:[clazz description]];
		success = YES;
	}
	
	return success;
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
        NSString *description = [NSString stringWithFormat:CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCodeMapperDidNotFound),
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
	if(object == [NSNull null]) {
		return object;
	} else if(object == nil) {
		return nil;
	}
	
    NSDictionary *mappings = self.mappingsByClass[[object class].description];
    NSMutableDictionary *exportedObject = [NSMutableDictionary dictionary];
    
    [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
        if ((descriptor.mode & CTXPropertyMapperCodificationModeEncode) == CTXPropertyMapperCodificationModeEncode) {
            NSArray *parts = [key componentsSeparatedByString:@"."];
            __block NSMutableDictionary *currentDictionary = exportedObject;
            [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger index, BOOL *stp) {
                if (index == parts.count - 1) {
                    id value = [self _getSafeValueForKey:descriptor.propertyName atObject:object];
                    if (!value && options == CTXPropertyMapperExportOptionIncludeNullValue) {
                        value = [NSNull  null];
					}
					
					switch (descriptor.type) {
						case CTXPropertyDescriptorTypeDirect:
						{
							[currentDictionary ctx_setSafeValue:value forKey:part];
						} break;
						case CTXPropertyDescriptorTypeClass:
						{
							
							if ([value isKindOfClass:NSSet.class]) {
								NSMutableArray *items = [NSMutableArray array];
								[(NSSet *)value enumerateObjectsUsingBlock:^(id obj, BOOL *s) {
									[items addObject:[self exportObject:obj]];
								}];
								[currentDictionary ctx_setSafeValue:items forKey:part];
							}else if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSOrderedSet.class]) {
								NSMutableArray *items = [NSMutableArray array];
								[value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *s) {
									[items addObject:[self exportObject:obj]];
								}];
								[currentDictionary ctx_setSafeValue:items forKey:part];
							} else {
								[currentDictionary ctx_setSafeValue:[self exportObject:value withOptions:options] forKey:part];
							}
						} break;
						case CTXPropertyDescriptorTypeSymmetricalBlock:
						{
							[currentDictionary ctx_setSafeValue:descriptor.encodingBlock(value, key) forKey:part];
						} break;
						case CTXPropertyDescriptorTypeAsymmetricalBlock:
						{
							[currentDictionary ctx_setSafeValue:descriptor.encodingGenerationBlock(object) forKey:part];
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
	
	CTXFinalMappingEncoderBlock encoder = [self.finalMappingEncodersByClass objectForKey:[object class].description];
	if(encoder) {
		NSMutableDictionary *mutableExportedObject = [exportedObject ctx_mutableDeepCopy];
		encoder(mutableExportedObject, object);
		[exportedObject addEntriesFromDictionary:[mutableExportedObject ctx_deepCopy]];
	}
	
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

- (NSDictionary *)_propertiesForClass:(Class)clazz
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
        NSDictionary *properties = [self _propertiesForClass:[object class]];
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
	if(![dictionary isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
	
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
                        [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *s) {
                            [items ctx_safeAddObject:[self _createObjectWithClass:descriptor.propertyClass fromDictionary:obj]];
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
	
	
	CTXFinalMappingDecoderBlock finalDecoder = [self.finalMappingDecodersByClass objectForKey:[clazz description]];
	if(finalDecoder) {
		CTXPropertyMapperFinalMappingDecoderOption finalDecoderOption = [[self.finalMappingDecoderOptionByClass objectForKey:[clazz description]] unsignedIntegerValue];
		
		if(finalDecoderOption == CTXPropertyMapperFinalMappingDecoderOptionIncludeAllKeys) {
			finalDecoder(dictionary, instance);
		} else if(finalDecoderOption == CTXPropertyMapperFinalMappingDecoderOptionExcludeAlreadyMappedKeys) {

			
			NSMutableDictionary *filteredDictionary = [dictionary ctx_mutableDeepCopy];
			
			for(NSString *key in mappings.allKeys) {
				
				[filteredDictionary removeObjectForKey:key];
				
				NSRange keyPathSeparatorRange = [key rangeOfString:@"." options:NSBackwardsSearch];
				if(keyPathSeparatorRange.location != NSNotFound) {
					NSString *basePath = [key substringWithRange:NSMakeRange(0, keyPathSeparatorRange.location)];
					NSString *lastPathComponent = [key substringWithRange:NSMakeRange(keyPathSeparatorRange.location + keyPathSeparatorRange.length, key.length - (keyPathSeparatorRange.location + keyPathSeparatorRange.length))];
					[[filteredDictionary valueForKeyPath:basePath] removeObjectForKey:lastPathComponent];
				}
			}

			finalDecoder([filteredDictionary ctx_deepCopy], instance);
		}
	}
	
	return instance;
}

#pragma mark - Validations

- (NSError *)_validateMappings:(NSDictionary *)mappings forClass:(Class)clazz
{
	NSParameterAssert(mappings);
	NSParameterAssert(clazz);
	
	__block NSError *mappingError;
	
	NSDictionary *properties = [self _propertiesForClass:clazz];
	
	[mappings enumerateKeysAndObjectsUsingBlock:^(id key, CTXPropertyDescriptor *descriptor, BOOL *stop) {
		
		if (![key isKindOfClass:[NSString class]] || ![descriptor isKindOfClass:[CTXPropertyDescriptor class]]) {
			mappingError = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
											   code:CTXPropertyMapperErrorCodeInvalidMapperFormat
										   userInfo:@{NSLocalizedDescriptionKey:CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCodeInvalidMapperFormat)}];
			*stop = YES;
		} else if (descriptor.type != CTXPropertyDescriptorTypeAsymmetricalBlock && !properties[descriptor.propertyName]) {
			NSString *author = [NSString stringWithFormat:CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCodeUnknownProperty),
								descriptor.propertyName, [clazz description]];
			mappingError = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
											   code:CTXPropertyMapperErrorCodeUnknownProperty
										   userInfo:@{NSLocalizedDescriptionKey:author}];
			*stop = YES;
		}
	}];
	
	return mappingError;
}

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
                NSDictionary *subMapping = self.mappingsByClass[[descriptor.propertyClass description]];
                
                if (subMapping) {
                    NSArray *validationErrors = [self _validateMapping:subMapping withValues:value];
                    if (validationErrors) {
                        [errors addObjectsFromArray:validationErrors];
                    }
                } else {
                    NSString *description = [NSString stringWithFormat:CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCodeMapperDidNotFound), [descriptor.propertyClass description]];
                    
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

@implementation NSDictionary (CTXMutableDeepCopy)

- (NSMutableDictionary *)ctx_deepCopy
{
	NSMutableDictionary *returnDict = [[NSMutableDictionary alloc] initWithCapacity:self.count];
	
	NSArray *keys = [self allKeys];
	
	for(id key in keys) {
		id oneValue = [self objectForKey:key];
		id oneCopy = nil;
		
		if([oneValue conformsToProtocol:@protocol(NSCopying)]){
			oneCopy = [oneValue copy];
		} else {
			oneCopy = oneValue;
		}
		
		[returnDict setValue:oneCopy forKey:key];
	}
	
	return returnDict;
}

- (NSMutableDictionary *)ctx_mutableDeepCopy
{
	NSMutableDictionary *returnDict = [[NSMutableDictionary alloc] initWithCapacity:self.count];
	
	NSArray *keys = [self allKeys];
	
	for(id key in keys) {
		id oneValue = [self objectForKey:key];
		id oneCopy = nil;
		
		if([oneValue respondsToSelector:@selector(ctx_mutableDeepCopy)]) {
			oneCopy = [oneValue ctx_mutableDeepCopy];
		} else if([oneValue conformsToProtocol:@protocol(NSMutableCopying)]) {
			oneCopy = [oneValue mutableCopy];
		} else if([oneValue conformsToProtocol:@protocol(NSCopying)]){
			oneCopy = [oneValue copy];
		} else {
			oneCopy = oneValue;
		}
		
		[returnDict setValue:oneCopy forKey:key];
	}
	
	return returnDict;
}

@end

@implementation NSMutableDictionary (CTXSetSafeValueForKey)

- (void)ctx_setSafeValue:(id)value forKey:(NSString *)key
{
	if(value == nil) {
		return;
	}
	
	[self setValue:value forKey:key];
}

@end

@implementation NSArray (CTXMutableDeepCopy)

- (NSMutableArray *)ctx_deepCopy
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for(id oneValue in self) {
		id oneCopy = nil;
		
		if([oneValue conformsToProtocol:@protocol(NSCopying)]){
			oneCopy = [oneValue copy];
		} else {
			oneCopy = oneValue;
		}
		
		[returnArray addObject:oneCopy];
	}
	
	return returnArray;
}

- (NSMutableArray *)ctx_mutableDeepCopy
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for(id oneValue in self) {
		id oneCopy = nil;
		
		if([oneValue respondsToSelector:@selector(ctx_mutableDeepCopy)]) {
			oneCopy = [oneValue ctx_mutableDeepCopy];
		} else if([oneValue conformsToProtocol:@protocol(NSMutableCopying)]) {
			oneCopy = [oneValue mutableCopy];
		} else if([oneValue conformsToProtocol:@protocol(NSCopying)]){
			oneCopy = [oneValue copy];
		} else {
			oneCopy = oneValue;
		}
		
		[returnArray addObject:oneCopy];
	}
	
	return returnArray;
}

@end

@implementation NSMutableArray (CTXSetSafeValueForKey)

- (void)ctx_safeAddObject:(id)object
{
	if(object == nil) {
		return;
	}
	
	[self addObject:object];
}

@end