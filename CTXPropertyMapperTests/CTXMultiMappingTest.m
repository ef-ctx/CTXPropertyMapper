//
//  CTXMultiMappingTest.m
//  CTXPropertyMapper
//
//  Created by David Carvalho on 14/02/2015.
//  Copyright (c) 2015 EF. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTXPropertyMapper.h"
#import "User.h"

@interface CTXMultiMappingTest : XCTestCase

@end

@implementation CTXMultiMappingTest

- (void)testNewParser
{
    CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
    
    NSDictionary *mappings = [CTXPropertyMapper generateMappingsFromClass:[User class]];
    [mapper addMappings:mappings
               forClass:[User class]];
    [mapper addMappings:@{@"firstName":CTXProperty(firstNameDifferent)}
               forClass:[User class]];
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *path = [bundle pathForResource:@"TestData" ofType:@"json"];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:nil];
	
    NSArray *errors = nil;
    User *user = [mapper createObjectWithClass:[User class] fromDictionary:json errors:&errors];
    XCTAssert([user.firstNameDifferent isEqualToString:@"Jon"]);
}

@end
