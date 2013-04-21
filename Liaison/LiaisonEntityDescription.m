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
    LiaisonEntityDescription *description = [[LiaisonEntityDescription alloc] init];
    
    description.entityName = entityName;
    description.primaryKey = [description primaryKeyForEntityName];
    description.relationshipName = relationshipName;
    description.isJoinTable = NO;
    description.postProcessingBlock = ^(NSManagedObjectContext *localContext, NSSet *processObjects) {
    };
    
    description.dateProperties = [NSMutableArray array];
    description.nestedEntityDescriptions = [NSMutableDictionary dictionary];
    
    return description;
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
    
    if ([key hasPrefix:@"_"]) key = [NSString stringWithFormat:@"%@", [key substringFromIndex:1]];
    
    return [NSString stringWithFormat:@"%@_id", [key lowercaseString]];
}

@end
