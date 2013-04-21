//
//  LiaisonJSONProcessor+Sanitization.m
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonJSONProcessor+Sanitization.h"
#import "ISO8601DateFormatter.h"


@implementation LiaisonJSONProcessor (Sanitization)

- (NSDictionary *)sanitizeJSONDictionary:(NSDictionary *)dictionary
                    forEntityDescription:(LiaisonEntityDescription *)description
{
    NSArray *implementedKeys = [self implementedKeysForEntityDescription:description];
    
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    [self sanitizeTimestampsForDictionary:sanitizedDictionary withEntityDescription:description];
    [self sanitizePrimaryKeyForDictionary:sanitizedDictionary withEntityDescription:description];
    
    for (NSString *property in dictionary) {
        if ([self isPropertyRelationship:property] == YES) {
            [self sanitizeRelationship:property inDictionary:sanitizedDictionary withDescription:description];
        }
        
        if ([implementedKeys containsObject:property] == NO) {
            [sanitizedDictionary removeObjectForKey:property];
        }
    }
    
    return sanitizedDictionary;
}


- (NSDictionary *)sanitizeJSONDictionaryForJoinTable:(NSDictionary *)dictionary
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    for (NSString *property in dictionary) {
        if ([property hasSuffix:@"_id"] == NO) {
            [sanitizedDictionary removeObjectForKey:property];
        }
    }
    
    return sanitizedDictionary;
}


- (NSString *)entityNameForProperty:(NSString *)property
{
    NSString *entityName = [[property stringByReplacingOccurrencesOfString:@"_id" withString:@""] capitalizedString];
    
    return [entityName stringByReplacingOccurrencesOfString:@"_" withString:@""];
}


#pragma mark - Helpers

- (void)sanitizeTimestampsForDictionary:(NSMutableDictionary *)dictionary
                            withEntityDescription:(LiaisonEntityDescription *)description
{
    ISO8601DateFormatter *dateFormatter = [[ISO8601DateFormatter alloc] init];
    NSArray *dateProperties = description.propertiesMarkedAsDate;
    
    for (NSString *property in dateProperties) {
        NSString *date = [dictionary objectForKey:property];
        
        if (date.length > 0) [dictionary setValue:[dateFormatter dateFromString:date] forKey:property];
    }
}


- (void)sanitizePrimaryKeyForDictionary:(NSMutableDictionary *)dictionary
                  withEntityDescription:(LiaisonEntityDescription *)description
{
    NSString *value = [dictionary objectForKey:@"id"];
    
    if (value != nil) {
        [dictionary setValue:value forKey:description.primaryKey];
        [dictionary removeObjectForKey:@"id"];
    }
}


- (void)sanitizeRelationship:(NSString *)relationship
                inDictionary:(NSMutableDictionary *)dictionary
             withDescription:(LiaisonEntityDescription *)description
{
    NSString *relationshipEntityName = [self entityNameForProperty:relationship];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:description.entityName
                                                         inManagedObjectContext:self.context];
    NSEntityDescription *relationshipEntity = [NSEntityDescription entityForName:relationshipEntityName
                                                          inManagedObjectContext:self.context];
    
    NSArray *relationships = [entityDescription relationshipsWithDestinationEntity:relationshipEntity];
    
    if (relationships.count <= 0) return;
    
    [dictionary removeObjectForKey:relationship];
}


- (NSArray *)implementedKeysForEntityDescription:(LiaisonEntityDescription *)description
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:description.entityName
                                                         inManagedObjectContext:self.context];

    return [[entityDescription attributesByName] allKeys];
}


- (BOOL)isPropertyRelationship:(NSString *)property
{
    return [property hasSuffix:@"_id"];
}

@end
