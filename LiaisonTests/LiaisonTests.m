//
//  LiaisonTests.m
//  LiaisonTests
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "LiaisonTests.h"
#import <CoreData/CoreData.h>
#import "Liaison.h"
#import "LiaisonEntityDescription.h"
#import "LiaisonJSONProcessor+Sanitization.h"


static NSString *kAuthor = @"Author";
static NSString *kAuthorRelationship = @"author";
static NSString *kPublisher = @"Publisher";
static NSString *kPublisherRelationship = @"publisher";
static NSString *kBook = @"Book";
static NSString *kBookRelationship = @"books";


@interface LiaisonTests()
@property (nonatomic) NSPersistentStoreCoordinator *coord;
@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSManagedObjectModel *model;
@property (nonatomic) NSPersistentStore *store;
@property (nonatomic) Liaison *liaison;
@end


@implementation LiaisonTests

- (void)setUp
{
    [super setUp];
    
    NSBundle *testBundle = [NSBundle bundleForClass:[LiaisonTests class]];
    NSString *modelURL = [testBundle pathForResource:@"LiaisonTestModel"
                                          ofType:@"momd"];
    NSURL *storeURL = [[testBundle resourceURL] URLByAppendingPathComponent:@"LiaisonTests.sqlite"];
    
    self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL URLWithString:modelURL]];
    
    STAssertNotNil(self.model, @"Managed Object Model should exist");
    
    self.coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    
    NSError *error = nil;
    self.store = [self.coord addPersistentStoreWithType:NSSQLiteStoreType
                                          configuration:nil
                                                    URL:storeURL
                                                options:nil
                                                  error:&error];
    
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.context setPersistentStoreCoordinator:self.coord];
    
    self.liaison = [[Liaison alloc] init];
}


- (void)tearDown
{
    self.context = nil;
    
    NSError *error = nil;
    STAssertTrue([self.coord removePersistentStore:self.store error:&error],
                 @"Couldn't remove persistent store: %@", error);
    
    NSBundle *testBundle = [NSBundle bundleForClass:[LiaisonTests class]];
    NSURL *storeURL = [[testBundle resourceURL] URLByAppendingPathComponent:@"LiaisonTests.sqlite"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (storeURL) {
        [fileManager removeItemAtURL:storeURL error:NULL];
    }
    
    [super tearDown];
}


#pragma mark - Entity Description

- (void)testEntityDescription
{
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationship];
    
    STAssertNotNil(desc, @"Should have built an entity description.");
    STAssertEqualObjects(desc.entityName, kAuthor, @"Entity name should have been set.");
    STAssertEqualObjects(desc.primaryKey, @"author_id", @"Primary key should be correctly inferred.");
    STAssertEqualObjects(desc.relationshipName, kAuthorRelationship, @"Relationship should have been correctly set.");
    STAssertFalse(desc.isJoinTable, @"Should not be a join table");
}


- (void)testDateProperties
{
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationship];
    
    [desc markPropertyAsDate:@"created_at"];
    [desc markPropertyAsDate:@"updated_at"];
    
    NSArray *dateProperties = [desc propertiesMarkedAsDate];
    
    STAssertTrue(dateProperties.count == 2, @"Should have two properties marked as dates.");
}


#pragma mark - Santization

- (void)testDateSanitization
{
    NSDictionary *fakeJSON = @{@"created_at": @"2013-04-17T20:58:42Z"};
    
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationship];
    [desc markPropertyAsDate:@"created_at"];
    
    LiaisonJSONProcessor *processor = [[LiaisonJSONProcessor alloc] initWithJSONPayload:fakeJSON
                                                                      entityDescription:desc
                                                                              inContext:self.context];
    NSDictionary *sanitizedJSON = [processor sanitizeJSONDictionary:fakeJSON forEntityDescription:desc];
    
    STAssertTrue([[sanitizedJSON objectForKey:@"created_at"] isKindOfClass:[NSDate class]],
                 @"Should have transformed created_at string to date.");
}


- (void)testPrimaryKeySanitization
{
    NSDictionary *fakeJSON = @{@"id": @(1)};
    
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationship];
    LiaisonJSONProcessor *processor = [[LiaisonJSONProcessor alloc] initWithJSONPayload:fakeJSON
                                                                      entityDescription:desc
                                                                              inContext:self.context];
    
    NSDictionary *sanitizedJSON = [processor sanitizeJSONDictionary:fakeJSON forEntityDescription:desc];
    
    STAssertNotNil([sanitizedJSON objectForKey:@"author_id"], @"Should have transformed primary key.");
    STAssertEquals([sanitizedJSON objectForKey:@"author_id"], @(1), @"Should have primary key value set.");
}


- (void)testRelationshipsSanitization
{
    NSDictionary *fakeJSON = @{
                               @"publisher_id": @(1),
                               };
    
    LiaisonEntityDescription *desc = [LiaisonEntityDescription descriptionForEntityName:kAuthor
                                                                        andRelationship:kAuthorRelationship];
    LiaisonJSONProcessor *processor = [[LiaisonJSONProcessor alloc] initWithJSONPayload:fakeJSON
                                                                      entityDescription:desc
                                                                              inContext:self.context];
    
    NSDictionary *sanitizedJSON = [processor sanitizeJSONDictionary:fakeJSON
                                               forEntityDescription:desc];
    
    STAssertNil([sanitizedJSON objectForKey:@"publisher_id"],
                @"Should not have publisher_id as it's a relationship");
}

@end
