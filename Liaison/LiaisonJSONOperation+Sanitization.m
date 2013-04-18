//
//  LiaisonJSONOperation+Sanitization.m
//  Liaison
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonJSONOperation+Sanitization.h"
#import "ISO8601DateFormatter.h"


@implementation LiaisonJSONOperation (Sanitization)

- (NSDictionary *)sanitizeJSONDictionary:(NSDictionary *)jsonDictionary
                    forEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    jsonDictionary = [self sanitizeTimestampsForJSONDictionary:jsonDictionary];
    jsonDictionary = [self sanitizePrimaryKeyForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    jsonDictionary = [self sanitizeRelationshipsForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    jsonDictionary = [self sanitizeSubDictionariesForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    jsonDictionary = [self sanitizeUnimplementedKeysForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    
    return jsonDictionary;
}


- (NSDictionary *)sanitizeJSONDictionaryForJoinTable:(NSDictionary *)jsonDictionary
                               withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    for (NSString *property in jsonDictionary) {
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

- (NSDictionary *)sanitizePrimaryKeyForJSONDictionary:(NSDictionary *)jsonDictionary
                                withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    NSString *value = [sanitizedDictionary objectForKey:@"id"];
    
    if (value) {
        [sanitizedDictionary setValue:value forKey:entityDescription.primaryKey];
        [sanitizedDictionary removeObjectForKey:@"id"];
    }
    
    return sanitizedDictionary;
}


- (NSDictionary *)sanitizeTimestampsForJSONDictionary:(NSDictionary *)jsonDictionary
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    NSString *createdAt = [sanitizedDictionary objectForKey:@"created_at"];
    NSString *updatedAt = [sanitizedDictionary objectForKey:@"updated_at"];
    NSString *date = [sanitizedDictionary objectForKey:@"date"];
    
    ISO8601DateFormatter *dateFormatter = [[ISO8601DateFormatter alloc] init];
    
    if (createdAt.length > 0) {
        [sanitizedDictionary setValue:[dateFormatter dateFromString:createdAt] forKey:@"created_at"];
    }
    
    if (updatedAt.length > 0) {
        [sanitizedDictionary setValue:[dateFormatter dateFromString:updatedAt] forKey:@"updated_at"];
    }
    
    if (date.length > 0) {
        [sanitizedDictionary setValue:[dateFormatter dateFromString:date] forKey:@"date"];
    }
    
    return sanitizedDictionary;
}


- (NSDictionary *)sanitizeRelationshipsForJSONDictionary:(NSDictionary *)jsonDictionary
                                   withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    for (NSString *property in jsonDictionary) {
        if ([self isPropertyRelationship:property forEntityDescription:entityDescription]) {
            NSString *relationshipEntityName = [self entityNameForProperty:property];
            NSEntityDescription *description = [NSEntityDescription entityForName:entityDescription.entityName
                                                           inManagedObjectContext:self.context];
            NSEntityDescription *relationshipEntity = [NSEntityDescription entityForName:relationshipEntityName
                                                                  inManagedObjectContext:self.context];
            
            NSArray *relationships = [description relationshipsWithDestinationEntity:relationshipEntity];
            
            if (relationships.count <= 0) continue;
            
            [sanitizedDictionary removeObjectForKey:property];
        }
    }
    
    return sanitizedDictionary;
}


- (NSDictionary *)sanitizeSubDictionariesForJSONDictionary:(NSDictionary *)jsonDictionary
                                     withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    for (id property in jsonDictionary) {
        id value = [jsonDictionary valueForKey:property];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            for (id subKey in value) {
                NSString *newKey = [NSString stringWithFormat:@"%@_%@", property, subKey];
                id subValue = [value objectForKey:subKey];
                
                [sanitizedDictionary setValue:subValue forKey:newKey];
            }
            
            
            [sanitizedDictionary removeObjectForKey:property];
        }
    }
    
    return sanitizedDictionary;
}


- (NSDictionary *)sanitizeUnimplementedKeysForJSONDictionary:(NSDictionary *)jsonDictionary
                                       withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    for (NSString *property in jsonDictionary) {
        NSEntityDescription *description = [NSEntityDescription entityForName:entityDescription.entityName
                                                       inManagedObjectContext:self.context];
        
        if ([[[description attributesByName] allKeys] containsObject:property] == YES) continue;
        
        [sanitizedDictionary removeObjectForKey:property];
    }
    
    return sanitizedDictionary;
}


- (BOOL)isPropertyRelationship:(NSString *)property forEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    BOOL isRelationship = NO;
    
    if ([property hasSuffix:@"_id"]) isRelationship = YES;
    if ([property hasPrefix:[entityDescription.entityName lowercaseString]]) isRelationship = NO;
    
    return isRelationship;
}

@end
