//
//  LiaisonEntityDescription.m
//  Liaison
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonEntityDescription.h"


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
    entityDescription.block = ^(NSManagedObjectContext *localContext, NSSet *processObjects) {
    };
    
    return entityDescription;
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
