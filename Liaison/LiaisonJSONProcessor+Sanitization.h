//
//  LiaisonJSONProcessor+Sanitization.h
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonJSONProcessor.h"


@interface LiaisonJSONProcessor (Sanitization)

- (NSDictionary *)sanitizeJSONDictionary:(NSDictionary *)dictionary
                    forEntityDescription:(LiaisonEntityDescription *)description;
- (NSDictionary *)sanitizeJSONDictionaryForJoinTable:(NSDictionary *)dictionary;
- (NSString *)entityNameForProperty:(NSString *)property;

@end
