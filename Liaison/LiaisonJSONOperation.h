//
//  LiaisonJSONOperation.h
//  Liaison
//
//  Created by Arik Devens on 4/17/13.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "LiaisonEntityDescription.h"


@interface LiaisonJSONOperation : NSObject

@property (nonatomic) NSManagedObjectContext *context;

- (id)initWithJSONPayload:(id)payload
        entityDescription:(LiaisonEntityDescription *)entityDescription
                inContext:(NSManagedObjectContext *)context;
- (void)processPayload;

@end
