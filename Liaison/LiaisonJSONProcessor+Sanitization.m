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

- (NSDictionary *)sanitizeJSONDictionary:(NSDictionary *)jsonDictionary
                    forEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    jsonDictionary = [self sanitizeTimestampsForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    jsonDictionary = [self sanitizePrimaryKeyForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
    jsonDictionary = [self sanitizeRelationshipsForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
//    jsonDictionary = [self sanitizeSubDictionariesForJSONDictionary:jsonDictionary withEntityDescription:entityDescription];
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
                                withEntityDescription:(LiaisonEntityDescription *)entityDescription
{
    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    
    ISO8601DateFormatter *dateFormatter = [[ISO8601DateFormatter alloc] init];
    NSArray *dateProperties = [entityDescription propertiesMarkedAsDate];
    
    for (NSString *property in dateProperties) {
        NSString *date = [sanitizedDictionary objectForKey:property];
        
        if (date.length > 0) [sanitizedDictionary setValue:[dateFormatter dateFromString:date] forKey:property];
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


//- (NSDictionary *)sanitizeSubDictionariesForJSONDictionary:(NSDictionary *)jsonDictionary
//                                     withEntityDescription:(LiaisonEntityDescription *)entityDescription
//{
//    NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
//    
//    for (id property in jsonDictionary) {
//        id value = [jsonDictionary valueForKey:property];
//        
//        if ([value isKindOfClass:[NSDictionary class]]) {
////            for (id subKey in value) {
////                NSString *newKey = [NSString stringWithFormat:@"%@_%@", property, subKey];
////                id subValue = [value objectForKey:subKey];
////                
////                [sanitizedDictionary setValue:subValue forKey:newKey];
////            }
////            
////            
////            [sanitizedDictionary removeObjectForKey:property];
//            
//            sanitizedDictionary = [self sanitizeJSONDictionary:jsonDictionary
//                                          forEntityDescription:<#(LiaisonEntityDescription *)#>]
//        }
//    }
//    
//    return sanitizedDictionary;
//}


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
