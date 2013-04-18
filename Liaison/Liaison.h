//
//  Liaison.h
//  Liaison
//
//  Created by Arik Devens on 11/21/12.
//  Copyright (c) 2013 Arik Devens. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "LiaisonEntityDescription.h"


@interface Liaison : NSObject

- (void)saveDataInBackgroundWithContext:(void(^)(NSManagedObjectContext *))saveBlock
                             completion:(void(^)(void))completion;
- (void)processJSONPayload:(id)payload
     withEntityDescription:(LiaisonEntityDescription *)entityDescription
                completion:(void(^)(void))completion;

@end
