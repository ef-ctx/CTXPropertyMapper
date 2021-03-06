//
//  CTXPropertyMapperErrors.h
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kCTXPropertyMapperErrorDomain;

typedef NS_ENUM(NSUInteger, CTXPropertyMapperErrorCode) {
    CTXPropertyMapperErrorCodeUnknownProperty       = 60520,
    CTXPropertyMapperErrorCodeInvalidMapperFormat   = 60530,
    CTXPropertyMapperErrorCodeMapperDidNotFound     = 60540,
    CTXPropertyMapperErrorCodeValidationFailed      = 60550,
    
};

extern NSString *CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCode code);
