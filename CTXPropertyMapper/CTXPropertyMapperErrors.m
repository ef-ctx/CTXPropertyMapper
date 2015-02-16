//
//  CTXPropertyMapperErrors.m
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

#import "CTXPropertyMapperErrors.h"

NSString *const kCTXPropertyMapperErrorDomain = @"com.ef.ctx.property-mapper";

NSString *const CTXPropertyMapperErrorDescription[] = {
    [CTXPropertyMapperErrorCodeUnknownProperty]     = @"Mapper contains a not found property [%@] on class [%@]",
    [CTXPropertyMapperErrorCodeInvalidMapperFormat] = @"Property Mapper is invalid.",
    [CTXPropertyMapperErrorCodeMapperDidNotFound]   = @"Mapper for class [%@] not found",
    [CTXPropertyMapperErrorCodeValidationFailed]    = @"%@ validation failed on %@"
};
