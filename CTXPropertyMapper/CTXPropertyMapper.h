//
//  CTXPropertyMapper.h
//  CTXFramework
//
//  Created by Mario on 09/12/2014.
//  Copyright (c) 2015 EF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTXPropertyMapperModelFactoryProtocol.h"
#import "CTXPropertyDescriptor.h"
#import "CTXPropertyDescriptor+Validators.h"
#import "CTXPropertyMapperErrors.h"

//! Project version number for CTXPropertyMapper.
FOUNDATION_EXPORT double CTXPropertyMapperVersionNumber;

//! Project version string for CTXPropertyMapper.
FOUNDATION_EXPORT const unsigned char CTXPropertyMapperVersionString[];

typedef NS_ENUM(NSUInteger, CTXPropertyMapperExportOption) {
	CTXPropertyMapperExportOptionExcludeNullValue,
	CTXPropertyMapperExportOptionIncludeNullValue
};

typedef void(^CTXFinalMappingDecoderBlock)(NSDictionary *input, id object);
typedef void(^CTXFinalMappingEncoderBlock)(NSMutableDictionary *output, id object);

typedef NS_ENUM(NSUInteger, CTXPropertyMapperFinalMappingDecoderOption) {
	CTXPropertyMapperFinalMappingDecoderOptionIncludeAllKeys,
	CTXPropertyMapperFinalMappingDecoderOptionExcludeAlreadyMappedKeys
};

@interface CTXPropertyMapper : NSObject

- (instancetype)initWithModelFactory:(id<CTXPropertyMapperModelFactoryProtocol>)modelFactory;


- (BOOL)addMappings:(NSDictionary *)mappings forClass:(Class)clazz;
- (BOOL)addMappings:(NSDictionary *)mappings forClass:(Class)clazz error:(NSError *__autoreleasing*)error;

- (void)addMappingsFromPropertyMapper:(CTXPropertyMapper *)propertyMapper;


- (BOOL)setMappings:(NSDictionary *)mappings forClass:(Class)clazz;
- (BOOL)setMappings:(NSDictionary *)mappings forClass:(Class)clazz error:(NSError *__autoreleasing*)error;

- (void)setFinalMappingEncoder:(CTXFinalMappingEncoderBlock)encoder forClass:(Class)clazz;
- (void)setFinalMappingDecoder:(CTXFinalMappingDecoderBlock)decoder forClass:(Class)clazz withOption:(CTXPropertyMapperFinalMappingDecoderOption)option;

- (BOOL)removeMappingsForClass:(Class)clazz;


- (id)createObjectWithClass:(Class)clazz fromDictionary:(NSDictionary *)dictionary;
- (id)createObjectWithClass:(Class)clazz fromDictionary:(NSDictionary *)dictionary errors:(NSArray *__autoreleasing*)errors;


- (NSDictionary *)exportObject:(id)object;
- (NSDictionary *)exportObject:(id)object withOptions:(enum CTXPropertyMapperExportOption)options;


+ (NSDictionary *)generateMappingsFromClass:(Class)clazz;
+ (NSDictionary *)generateMappingsWithKeys:(NSArray *)keys;

@end