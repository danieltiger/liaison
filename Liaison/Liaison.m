//
//  Liaison.m
//  Liaison
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import "Liaison.h"
#import "LiaisonJSONOperation.h"


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
    if (![payload isKindOfClass:[NSArray class]]) {
        DLog(@"Payload must be an array. Bailing.");
        
        return;
    }
    
    [self saveDataInBackgroundWithContext:^(NSManagedObjectContext *localContext) {
        LiaisonJSONOperation *JSONOperation = [[LiaisonJSONOperation alloc] initWithJSONPayload:payload
                                                                              entityDescription:entityDescription
                                                                                      inContext:localContext];
        [JSONOperation processPayload];
        
        NSSet *updatedObjects = [localContext updatedObjects];
        NSSet *insertedObjects = [localContext insertedObjects];
        
        NSMutableSet *processObjects = [NSMutableSet setWithSet:updatedObjects];
        [processObjects unionSet:insertedObjects];
        
        entityDescription.block(localContext, processObjects);
    } completion:completion];
}

@end
