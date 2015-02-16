//
//  CTXPropertyDescriptor+Validators.h
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//
//  code borrowed from project KZPropertyMapper
//  https://github.com/krzysztofzablocki/KZPropertyMapper

#import <Foundation/Foundation.h>

#import "CTXPropertyDescriptor.h"

@interface CTXPropertyDescriptor(Validators)

#pragma mark - Strings
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^isRequired)();
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^lengthRange)(NSInteger min, NSInteger max);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^matchesRegEx)(NSRegularExpression *regularExpression);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^length)(NSUInteger length);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^minLength)(NSInteger min);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^maxLength)(NSInteger max);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^oneOf)(NSArray *items);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^equalTo)(NSString *value);


#pragma mark - Numbers
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^min)(NSInteger min);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^max)(NSInteger max);
@property(nonatomic, copy, readonly) CTXPropertyDescriptor *(^range)(NSInteger min, NSInteger max);


@end
