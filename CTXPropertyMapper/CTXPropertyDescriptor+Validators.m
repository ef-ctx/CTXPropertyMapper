//
//  CTXPropertyDescriptor+Validators.m
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//
//  code borrowed from project KZPropertyMapper
//  https://github.com/krzysztofzablocki/KZPropertyMapper

#import <objc/message.h>
#import "CTXPropertyDescriptor+Validators.h"

@implementation CTXPropertyDescriptor (Validators)

#pragma mark - Strings
- (CTXPropertyDescriptor * (^)())isRequired
{
    return ^() {
        [self addValidatorWithName:@"isRequired" validation:^(id value) {
            return YES;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSInteger, NSInteger))lengthRange
{
    return ^(NSInteger min, NSInteger max) {
        NSInteger realMax = MAX(min, max);
        NSInteger realMin = MIN(min, max);
        [self addValidatorWithName:@"lengthRange" validation:^BOOL(NSString *value) {
            return value.length >= realMin && value.length <= realMax;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSRegularExpression *regEx))matchesRegEx
{
    return ^(NSRegularExpression *regEx) {
        [self addValidatorWithName:@"matchesRegex" validation:^BOOL(NSString *value) {
            NSUInteger matches = [regEx numberOfMatchesInString:value options:0 range:NSMakeRange(0, value.length)];
            return matches == 1;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSUInteger length))length
{
    return ^(NSUInteger number) {
        [self addValidatorWithName:@"length" validation:^BOOL(NSString *value) {
            return value.length == number;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSInteger minLength))minLength
{
    return ^(NSInteger number) {
        [self addValidatorWithName:@"minLength" validation:^BOOL(NSString *value) {
            return value.length >= number;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSInteger maxLength))maxLength
{
    return ^(NSInteger number) {
        [self addValidatorWithName:@"maxLength" validation:^BOOL(NSString *value) {
            return value.length <= number;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSArray *))oneOf
{
    return ^(NSArray *array) {
        [self addValidatorWithName:@"oneOf" validation:^BOOL(NSString *value) {
            return [array containsObject:value];
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSString *))equalTo
{
    return ^(NSString *compare) {
        [self addValidatorWithName:@"equalTo" validation:^BOOL(NSString* value) {
            return [value isEqualToString:compare];
        }];
        return self;
    };
}

#pragma mark - Numbers

- (CTXPropertyDescriptor * (^)(NSInteger min))min
{
    return ^(NSInteger min) {
        [self addValidatorWithName:@"min" validation:^BOOL(NSNumber *value) {
            return value.integerValue >= min;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSInteger max))max
{
    return ^(NSInteger maxNumber) {
        [self addValidatorWithName:@"max" validation:^BOOL(NSNumber *value) {
            BOOL v = value.integerValue <= maxNumber;
            return v;
        }];
        return self;
    };
}

- (CTXPropertyDescriptor * (^)(NSInteger, NSInteger))range
{
    return ^(NSInteger min, NSInteger max) {
        NSInteger realMax = MAX(min, max);
        NSInteger realMin = MIN(min, max);
        [self addValidatorWithName:@"range" validation:^BOOL(NSNumber *value) {
            return value.integerValue >= realMin && value.integerValue <= realMax;
        }];
        return self;
    };
}

@end
