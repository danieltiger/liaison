//
//  Liaison.m
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "Liaison.h"
#import "LiaisonJSONProcessor.h"


@interface Liaison()
@property NSManagedObjectContext *mainContext;
@property NSManagedObjectContext *saveContext;
@end


@implementation Liaison

#pragma mark - Designated Initializer

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    self = [super init];
    
    if (self != nil) {
        self.mainContext = managedObjectContext;

        self.saveContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];;
        self.saveContext.parentContext = self.mainContext;
        [self.saveContext setUndoManager:nil];
    }
    
    return self;
}


#pragma mark - API

- (void)saveDataInBackgroundWithContext:(void(^)(NSManagedObjectContext *))saveBlock
                             completion:(void(^)(void))completion
{
    [self.saveContext performBlock:^{
        saveBlock(self.saveContext);
        
        if (self.saveContext.hasChanges) [self.saveContext save:nil];
        
        [self.mainContext performBlock:^{
            [self.mainContext save:nil];
            
            if (completion) completion();
        }];
    }];
}


- (void)processJSONPayload:(id)payload
     withEntityDescription:(LiaisonEntityDescription *)entityDescription
                completion:(void(^)(void))completion
{
    if ([payload isKindOfClass:[NSDictionary class]] == YES) {
        NSArray *payloadWrapper = @[payload];
        
        payload = payloadWrapper;
    }
    
    NSAssert([payload isKindOfClass:[NSArray class]], @"Payload must be an NSArray.");
    
    [self saveDataInBackgroundWithContext:^(NSManagedObjectContext *localContext) {
        LiaisonJSONProcessor *JSONOperation = [[LiaisonJSONProcessor alloc] initWithJSONPayload:payload
                                                                              entityDescription:entityDescription
                                                                                      inContext:localContext];
        [JSONOperation processPayload];
        
        NSSet *updatedObjects = [localContext updatedObjects];
        NSSet *insertedObjects = [localContext insertedObjects];
        
        NSMutableSet *processObjects = [NSMutableSet setWithSet:updatedObjects];
        [processObjects unionSet:insertedObjects];
        
        entityDescription.postProcessingBlock(localContext, processObjects);
    } completion:completion];
}

@end
