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
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (NTDCoreDataStore *) sharedStore;

@end
