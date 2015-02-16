//
//  CTXPropertyMapperModelFactoryProtocol.h
//  Pods
//
//  Created by Mario on 26/01/2015.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

@protocol CTXPropertyMapperModelFactoryProtocol <NSObject>

- (id)instanceForClass:(Class)class withDictionary:(NSDictionary *)dictionary;

@end