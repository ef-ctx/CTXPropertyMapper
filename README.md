# CTXPropertyMapper

Simple property mapper that solves the most common parsing problems. 

- Data Validations
- Type conversions
- Handle optimal properties
- Simple to use, and highly extensible  

## Prerequisites

CTXPropertyMapper advantages of recent Objective-C runtime advances, including ARC and blocks. It requires:

- iOS 6 or later.
- OS X 10.7 or later.

## Installing

To install using CocoaPods, add the following line to your project Podfile:

````ruby
pod 'CTXPropertyMapper'
````

## Example of usage

Assuming the follow model:

````objc
@interface User : NSObject
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSInteger age;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) Job *job;
@property (nonatomic, strong) NSURL *profileURL;
@end
````

receving the follow json format:

````json
{
	"avatarURL": "http://server.com/avatarurlpath",
	"firstName": "Jon",
	"lastName": "Snow",
	"origin": "Winterfell, The North, Westeros",
	"quote":"you know nothing Jon Snow (Ygritte)",
	"status":{
		"alive":true
	},
	"job": {
		"title":"The bastard of Winterfell",
		"sector":"Castle Black",
		"hours":"Full Time"
	}
}
````

follow the parsing code:

````objc
CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];

[mapper addMappings:@{@"firstName":CTXProperty(firstName),
						  @"lastName":CTXProperty(lastName),
						  @"status.alive":CTXProperty(active)
						  }
			   forClass:[User class]];
  
//Decoding
NSArray *errors = nil;
User *user = [mapper createObjectWithClass:[User class] fromDictionary:dictionary errors:&errors];

//Encoding
NSDictionary *output = [mapper exportObject:user];
````

## Advanced usage

CTXPropertyMapper is flexible enought to parse complex and chained objects.

````objc
CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init];

//URL
CTXValueTransformerBlock decodeURL = ^id(NSString *input, NSString *propertyName){
	return [NSURL URLWithString:input];
};

CTXValueTransformerBlock encodeURL = ^id(NSURL *input, NSString *propertyName){
	return [input absoluteString];
};

//Origin
CTXValueConsumerBlock decodeOrigin = ^void(NSString *input, User *user){
	NSArray *originParts = [input componentsSeparatedByString:@","];
	if (originParts.count == 3) {
		user.origin = originParts[0];
		user.region = originParts[1];
		user.continent = originParts[2];	
	}
};

CTXValueGenerationBlock *encodeOrigin = ^id(id object){
	return [[user.origin, user.region, user.continent] componentsJoinedByString:@","];
};

[mapper addMappings:@{@"title":CTXProperty(title),
						  @"sector":CTXProperty(sector),
						  @"hours"::CTXProperty(hours),
						  }
			   forClass:[Job class]];

[mapper addMappings:@{@"firstName":CTXProperty(firstName),
						  @"lastName":CTXProperty(lastName),
						  @"job":CTXClass(job, [Job class]),
						  @"avatarURL":CTXBlock(profileURL, encodeURL, decodeURL),
						  @"origin":CTXGenerationConsumerBlock(encodeOrigin, decodeOrigin)
						  }
			   forClass:[User class]];
			  
User *user = [mapper createObjectWithClass:[User class] fromDictionary:dictionary];
````

## Custom Factory

CTXPropertyMapper uses the default object initializer internally, but some technologies like CoreData requires a custom initializer. To support that you can use your own custom Factory implementing the protocol `CTXPropertyMapperModelFactoryProtocol`. The factory receive the class type and the dictionary for greater flexibility, allowing use models already created, fetching model instance from local storage.

````objc
@interface CoreDataModelFactory : NSObject<CTXPropertyMapperModelFactoryProtocol>
- (instancetype)initWithContext:(NSManagedObjectContext *)context;
@end

@implementation CoreDataModelFactory
- (id)instanceForClass:(Class)class withDictionary:(NSDictionary *)dictionary
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:[class description]] inManagedObjectContext:self.context];
	return [[NSManagedObjec alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
}
@end
````

Now just create your instance of CTXPropertyMapper initializing with your custom model factory.

````objc
CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] initWithModelFactory:[[CoreDataModelFactory alloc] init]];
````

## Validations

You can add validations to your mappings.

````objc
[mapper addMappings:@{@"title":CTXProperty(title).isRequired().min(10),
						  @"sector":CTXProperty(sector).lengthRange(5, 20),
						  @"hours"::CTXProperty(hours),
						  }
			   forClass:[Job class]];
````
If necessaire you can create your own validations, get inspired by looking at the category `CTXPropertyDescriptor+Validators(h,m)`.

### Buil-in validations

Code borrowed from our inspiration project [KZPropertyMapper](https://github.com/krzysztofzablocki/KZPropertyMapper)

#### Strings
* isRequired
* matchesRegEx
* length
* minLength
* maxLength
* lengthRange
* oneOf
* equalTo

#### Numbers
* min
* max
* range

## License

CTXPropertyMapper is released under a MIT License. See LICENSE file for details.

