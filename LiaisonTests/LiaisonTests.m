//
//  LiaisonTests.m
//  LiaisonTests
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonTests.h"
#import "LiaisonEntityDescription.h"


static NSString *kAuthor = @"Author";
static NSString *kAuthorRelationshop = @"authors";


@implementation LiaisonTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}


#pragma mark - Entity Description

- (void)testEntityDescription
{
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationshop];
    
    STAssertNotNil(desc, @"Should have built an entity description.");
    STAssertEqualObjects(desc.entityName, kAuthor, @"Entity name should have been set.");
    STAssertEqualObjects(desc.primaryKey, @"author_id", @"Primary key should be correctly inferred.");
    STAssertEqualObjects(desc.relationshipName, kAuthorRelationshop, @"Relationship should have been correctly set.");
    STAssertFalse(desc.isJoinTable, @"Should not be a join table");
}


- (void)testDateProperties
{
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationshop];
    
    [desc markPropertyAsDate:@"created_at"];
    [desc markPropertyAsDate:@"updated_at"];
    
    NSArray *dateProperties = [desc propertiesMarkedAsDate];
    
    STAssertTrue(dateProperties.count == 2, @"Should have two properties marked as dates.");
}

@end
