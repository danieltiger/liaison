//
//  LiaisonJSONProcessor.h
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "LiaisonEntityDescription.h"


@interface LiaisonJSONProcessor : NSObject

@property (nonatomic) NSManagedObjectContext *context;

- (id)initWithJSONPayload:(id)payload
        entityDescription:(LiaisonEntityDescription *)entityDescription
                inContext:(NSManagedObjectContext *)context;
- (void)processPayload;

@end
