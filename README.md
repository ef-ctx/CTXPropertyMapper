# CTXPropertyMapper

Simple property mapper that solves the most common parsing problems. 

- Data Validation
- Type conversion
- Handle optional properties
- Simple to use and highly extensible  

## Prerequisites

CTXPropertyMapper takes advantage of recent Objective-C runtime additions, including ARC and blocks. It requires:

- iOS 6 or later.
- OS X 10.7 or later.

## Installing

To install using CocoaPods add the following line to your project Podfile:

````ruby
pod 'CTXPropertyMapper'
````

## Example of usage

Assuming the following model:

````objc
@interface User : NSObject
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) Job *job;
@property (nonatomic, strong) NSURL *profileURL;
@end
````

and receiving the following json object:

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

the property mapper can be configured like so:

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

CTXPropertyMapper is flexible enough to parse complex and nested objects.

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
					  @"hours":CTXProperty(hours),
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

CTXPropertyMapper uses the default object initializer internally, but some technologies like CoreData require a custom initializer. To support that you can use your own custom Factory implementing the protocol `CTXPropertyMapperModelFactoryProtocol`. The factory receives the class type and a dictionary for added flexibility, allowing the use of already created models, or fetching model instance from the local storage.

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

## Final Encoders and Decoders

CTXPropertyMapper is very powerful and flexible, but cannot solve every single problem. Sometimes refinements on the final version of the encoded or decoded objects are necessary. To give developers more control we introduced a final step hook the that gives access to the full mapper state and is run right before the object is returned by the mapper.

````objc
[mapper setFinalMappingDecoder:^(NSDictionary *input, User *object){
    NSLog(@"[Warning] User non mapped keys %@", input);
} forClass:[User class] withOption:CTXPropertyMapperFinalMappingDecoderOptionExcludeAlreadyMappedKeys];
````

````objc
[mapper setFinalMappingEncoder:^(NSMutableDictionary *output, User *object){
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", object.firstName, object.lastName];
    [output setValue:fullName forKey:@"fullName"];
} forClass:[User class]];
````

## Automatic Mappings

Usually the client model has the same structure as the server. To avoid repetitive code, CTXPropertyMapper supports creating models automatically.

````objc
CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init]];

[mapper addMappings:[CTXPropertyMapper generateMappingsFromClass:[Job class]]
		   forClass:[Job class]];
````
We use some objective c runtime calls to create a valid mapper, ignoring pointer address, blocks, selectors, etc.
Currently supported properties:
- NSString
- NSNumber
- char
- double
- enum
- float
- int
- long
- short
- signed
- unsigned

### Limitations

Mapping generation doesn't consider inherited properties, created through protocols or dynamically created through the runtime, so use it wisely.

To support `keyPath` mappings, the CTXPropertyMapper considers all key names containing dots (.) as keyPaths, and does not support keys that originally contain dots.

## Helpers

If your local model shares property names with the remote model, but you don't want to map the whole object like the automatic mapping does, you can use the method `+ (NSDictionary *)generateMappingsWithKeys:(NSArray *)keys`, passing the array of properties that you want to map.

````objc
CTXPropertyMapper *mapper = [[CTXPropertyMapper alloc] init]];

[mapper addMappings:[CTXPropertyMapper generateMappingsWithKeys:@[@"title", @"sector"]]
		   forClass:[Job class]];
````

## Validations

You can add validations to your mappings.

````objc
[mapper addMappings:[CTXPropertyMapper generateMappingsFromClass:[Job class]]
		   forClass:[Job class]];
````
If necessary, you can create your own validations, get inspired by looking at the category `CTXPropertyDescriptor+Validators(h,m)`.

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
