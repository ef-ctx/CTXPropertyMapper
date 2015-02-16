//
//  CTXPropertyMapperErrors.m
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

#import "CTXPropertyMapperErrors.h"

NSString *const kCTXPropertyMapperErrorDomain = @"com.ef.ctx.property-mapper";

extern NSString *CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCode code)
{
    static NSDictionary *descriptions = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        descriptions = @{
                @(CTXPropertyMapperErrorCodeUnknownProperty)     : @"Property Mapper contains a not found property [%@] on class [%@]",
                @(CTXPropertyMapperErrorCodeInvalidMapperFormat) : @"Property Mapper is invalid.",
                @(CTXPropertyMapperErrorCodeMapperDidNotFound)   : @"Property Mapper for class [%@] is not found",
                @(CTXPropertyMapperErrorCodeValidationFailed)    : @"[%@] validation failed on [%@]"
        };
    });
    return descriptions[@(code)];
}
