//
//  CTXPropertyDescriptor.h
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CTXProperty(property) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property)];})
#define CTXPropertyEncode(property) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) mode:CTXPropertyMapperCodificationModeEncode];})
#define CTXPropertyDecode(property) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) mode:CTXPropertyMapperCodificationModeDecode];})
#define CTXClass(property, clazz) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) withClass:clazz];})
#define CTXClassEncode(property, clazz) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) withClass:clazz mode:CTXPropertyMapperCodificationModeEncode];})
#define CTXClassDecode(property, clazz) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) withClass:clazz mode:CTXPropertyMapperCodificationModeDecode];})
#define CTXBlock(property, encoder, decoder) ({[[CTXPropertyDescriptor alloc] initWithSelector:@selector(property) encondingBlock:encoder decodingBlock:decoder];})
#define CTXGenerationConsumerBlock(encoder, decoder) ({[[CTXPropertyDescriptor alloc] initWithEncodingGenerationBlock:encoder decodingConsumerBlock:decoder];})

typedef NS_ENUM(NSUInteger, CTXPropertyMapperCodificationMode) {
    CTXPropertyMapperCodificationModeEncode             = 1,
    CTXPropertyMapperCodificationModeDecode             = 2,
    CTXPropertyMapperCodificationModeEncodeAndDecode    = 3//Encode + Decode to allow bitwise operation
};

typedef NS_ENUM(NSUInteger, CTXPropertyDescriptorType) {
    CTXPropertyDescriptorTypeDirect,
    CTXPropertyDescriptorTypeClass,
    CTXPropertyDescriptorTypeSymmetricalBlock,
    CTXPropertyDescriptorTypeAsymmetricalBlock
};

typedef id(^CTXValueTransformerBlock)(id input, NSString *propertyName);

typedef id(^CTXValueGenerationBlock)(id object);
typedef void(^CTXValueConsumerBlock)(id input, id object);

@interface CTXPropertyDescriptor : NSObject
@property (nonatomic, readonly) NSString *propertyName;
@property (nonatomic, assign, readonly) Class propertyClass;
@property (nonatomic, readonly) NSMutableArray *validationBlocks;
@property (nonatomic, readonly) CTXValueTransformerBlock encodingBlock;
@property (nonatomic, readonly) CTXValueTransformerBlock decodingBlock;
@property (nonatomic, readonly) CTXValueGenerationBlock encodingGenerationBlock;
@property (nonatomic, readonly) CTXValueConsumerBlock decodingConsumerBlock;
@property (nonatomic, readonly) enum CTXPropertyMapperCodificationMode mode;
@property (nonatomic, readonly) enum CTXPropertyDescriptorType type;

- (instancetype)initWithSelector:(SEL)selector;
- (instancetype)initWithSelector:(SEL)selector mode:(enum CTXPropertyMapperCodificationMode)mode;
- (instancetype)initWithSelector:(SEL)selector withClass:(Class)clazz;
- (instancetype)initWithSelector:(SEL)selector withClass:(Class)clazz mode:(enum CTXPropertyMapperCodificationMode)mode;
- (instancetype)initWithSelector:(SEL)selector encondingBlock:(CTXValueTransformerBlock)encoder decodingBlock:(CTXValueTransformerBlock)decoder;
- (instancetype)initWithEncodingGenerationBlock:(CTXValueGenerationBlock)encoder decodingConsumerBlock:(CTXValueConsumerBlock)decoder;

- (void)addValidatorWithName:(NSString *)name validation:(BOOL (^)(id value))validator;
- (NSArray *)validateValue:(id)value;
@end
