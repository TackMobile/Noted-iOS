//
//  NTDCoreDataStore.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCoreDataStore.h"

static NSString *const ModelFilename = @"NTDNoteMetadata";
static NSString *const DatabaseFilename = @"metadata";

@implementation NTDCoreDataStore

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Singleton
+ (NTDCoreDataStore *) sharedStore
{
    static NTDCoreDataStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NTDCoreDataStore alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Core Data
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
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

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:ModelFilename withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    static BOOL didDeleteExistingStore = NO;
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSString *dbFilename = [NSString stringWithFormat:@"%@.db", DatabaseFilename];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:dbFilename];
    [self copyInitialStoreToURLIfNecessary:storeURL];
    
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

- (void)copyInitialStoreToURLIfNecessary:(NSURL *)storeURL
{
    NSString *storePath = [storeURL path];
    NSString *initialStoreName = [NSString stringWithFormat:@"%@.initial", DatabaseFilename];
    NSString *initialStorePath = [[NSBundle mainBundle] pathForResource:initialStoreName ofType:@"db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:initialStorePath] && ![fileManager fileExistsAtPath:storePath]) {
        NSError __autoreleasing *error;
        [fileManager copyItemAtPath:initialStorePath toPath:storePath error:&error];
        if (error)
            NSLog(@"Couldn't copy initial DB: %@", error);
        else
            NSLog(@"Copied initial DB.");
    }
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
