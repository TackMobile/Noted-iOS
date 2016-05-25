//
//  NTDCoreDataStore.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NTDCoreDataStore : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *persistingManagedObjectContext;

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (NTDCoreDataStore *) datastoreWithURL:(NSURL *)dbURL;
- (void)resetStore;

@end
