//
//  LiaisonJSONProcessor.m
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonJSONProcessor.h"
#import "LiaisonJSONProcessor+Sanitization.h"


@interface LiaisonJSONProcessor()
@property (nonatomic) id payload;
@property (nonatomic) LiaisonEntityDescription *entityDescription;
@end


@implementation LiaisonJSONProcessor

#pragma mark - Designated Intializer

- (id)initWithJSONPayload:(id)payload
        entityDescription:(LiaisonEntityDescription *)description
                inContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self != nil) {
        self.payload = payload;
        self.entityDescription = description;
        self.context = context;
    }
    
    return self;
}


- (void)processPayload
{
    if (self.entityDescription.isJoinTable == YES) {
        [self processJoinTableJSONPayload:self.payload
                    withEntityDescription:self.entityDescription
                                inContext:self.context];
        
        return;
    }

    [self processJSONPayload:self.payload
       withEntityDescription:self.entityDescription
                   inContext:self.context];
}


#pragma mark - Helpers

- (NSManagedObject *)findOrCreateObjectForEntityDescription:(LiaisonEntityDescription *)description
                                        withPrimaryKeyValue:(id)primaryKeyValue
                                                  inContext:(NSManagedObjectContext *)context
{
    if ([primaryKeyValue isKindOfClass:[NSNull class]]) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:description.entityName inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"SELF.%@ == %@", description.primaryKey, primaryKeyValue]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
    if (error != nil) {
        NSLog(@"findOrCreateObjectForEntityDescription: Unresolved error %@, %@", error, [error userInfo]);
    }
    
    if (fetchedObjects.count == 0) {
        NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:description.entityName
                                                                   inManagedObjectContext:context];
        
        [newObject setValue:primaryKeyValue forKey:description.primaryKey];
        
        return newObject;
    } else if (fetchedObjects.count == 1) {
        NSManagedObject *existingObject = [fetchedObjects objectAtIndex:0];
        
        return existingObject;
    }
    
    return nil;
}


- (void)processJSONDictionary:(NSDictionary *)dictionary andAssignValuesToObject:(NSManagedObject *)object
{
    for (id property in dictionary) {
        id value = [dictionary valueForKey:property];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            [self processJSONDictionary:value andAssignValuesToObject:object];
        } else {
            if ([value isKindOfClass:[NSNull class]]) continue;
            
            [object setValue:value forKey:property];
        }
    }
}


- (NSMutableSet *)relationshipObjectsForJSONDictionary:(NSDictionary *)dictionary
                                 withEntityDescription:(LiaisonEntityDescription *)entityDescription
                                             inContext:(NSManagedObjectContext *)context
{
    NSMutableSet *relationshipSet = [[NSMutableSet alloc] init];
    
    for (NSString *property in dictionary) {
        if ([property hasSuffix:@"_id"]) {
            NSString *relationshipEntityName = [self entityNameForProperty:property];
            NSEntityDescription *description = [NSEntityDescription entityForName:entityDescription.entityName
                                                           inManagedObjectContext:context];
            NSEntityDescription *relationshipEntity = [NSEntityDescription entityForName:relationshipEntityName
                                                                  inManagedObjectContext:context];
            
            NSArray *relationships = [description relationshipsWithDestinationEntity:relationshipEntity];
            if (relationships.count <= 0) continue;
            
            id primaryKeyValue = [dictionary valueForKey:property];
            NSString *entityName = [self entityNameForProperty:property];
            
            LiaisonEntityDescription *entityDescription = [LiaisonEntityDescription descriptionForEntityName:entityName
                                                                                             andRelationship:nil];
            NSManagedObject *managedObject = [self findOrCreateObjectForEntityDescription:entityDescription
                                                                      withPrimaryKeyValue:primaryKeyValue
                                                                                inContext:context];
            if (!managedObject) continue;
            
            [relationshipSet addObject:managedObject];
        }
    }
    
    return relationshipSet;
}


- (void)processRelationshipsForObject:(NSManagedObject *)collectionObject
                   withJSONDictionary:(NSDictionary *)dictionary
                 andEntityDescription:(LiaisonEntityDescription *)description
                            inContext:(NSManagedObjectContext *)context
{
    NSMutableSet *relationshipSet = [self relationshipObjectsForJSONDictionary:dictionary
                                                         withEntityDescription:description
                                                                     inContext:context];
    
    for (NSManagedObject *object in relationshipSet) {
        NSDictionary *relationships = [object.entity relationshipsByName];
        NSRelationshipDescription *relationshipDescription = [relationships objectForKey:description.relationshipName];
        
        if (relationshipDescription.isToMany) {
            NSMutableSet *relationshipObjects = [object mutableSetValueForKey:description.relationshipName];
            
            NSSet *objectsToAdd = [NSSet setWithObject:collectionObject];
            
            [relationshipObjects unionSet:objectsToAdd];
        } else {
            [object setValue:collectionObject forKey:description.relationshipName];
        }
    }
}


- (void)processRelationshipsForJSONDictionary:(NSDictionary *)dictionary
                                      forMany:(LiaisonEntityDescription *)leftEntityDescription
                                       toMany:(LiaisonEntityDescription *)rightEntityDescription
                                    inContext:(NSManagedObjectContext *)context
{
    NSString *leftPrimaryKeyValue = [dictionary objectForKey:leftEntityDescription.primaryKey];
    NSString *rightPrimaryKeyValue = [dictionary objectForKey:rightEntityDescription.primaryKey];
    
    NSManagedObject *leftCollectionObject = [self findOrCreateObjectForEntityDescription:leftEntityDescription
                                                                     withPrimaryKeyValue:leftPrimaryKeyValue
                                                                               inContext:context];
    NSManagedObject *rightCollectionObject = [self findOrCreateObjectForEntityDescription:rightEntityDescription
                                                                      withPrimaryKeyValue:rightPrimaryKeyValue
                                                                                inContext:context];
    
    NSMutableSet *leftRelationshipObjects = [leftCollectionObject mutableSetValueForKey:rightEntityDescription.relationshipName];
    NSMutableSet *rightRelationshipObjects = [rightCollectionObject mutableSetValueForKey:leftEntityDescription.relationshipName];
    
    if (leftCollectionObject == nil || rightCollectionObject == nil) return;
    
    NSSet *leftObjectToAdd = [NSSet setWithObject:rightCollectionObject];
    NSSet *rightObjectToAdd = [NSSet setWithObject:leftCollectionObject];
    
    [leftRelationshipObjects unionSet:leftObjectToAdd];
    [rightRelationshipObjects unionSet:rightObjectToAdd];
}


- (NSArray *)processJSONPayload:(id)payload
          withEntityDescription:(LiaisonEntityDescription *)description
                      inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dictionary in payload) {
        if (![dictionary isKindOfClass:[NSDictionary class]]) continue;
        
        NSDictionary *sanitizedDictionary = [self sanitizeJSONDictionary:dictionary
                                                    forEntityDescription:description];
        
        id primaryKeyValue = [sanitizedDictionary objectForKey:description.primaryKey];
        
        NSManagedObject *collectionObject = [self findOrCreateObjectForEntityDescription:description
                                                                     withPrimaryKeyValue:primaryKeyValue
                                                                               inContext:context];
        if (!collectionObject) continue;
        
        [self processJSONDictionary:sanitizedDictionary andAssignValuesToObject:collectionObject];
        [self processRelationshipsForObject:collectionObject
                         withJSONDictionary:dictionary
                       andEntityDescription:description
                                  inContext:context];
        
        [objects addObject:collectionObject.objectID];
    }
    
    return objects;
}


- (void)processJoinTableJSONPayload:(id)payload
              withEntityDescription:(LiaisonEntityDescription *)description
                          inContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *dictionary in payload) {
        if (![dictionary isKindOfClass:[NSDictionary class]]) continue;
        
        NSDictionary *sanitizedDictionary = [self sanitizeJSONDictionaryForJoinTable:dictionary];
        
        [self processRelationshipsForJSONDictionary:sanitizedDictionary
                                            forMany:description.leftRelationshipEntityDescription
                                             toMany:description.rightRelationshipEntityDescription
                                          inContext:context];
    }
}

@end
