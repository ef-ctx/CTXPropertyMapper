//
//  CTXPropertyMapperTests.m
//  CTXPropertyMapperTests
//
//  Created by Mario on 04/02/2015.
//  Copyright (c) 2015 EF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CTXPropertyMapper.h"

@interface ItemClass : NSObject
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *title;
@end
@implementation ItemClass
@end

@interface BaseClass : NSObject
@property (nonatomic, strong, readonly) NSString *uuid;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, assign, readonly) int page;
@property (nonatomic, strong, readonly) NSArray *children;
@property (nonatomic, strong, readonly) NSSet *set;
@property (nonatomic, strong, readonly) void ((^block)(void));
@property (nonatomic, strong, readonly) id subItem;
@property (nonatomic, retain, readonly) NSNumber *number;
@property (nonatomic, retain, readonly) ItemClass *itemClass;
@property (nonatomic, retain, readonly) NSOrderedSet *orderedSet;
@property (nonatomic, assign, readonly) BOOL usingCustomInit;
- (instancetype)initWithName:(NSString *)name;
@end
@implementation BaseClass
- (instancetype)initWithName:(NSString *)name
{
	if (self = [super init]) {
		_name = name;
		_usingCustomInit = YES;
	}
	return self;
}
@end

@interface SuperClass : BaseClass
@property (nonatomic, strong, readonly) NSString *firstName;
@end
@implementation SuperClass
@end


@interface SimpleFactory : NSObject<CTXPropertyMapperModelFactoryProtocol>
@end
@implementation SimpleFactory
- (id)instanceForClass:(Class)class withDictionary:(NSDictionary *)dictionary
{
	return [[class alloc] initWithName:@"custom name"];
}
@end



@interface CTXPropertyMapperTests : XCTestCase

@end

@implementation CTXPropertyMapperTests

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

- (void)testBasicParse
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":[NSNull null],
							 @"title":@"source title",
							 @"items":@[
									 @{
										 @"name":    @"Item Name 0",
										 @"title":   @"Item Title 0",
										 },
									 @{
										 @"name":    @"Item Name 1",
										 @"title":   @"Item Title 1",
										 },
									 @{
										 @"name":    @"Item Name 2",
										 @"title":   @"Item Title 2",
										 }
									 ]};
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  }
			   forClass:[ItemClass class]];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"items":CTXClass(children, [ItemClass class])
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert([instance.uuid isEqualToString:@"source id"]);
	XCTAssert(instance.name == nil);
	XCTAssert([instance.title isEqualToString:@"source title"]);
	XCTAssert(instance.page == 2);
	
	ItemClass *item0 = instance.children[0];
	XCTAssert([item0.name isEqualToString:@"Item Name 0"]);
	XCTAssert([item0.title isEqualToString:@"Item Title 0"]);
	
	ItemClass *item1 = instance.children[1];
	XCTAssert([item1.name isEqualToString:@"Item Name 1"]);
	XCTAssert([item1.title isEqualToString:@"Item Title 1"]);
	
	ItemClass *item2 = instance.children[2];
	XCTAssert([item2.name isEqualToString:@"Item Name 2"]);
	XCTAssert([item2.title isEqualToString:@"Item Title 2"]);
	
	
	NSDictionary *dict = [mapper exportObject:instance];
	XCTAssert(dict);
	XCTAssert([dict[@"id"] isEqualToString:@"source id"]);
	XCTAssert([[dict valueForKeyPath:@"metadata.pagination.page"] isEqualToNumber:@(2)]);
	XCTAssert(!dict[@"name"]);
	XCTAssert([dict[@"title"] isEqualToString:@"source title"]);
	XCTAssert([dict[@"items"][0][@"name"] isEqualToString:@"Item Name 0"]);
	XCTAssert([dict[@"items"][0][@"title"] isEqualToString:@"Item Title 0"]);
	XCTAssert([dict[@"items"][1][@"name"] isEqualToString:@"Item Name 1"]);
	XCTAssert([dict[@"items"][1][@"title"] isEqualToString:@"Item Title 1"]);
	XCTAssert([dict[@"items"][2][@"name"] isEqualToString:@"Item Name 2"]);
	XCTAssert([dict[@"items"][2][@"title"] isEqualToString:@"Item Title 2"]);
}

- (void)testMappingsErrors
{
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSError *error = nil;
	[mapper addMappings:@{
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  @(2):@"testing"
						  }
			   forClass:[ItemClass class] error:&error];
	
	XCTAssert(error);
	XCTAssert(error.code == CTXPropertyMapperErrorCodeInvalidMapperFormat);
    XCTAssertNotNil(error.description);
}

- (void)testValidationErrors
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":@"source names",
							 @"title":[NSNull null]};
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"items":CTXClass(children, [ItemClass class])
						  }
			   forClass:[BaseClass class]];
	
	NSArray *errors = nil;
	[mapper createObjectWithClass:[BaseClass class] fromDictionary:source errors:&errors];
	
	XCTAssert(errors);
	XCTAssert(errors.count == 1);
	
	NSError *error = errors.firstObject;
	XCTAssert(error.code == CTXPropertyMapperErrorCodeMapperDidNotFound);
    XCTAssertNotNil(error.description);
}

- (void)testEncodeOnly
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":@"source names",
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXPropertyDecode(name),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page)
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert([instance.name isEqualToString:@"source names"]);
	
	NSDictionary *dict = [mapper exportObject:instance];
	
	XCTAssert(dict);
	XCTAssert(dict[@"name"] == nil);
}

- (void)testDecodeOnly
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":@"source names",
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXPropertyEncode(name),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page)
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert(instance.name == nil);
	
	[instance setValue:@"testing name" forKey:@"name"];
	NSDictionary *dict = [mapper exportObject:instance];
	
	XCTAssert(dict);
	XCTAssert([dict[@"name"] isEqualToString:@"testing name"]);
}

- (void)testBlock
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":@"source names",
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXBlock(name,
										   ^(id input, NSString *property){return @[@{@"value":input}];},
										   ^(id input, NSString *property){return [input stringByAppendingString:@"!"];}),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page)
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert([instance.name isEqualToString:@"source names!"]);
	
	[instance setValue:@"testing name" forKey:@"name"];
	NSDictionary *dict = [mapper exportObject:instance];
	
	XCTAssert(dict);
	XCTAssert([[dict valueForKeyPath:@"name.value"][0] isEqualToString:@"testing name"]);
}

- (void)testValidation
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"name":CTXProperty(name).isRequired(),
						  @"metadata.pagination.page":CTXProperty(page)
						  }
			   forClass:[BaseClass class]];
	
	NSArray *errors = nil;
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source errors:&errors];
	
	XCTAssert(!instance);
	
	NSError *error = errors[0];
	XCTAssert(error.code == CTXPropertyMapperErrorCodeValidationFailed);
    XCTAssertNotNil(error.description);
}


- (void)testPropertyMapperGenerator
{
	BaseClass *base = [[BaseClass alloc] init];
	NSDictionary *dictionary = [CTXPropertyMapper generateMappingsFromClass:[base class]];
	
	XCTAssert(dictionary.count == 5);
	XCTAssert([dictionary valueForKey:@"name"]);
	XCTAssert([dictionary valueForKey:@"number"]);
	XCTAssert([dictionary valueForKey:@"page"]);
	XCTAssert([dictionary valueForKey:@"title"]);
	XCTAssert([dictionary valueForKey:@"uuid"]);
}

- (void)testSetProperty
{
	NSDictionary *source = @{@"name":@"source name",
							 @"title":@"source title",
							 @"orderedSet":@[
									 @{
										 @"name":    @"Item Name 0",
										 @"title":   @"Item Title 0",
										 },
									 @{
										 @"name":    @"Item Name 1",
										 @"title":   @"Item Title 1",
										 },
									 @{
										 @"name":    @"Item Name 2",
										 @"title":   @"Item Title 2",
										 }
									 ],
							 @"set":@[
									 @{
										 @"name":    @"Item Name 0",
										 @"title":   @"Item Title 0",
										 },
									 @{
										 @"name":    @"Item Name 1",
										 @"title":   @"Item Title 1",
										 }
									 ],};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"name":CTXProperty(name),
						  @"set":CTXClass(set, [ItemClass class]),
						  @"orderedSet":CTXClass(orderedSet, [ItemClass class])
						  }
			   forClass:[BaseClass class]];
	
	[mapper addMappings:@{
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  }
			   forClass:[ItemClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	XCTAssert(instance);
	XCTAssert([instance.set count] == 2);
	XCTAssert([instance.orderedSet count] == 3);
	XCTAssert([instance.set isKindOfClass:NSSet.class]);
	XCTAssert([instance.orderedSet isKindOfClass:NSOrderedSet.class]);
	
	NSDictionary *dict = [mapper exportObject:instance];
	XCTAssert(dict);
	XCTAssert([dict[@"set"] count] == 2);
	XCTAssert([dict[@"orderedSet"] count] == 3);
	
}

- (void)testUnknownClassProperty
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSError *error = nil;
	
	[mapper addMappings:@{
						  @"id":CTXProperty(uuid),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"unknown":CTXProperty(unknown)
						  }
			   forClass:[BaseClass class]
				  error:&error];
	
	XCTAssert(error);
	XCTAssert(error.code == CTXPropertyMapperErrorCodeUnknownProperty);
    XCTAssertNotNil(error.description);
	
	NSArray *errors = nil;
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source errors:&errors];
	
	XCTAssert(!instance);
	
	error = errors[0];
	XCTAssert(error.code == CTXPropertyMapperErrorCodeMapperDidNotFound);
    XCTAssertNotNil(error.description);
}

- (void)testUnknownDictProperty
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"title":@"source title"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSError *error = nil;
	
	[mapper addMappings:@{
						  @"title":CTXProperty(title).isRequired(),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"unknown":CTXProperty(uuid)
						  }
			   forClass:[BaseClass class]
				  error:&error];
	
	XCTAssert(!error);
	
	NSArray *errors = nil;
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source errors:&errors];
	
	XCTAssert(instance);
	XCTAssert([instance.title isEqualToString:@"source title"]);
	XCTAssert(instance.page == 2);
	XCTAssert(instance.uuid == nil);
}

- (void)testSuperClass
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"title":@"source title",
							 @"firstName":@"source firstName"};
	
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSError *error = nil;
	
	[mapper addMappings:@{@"id":CTXProperty(uuid),
						  @"title":CTXProperty(title).isRequired(),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"firstName":CTXProperty(firstName)
						  }
			   forClass:[SuperClass class]
				  error:&error];
	
	XCTAssert(!error);
	
	NSArray *errors = nil;
	SuperClass *instance = [mapper createObjectWithClass:[SuperClass class] fromDictionary:source errors:&errors];
	
	XCTAssert(instance);
	XCTAssert([instance.uuid isEqualToString:@"source id"]);
	XCTAssert([instance.title isEqualToString:@"source title"]);
	XCTAssert([instance.firstName isEqualToString:@"source firstName"]);
}

- (void)testNilChildObject
{
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"name":[NSNull null],
							 @"title":@"source title",
							 @"item":[NSNull null]};
	
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	[mapper addMappings:@{
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  }
			   forClass:[ItemClass class]];
	
	[mapper addMappings:@{@"id":CTXProperty(uuid),
						  @"name":CTXProperty(name),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page),
						  @"item":CTXClass(itemClass, [ItemClass class])
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert(instance.itemClass == nil);
}

- (void)testFactory
{
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] initWithModelFactory:[[SimpleFactory alloc] init]];
	
	NSDictionary *source = @{@"id":@"source id",
							 @"metadata":@{@"pagination":@{@"page":@(2)}},
							 @"title":@"source title"};
	
	[mapper addMappings:@{@"id":CTXProperty(uuid),
						  @"title":CTXProperty(title),
						  @"metadata.pagination.page":CTXProperty(page)
						  }
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	
	XCTAssert(instance);
	XCTAssert(instance.usingCustomInit);
}

- (void)testSetMappings
{
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSDictionary *source = @{@"title":@"source title"};
	
	[mapper setMappings:@{@"title":CTXProperty(title)}
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	XCTAssert(instance);
	XCTAssert(instance.name == nil);
	XCTAssert([instance.title isEqualToString:@"source title"]);

	[mapper setMappings:@{@"title":CTXProperty(name)}
			   forClass:[BaseClass class]];
	
	instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	XCTAssert(instance);
	XCTAssert(instance.title == nil);
	XCTAssert([instance.name isEqualToString:@"source title"]);
}

- (void)testRemoveMappings
{
	CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];
	
	NSDictionary *source = @{@"title":@"source title"};
	
	[mapper setMappings:@{@"title":CTXProperty(title)}
			   forClass:[BaseClass class]];
	
	BaseClass *instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	XCTAssert(instance);
	
	[mapper removeMappingsForClass:[BaseClass class]];
	instance = [mapper createObjectWithClass:[BaseClass class] fromDictionary:source];
	XCTAssert(instance == nil);
}



@end