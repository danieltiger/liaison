//
//  LiaisonEntityDescription.h
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import <CoreData/CoreData.h>


typedef void(^LiaisonEntityDescriptionBlock)(NSManagedObjectContext *localContext, NSSet *processObjects);


@interface LiaisonEntityDescription : NSObject

@property (strong, nonatomic) LiaisonEntityDescriptionBlock postProcessingBlock;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSString *relationshipName;
@property (strong, nonatomic) NSString *primaryKey;
@property (nonatomic) BOOL isJoinTable;
@property (strong, nonatomic) LiaisonEntityDescription *leftRelationshipEntityDescription;
@property (strong, nonatomic) LiaisonEntityDescription *rightRelationshipEntityDescription;

+ (LiaisonEntityDescription *)descriptionForEntityName:(NSString *)entityName
                                       andRelationship:(NSString *)relationshipName;

- (void)markPropertyAsDate:(NSString *)propertyName;
- (NSArray *)propertiesMarkedAsDate;
- (void)setEntityDescription:(LiaisonEntityDescription *)description forProperty:(NSString *)property;
- (LiaisonEntityDescription *)entityDescriptionForProperty:(NSString *)property;

@end
