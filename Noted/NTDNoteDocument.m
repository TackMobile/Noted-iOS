//
//  NTDNoteDocument.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//TODO: better error handling in callbacks

#include <mach/mach.h>
#include <mach/clock.h>
#include <errno.h>
#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"
#import "NTDNote.h"
#import "NTDCoreDataStore.h"

static NSString *const FileExtension = @"txt";
static NSString *const DatabaseFilename = @".noted.metadata";
static const NSUInteger HeadlineLength = 75;
static const char *NotesDirectoryName = "Notes";
static const char *BackupDirectoryName = "NotesBackup";
static NTDCoreDataStore *sharedDatastore;

@interface NTDNoteDocument ()
@property (nonatomic, strong) NSString *bodyText;
@property (nonatomic, strong) NTDNoteMetadata *metadata;
@end

@implementation NTDNoteDocument

#pragma mark - Helpers
+ (NSURL *)localDocumentsDirectoryURL
{
    static NSURL *localDocumentsDirectoryURL = nil;
    if (localDocumentsDirectoryURL == nil) {
        NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                                                NSUserDomainMask, YES ) objectAtIndex:0];
        localDocumentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectoryPath];
    }
    return localDocumentsDirectoryURL;
}

+ (NSURL *)notesDirectoryURL
{
    NSURL *url = [self localDocumentsDirectoryURL];
    return [url URLByAppendingPathComponent:[NSString stringWithCString:NotesDirectoryName encoding:NSUTF8StringEncoding] isDirectory:YES];
}

+ (NSURL *)backupDirectoryURL
{
    NSURL *url = [self localDocumentsDirectoryURL];
    return [url URLByAppendingPathComponent:[NSString stringWithCString:BackupDirectoryName encoding:NSUTF8StringEncoding] isDirectory:YES];
}

+ (NSURL *)newFileURL
{
    static NSDateFormatter *filenameDateFormatter = nil;
    if (!filenameDateFormatter) {
        NSString *format = @"yyyy-MM-dd HH_mm_ss.SSS";
        filenameDateFormatter = [[NSDateFormatter alloc] init];
        [filenameDateFormatter setDateFormat:format];
    }
    NSString *now = [filenameDateFormatter stringFromDate:[NSDate date]];
    mach_timespec_t mts = ntd_get_time();
    NSString *basename = [NSString stringWithFormat:@"Note %@.%d.%d", now, mts.tv_sec, mts.tv_nsec];
    NSString *filename = [basename stringByAppendingPathExtension:FileExtension];
    return [[self notesDirectoryURL] URLByAppendingPathComponent:filename];
}

mach_timespec_t ntd_get_time()
{
    clock_serv_t cclock;
    mach_timespec_t mts;
    
    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);
    return mts;
}

BOOL safe_rename(const char *old, const char *new)
{
    // http://rcrowley.org/2010/01/06/things-unix-can-do-atomically.html
    int old_fd, new_fd, error;
    
    old_fd = open(old, O_RDONLY);
    if (-1 == old_fd) return NO;
    
    error = rename(old, new);
    if (-1 == error) return NO;
    
    new_fd = open(new, O_RDONLY);
    if (-1 == new_fd) return NO;
    
    error = fsync(old_fd); /* Not sure what to do if we fail here so let's punt for now. */
    error = fsync(new_fd);
    
    return YES;
}

+ (BOOL)safelyMoveItemAtURL:(NSURL *)oldURL toURL:(NSURL *)newURL
{
    const char *oldpath = [[oldURL path] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *newpath = [[newURL path] cStringUsingEncoding:NSUTF8StringEncoding];
    BOOL success = safe_rename(oldpath, newpath);
    if (!success)
        NSLog(@"safe_renamed failed. errno = %d", errno);
    return success;
}

+ (BOOL)restoreFromBackup
{
    if ([NSFileManager.defaultManager fileExistsAtPath:[[self backupDirectoryURL] path]]) {
        // delete current notes directory
        NSError __autoreleasing *error;
        [NSFileManager.defaultManager removeItemAtURL:[self notesDirectoryURL] error:&error];
        if (error) {
            NSLog(@"Couldn't delete current notes directory: %@", error);
            return NO;
        }
        
        // restore from backup
        BOOL didRestore = [self safelyMoveItemAtURL:[self backupDirectoryURL] toURL:[self notesDirectoryURL]];
        if (!didRestore) {
            NSLog(@"Couldn't restore from backup?!");
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (BOOL)createNotesDirectory
{
    NSError __autoreleasing *error;
    BOOL success = [NSFileManager.defaultManager createDirectoryAtURL:[self notesDirectoryURL]
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error];
    if (!success) {
        NSLog(@"Couldn't create notes directory: %@", error);
    }
    return success;
}

+ (instancetype)documentFromMetadata:(NTDNoteMetadata *)metadata
{
    NSURL *fileURL = [[self notesDirectoryURL] URLByAppendingPathComponent:metadata.filename];
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:fileURL];
    document.metadata = metadata;
    return document;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    return [sharedDatastore persistingManagedObjectContext];
}

+ (NTDNoteDefaultCompletionHandler)handlerDispatchedToMainQueue:(NTDNoteDefaultCompletionHandler)handler
{
    return ^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) handler(success);
        });
    };
}

#pragma mark - UIDocument
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    if ([contents length] > 0) {
        self.bodyText = [[NSString alloc] initWithData:(NSData *)contents encoding:NSUTF8StringEncoding];
    } else {
//        NSLog(@"INFO: Opening empty file.");
        self.bodyText = @"";
    }
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    if (!self.bodyText) {
        self.bodyText = @"";
    }
    NSData *docData = [self.bodyText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    return docData;
}

- (BOOL)writeContents:(id)contents toURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError **)outError
{
    BOOL didSaveFile = [super writeContents:contents
                                      toURL:url
                           forSaveOperation:saveOperation
                        originalContentsURL:originalContentsURL
                                      error:outError];
    if (!didSaveFile) {
        NSLog(@"WARNING: Couldn't save file: %@", *outError);
        return NO;
    }
    
    NSManagedObjectContext *context = [[self class] managedObjectContext];
    __block BOOL didSaveMetadata = YES;
    [context performBlockAndWait:^{
        self.metadata.lastModifiedDate = [NSDate date];
        [context save:outError];
        if (*outError) {
            NSLog(@"WARNING: Couldn't save metadata: %@", *outError);
            [self revertToContentsOfURL:originalContentsURL completionHandler:NULL];
            didSaveMetadata = NO;
        }
    }];
    return didSaveMetadata;
}

#pragma mark - NTDNote
+ (void)initialize
{
    [self createNotesDirectory];
    if ([self restoreFromBackup])
        NSLog(@"Successfully restored from backup.");
    NSURL *databaseURL = [[self notesDirectoryURL] URLByAppendingPathComponent:DatabaseFilename];
    sharedDatastore = [NTDCoreDataStore datastoreWithURL:databaseURL];
}

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *))handler
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NTDNoteMetadata"];
    NSSortDescriptor *filenameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:NO];
    fetchRequest.sortDescriptors = @[filenameSortDescriptor];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (results == nil) NSLog(@"WARNING: Couldn't fetch list of notes!");
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[results count]];
    for (NTDNoteMetadata *metadata in results) {
        [notes addObject:[self documentFromMetadata:metadata]];
    }
    handler(notes);
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:[self newFileURL]];
    document.metadata = [NSEntityDescription insertNewObjectForEntityForName:@"NTDNoteMetadata"
                                                      inManagedObjectContext:[self managedObjectContext]];
    document.metadata.filename = [document.fileURL lastPathComponent];
    document.metadata.lastModifiedDate = [NSDate date];
    [document saveToURL:document.fileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          if (success) {
              handler((NTDNote *)document /* Shhh... */);
          } else {
              NSLog(@"WARNING: Couldn't create new note!");
              handler(nil);
          };
      }];
}

+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [self handlerDispatchedToMainQueue:handler];
    
    // lock PSC
    [[sharedDatastore persistentStoreCoordinator] lock];

    // move current notes directory to backup
    NSAssert(![NSFileManager.defaultManager fileExistsAtPath:[[self backupDirectoryURL] path]],
             @"Backup should have been restored on app launch. Are you trying to do a backup while doing a backup?");
    BOOL didBackup = [self safelyMoveItemAtURL:[self notesDirectoryURL] toURL:[self backupDirectoryURL]];
    
    // unlock PSC
    [[sharedDatastore persistentStoreCoordinator] unlock];
    
    // quit if file operations failed
    if (!didBackup || ![self createNotesDirectory]) {
        handler(NO);
        return;
    }
    
    // reset PSC
    [sharedDatastore resetStore];

    handler(YES);
}

+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [self handlerDispatchedToMainQueue:handler];
    
//    // delete store
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError __autoreleasing *error;
//
//    [[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] lock];
//    NSPersistentStore *mainStore = [[[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] persistentStores] objectAtIndex:0];
//    [fileManager removeItemAtURL:[mainStore URL] error:&error];
//    if (error) {
//        NSLog(@"Couldn't delete persistent store: %@", error);
//        handler(NO);
//        return;
//    }
    
    // nil PSC
    [[sharedDatastore persistentStoreCoordinator] unlock];
    [sharedDatastore resetStore];

    // lock PSC
    [[sharedDatastore persistentStoreCoordinator] lock];
    
    BOOL didRestore = [self restoreFromBackup];
    
    // unlock PSC
    [[sharedDatastore persistentStoreCoordinator] unlock];

    if (!didRestore) {
        handler(NO);
        return;
    }

    // reset PSC
    [sharedDatastore resetStore];

    handler(YES);
}

- (void)deleteWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    NSManagedObjectContext *context = [[self class] managedObjectContext];
    __block BOOL didDeleteMetadata;
    [context performBlockAndWait:^{
        [context deleteObject:self.metadata];
        didDeleteMetadata = [context save:nil];
    }];
    if (didDeleteMetadata) {
        self.metadata = nil;
    } else {
        NSLog(@"WARNING: Couldn't delete metadata!");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) completionHandler(NO);
        });
        return;
    }
    
    NSURL *fileURL = self.fileURL;
    [self performAsynchronousFileAccessUsingBlock:^{
        NSError __autoreleasing *error;
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:fileURL
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:&error
                                         byAccessor:^(NSURL* writingURL) {
                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             [fileManager removeItemAtURL:writingURL error:nil];
                                         }];
        BOOL success = !error;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) completionHandler(success);
        });
    }];
}

- (NSString *)filename
{
    return self.metadata.filename;
}

- (NSString *)headline
{
    return self.metadata.headline;
}

- (NSDate *)lastModifiedDate
{
    return self.metadata.lastModifiedDate;
}

- (NTDNoteFileState)fileState
{
    switch (self.documentState) {
        case UIDocumentStateNormal:
            return NTDNoteFileStateOpened;
        case UIDocumentStateClosed:
            return NTDNoteFileStateClosed;
        default:
            return NTDNoteFileStateError;
    }
}

- (NTDTheme *)theme
{
    return [NTDTheme themeForColorScheme:self.metadata.colorScheme];
}

- (NSString *)text
{
    return self.bodyText;
}

// Needs to: update change count; maybe notify app
- (void)setTheme:(NTDTheme *)theme
{
    if (theme.colorScheme != self.metadata.colorScheme) {
        self.metadata.colorScheme = theme.colorScheme;
        [self updateChangeCount:UIDocumentChangeDone];
    }
}
 
// Needs to: update change count; maybe notify app; update headline
- (void)setText:(NSString *)text
{
    if (![text isEqualToString:self.bodyText]) {
        self.bodyText = text;
        if (text.length < HeadlineLength) {
            self.metadata.headline = text;
        } else {
            self.metadata.headline = [text substringToIndex:HeadlineLength];
        }
        [self updateChangeCount:UIDocumentChangeDone];
    }
}
@end
