//
//  NTDNoteDocument.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//TODO: better error handling in callbacks

#include <errno.h>
#import <FlurrySDK/Flurry.h>
#import <Crashlytics/Crashlytics.h>
#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"
#import "NTDNote.h"
#import "NTDCoreDataStore.h"

static NSString *const FileExtension = @"txt";
static NSString *const DatabaseFilename = @".noted.metadata";
static const char *NotesDirectoryName = "Notes";
static const char *BackupDirectoryName = "NotesBackup";
static NTDCoreDataStore *sharedDatastore;
static const NSUInteger HeadlineLength = 280;
static NSUInteger filenameCounter = 1;

@interface NTDNoteDocument ()
@property (nonatomic, strong) NSString *bodyText;
@property (nonatomic, strong) NTDNoteMetadata *metadata;
@property (nonatomic, assign) BOOL isOpenOperationInFlight, wasClosed;
@property (nonatomic, strong) NSMutableArray *pendingOpenOperations;
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
    NSURL *url;
    do
    {
        NSString *basename = [NSString stringWithFormat:@"Note %d", filenameCounter];
        NSString *filename = [basename stringByAppendingPathExtension:FileExtension];
        url = [[self notesDirectoryURL] URLByAppendingPathComponent:filename];
        filenameCounter++;
    }
    while ([NSFileManager.defaultManager fileExistsAtPath:[url path]]);
    
    return url;
}

+ (NSUInteger)indexFromFilename:(NSString *)filename
{
    /* Depends on filename structure as defined by +newFileURL */
    static NSUInteger NilIndex = 0;
    static NSRegularExpression *matcher;
    if (!matcher) {
        NSError __autoreleasing *error;
        matcher = [NSRegularExpression regularExpressionWithPattern:@"^Note ([0-9]+)$"
                                                            options:0
                                                              error:&error];
        if (error) return NilIndex;
    }
    
    filename = [filename stringByDeletingPathExtension];
    if (!filename || 0==filename.length) return NilIndex;

    NSTextCheckingResult *result = [matcher firstMatchInString:filename options:0 range:[filename rangeOfString:filename]];
    if (!result) return NilIndex;

    NSRange range = [result rangeAtIndex:1];
    if (NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) {
        return NilIndex;
    } else {
        return [[filename substringWithRange:range] integerValue];
    }    
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
    if (!success) {
        NSString *errorMsg = [NSString stringWithFormat:@"safe_rename failed. errno = %d", errno];
        NSLog(@"%@", errorMsg);
        [Flurry logError:@"safe_rename() failure" message:errorMsg error:nil];
    }
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
            [Flurry logError:@"Couldn't delete current notes directory" message:[error localizedDescription] error:error];
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
        [Flurry logError:@"Couldn't create notes directory" message:[error localizedDescription] error:error];
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

+ (NTDNoteDefaultCompletionHandler)nonNilHandler:(NTDNoteDefaultCompletionHandler)handler
{
    return ^(BOOL success) {
        if (handler) handler(success);
    };
}

#pragma mark - UIDocument
- (id)initWithFileURL:(NSURL *)url
{
    if (self = [super initWithFileURL:url]) {
        self.pendingOpenOperations = [NSMutableArray new];
    }
    return self;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    if ([contents length] > 0) {
        self.bodyText = [[NSString alloc] initWithData:(NSData *)contents encoding:NSUTF8StringEncoding];
    } else {
//        NSLog(@"INFO: Opening empty file.");
        self.bodyText = @"";
        self.metadata.headline = @"";
    }
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    if (!self.bodyText) {
        self.bodyText = @"";
        self.metadata.headline = @"";
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
        [Flurry logError:@"Couldn't save file" message:[*outError localizedDescription] error:*outError];
        return NO;
    }
    
    NSManagedObjectContext *context = [[self class] managedObjectContext];
    __block BOOL didSaveMetadata = YES;
    typeof(self) __weak weakSelf = self;
    [context performBlockAndWait:^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            didSaveMetadata = NO;
            return;
        }
        strongSelf.metadata.lastModifiedDate = [NSDate date];
        [context save:outError];
        if (*outError) {
            NSLog(@"WARNING: Couldn't save metadata: %@", *outError);
            [Flurry logError:@"Couldn't save metadata" message:[*outError localizedDescription] error:*outError];
            [strongSelf revertToContentsOfURL:originalContentsURL completionHandler:NULL];
            didSaveMetadata = NO;
        }
    }];
    return didSaveMetadata;
}

-(void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    /* This code depends on the following:
     * - It's only run on the main thread. It's not designed for concurrency.
     * - -[super openWithCompletionHandler:] executes the completion handler even if the file is open. (Verified on iOS v6.1.3 & 7.0.2)
     *
     * It may be useful to note that self.documentState == UIDocumentStateNormal inside the completion handler.
     */
    
    NSAssert([NSThread isMainThread], @"%s MUST be called from main thread.", __PRETTY_FUNCTION__);
    
    completionHandler = [NTDNoteDocument nonNilHandler:completionHandler];
    
    // If the document is already open, skip this rigmarole.
    if (self.documentState & UIDocumentStateNormal) {
        completionHandler(YES);
        return;
    }
    
    // If the document has been closed, it's bad UIDocument mojo to open it again.
    if (self.wasClosed) {
        completionHandler(NO);
        return;
    }
    
    if (completionHandler != NULL) {
        [self.pendingOpenOperations addObject:completionHandler];
    }
    
    if (!self.isOpenOperationInFlight) {
        self.isOpenOperationInFlight = YES;
        typeof(self) __weak weakSelf = self;
        [super openWithCompletionHandler:^(BOOL success) {
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            strongSelf.isOpenOperationInFlight = NO;
            NSArray *operations = [strongSelf.pendingOpenOperations copy];
            for (void(^handler)(BOOL success) in operations) {
                handler(success);
            }
            [strongSelf.pendingOpenOperations removeObjectsInArray:operations];
        }];
    }
}

/* NOTE: If the documentState of the file is UIDocumentStateClosed, the completion handler is not called.
 * We override this method to manually invoke the completion handler.
 */
-(void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    completionHandler = [NTDNoteDocument nonNilHandler:completionHandler];
    if (self.wasClosed) {
        completionHandler(NO);
        return;
    }
    
    // We need to wrap the close here so that it serializes with any in-flight opens.
    // NOTE: I'm kind of assuming that this block runs on a serial queue.
    [self performAsynchronousFileAccessUsingBlock:^{
        self.wasClosed = YES; // It's fine to prevent in-flight closes.
        if (self.documentState & UIDocumentStateClosed)
            completionHandler(YES);
        else {
            [super closeWithCompletionHandler:completionHandler];
        }
    }];
}

#pragma mark - NTDNote
+ (void)initialize
{
    [self createNotesDirectory];
    if ([self restoreFromBackup]) {
        NSLog(@"Successfully restored from backup.");
        [Flurry logError:@"Restored from Backup" message:nil error:nil];
    }
    NSURL *databaseURL = [[self notesDirectoryURL] URLByAppendingPathComponent:DatabaseFilename];
    sharedDatastore = [NTDCoreDataStore datastoreWithURL:databaseURL];
}

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *))handler
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NTDNoteMetadata"];
    NSSortDescriptor *filenameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:NO];
    fetchRequest.sortDescriptors = @[filenameSortDescriptor];
    NSError __autoreleasing *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (results == nil) {
        NSLog(@"WARNING: Couldn't fetch list of notes!");
        [Flurry logError:@"Couldn't fetch list of notes" message:[error localizedDescription] error:error];
    }

    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[results count]];
    for (NTDNoteMetadata *metadata in results) {
        [notes addObject:[self documentFromMetadata:metadata]];
        filenameCounter = MAX(filenameCounter, [self indexFromFilename:metadata.filename]);
    }

    [notes sortUsingComparator:^NSComparisonResult(NTDNoteMetadata *metadata1, NTDNoteMetadata *metadata2) {
        NSUInteger i = [self indexFromFilename:metadata1.filename];
        NSUInteger j = [self indexFromFilename:metadata2.filename];
        
        if (i > j) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if (i < j) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];

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
              [Flurry logEvent:@"Note Created" withParameters:@{@"counter" : @(filenameCounter-1)}];
              handler((NTDNote *)document /* Shhh... */);
          } else {
              NSLog(@"WARNING: Couldn't create new note!");
              [Flurry logError:@"Couldn't create new note" message:nil error:nil];
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
    [self closeWithCompletionHandler:^(BOOL success) {
       if (success)
           [self actuallyDeleteWithCompletionHandler:completionHandler];
        else
            [NTDNoteDocument handlerDispatchedToMainQueue:completionHandler](NO);
    }];
}

- (void)actuallyDeleteWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    completionHandler = [NTDNoteDocument handlerDispatchedToMainQueue:completionHandler];
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
        [Flurry logError:@"Couldn't delete metadata" message:nil error:nil];
        completionHandler(NO);
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
        if (success) [Flurry logEvent:@"Note Deleted"];
        completionHandler(success);
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
