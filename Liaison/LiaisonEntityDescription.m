//
//  LiaisonEntityDescription.m
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonEntityDescription.h"


@interface LiaisonEntityDescription()
@property (nonatomic) NSMutableArray *dateProperties;
@property (nonatomic) NSMutableDictionary *nestedEntityDescriptions;
@end


@implementation LiaisonEntityDescription

#pragma mark - Designated Initializer

+ (LiaisonEntityDescription *)descriptionForEntityName:(NSString *)entityName
                                       andRelationship:(NSString *)relationshipName
{
    LiaisonEntityDescription *entityDescription = [[LiaisonEntityDescription alloc] init];
    
    entityDescription.entityName = entityName;
    entityDescription.primaryKey = [entityDescription primaryKeyForEntityName];
    entityDescription.relationshipName = relationshipName;
    entityDescription.isJoinTable = NO;
    entityDescription.postProcessingBlock = ^(NSManagedObjectContext *localContext, NSSet *processObjects) {
    };
    
    entityDescription.dateProperties = [NSMutableArray array];
    entityDescription.nestedEntityDescriptions = [NSMutableDictionary dictionary];
    
    return entityDescription;
}


#pragma mark - API

- (void)markPropertyAsDate:(NSString *)propertyName
{
    [self.dateProperties addObject:propertyName];
}


- (NSArray *)propertiesMarkedAsDate
{
    return self.dateProperties;
}


- (void)setEntityDescription:(LiaisonEntityDescription *)description forProperty:(NSString *)property
{
    [self.nestedEntityDescriptions setObject:description forKey:property];
}


- (LiaisonEntityDescription *)entityDescriptionForProperty:(NSString *)property
{
    return [self.nestedEntityDescriptions objectForKey:property];
}


#pragma mark - Helpers

- (NSString *)primaryKeyForEntityName
{
    NSMutableString *key = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [self.entityName length]; i++) {
        unichar oneChar = [self.entityName characterAtIndex:i];
        
        if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:oneChar]) {
            [key appendFormat:@"_%C", oneChar];
        } else {
            [key appendFormat:@"%C", oneChar];
        }
    }
    
    if ([key hasPrefix:@"_"]) {
        key = [NSString stringWithFormat:@"%@", [key substringFromIndex:1]];
    }
    
    return [NSString stringWithFormat:@"%@_id", [key lowercaseString]];
}

@end
