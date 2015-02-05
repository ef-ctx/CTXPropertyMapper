//
//  CTXPropertyMapperModelFactoryProtocol.h
//  Pods
//
//  Created by Mario on 26/01/2015.
//
//

@protocol CTXPropertyMapperModelFactoryProtocol <NSObject>

- (id)instanceForClass:(Class)class withDictionary:(NSDictionary *)dictionary;

@end