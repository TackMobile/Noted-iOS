//
//  NTDCoreDataStore.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <FlurrySDK/Flurry.h>
#import "NTDCoreDataStore.h"

static NSString *const ModelFilename = @"NTDNoteMetadata";

@interface NTDCoreDataStore ()
@property (nonatomic, strong) NSURL *databaseURL;
@end

@implementation NTDCoreDataStore

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (NTDCoreDataStore *)datastoreWithURL:(NSURL *)dbURL
{
    NTDCoreDataStore *store = [NTDCoreDataStore new];
    store.databaseURL = dbURL;
    return store;
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)persistingManagedObjectContext
{
    return self.managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:ModelFilename withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    static BOOL didDeleteExistingStore = NO;
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = self.databaseURL;
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@TRUE, NSInferMappingModelAutomaticallyOption:@TRUE};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        
        if (error.code != NSPersistentStoreIncompatibleVersionHashError && error.code == NSMigrationMissingSourceModelError) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [Flurry logError:@"Error loading DB" message:[error localizedDescription] error:error];
        }
        
        if (!didDeleteExistingStore) {
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
            _persistentStoreCoordinator = nil;
            didDeleteExistingStore = YES;
            return self.persistentStoreCoordinator;
        } else {
            // If we deleted the existing store and we still can't create a new one, abort.
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)resetStore
{
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
}

@end
