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
#import <BlocksKit/BlocksKit.h>
#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"
#import "NTDNote.h"
#import "NTDDeletedNotePlaceholder.h"
#import "NTDCoreDataStore.h"

static NSString *const FileExtension = @"txt";
static NSString *const DatabaseFilename = @".noted.metadata";
#if __NOTED_TESTS__
static const char *NotesDirectoryName = "Notes__Test";
static const char *BackupDirectoryName = "NotesBackup__Test";
#else
static const char *NotesDirectoryName = "Notes";
static const char *BackupDirectoryName = "NotesBackup";
#endif

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
    return [self fileURLFromDate:[NSDate date]];
}

+ (NSString *)filenameFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss_A";
    
    NSString *filename = [NSString stringWithFormat:@"Note at %@.txt", [dateFormatter stringFromDate:date]];
    return filename;
}

+ (NSURL *)fileURLFromDate:(NSDate *)date
{
    // try to use the new index. if not, keep incrimenting
    NSURL *url;
    NSString *basename = [NTDNoteDocument filenameFromDate:date];
    NSString *filename = [basename stringByAppendingPathExtension:FileExtension];
    url = [[self notesDirectoryURL] URLByAppendingPathComponent:filename];
    
    return url;
}

+ (BOOL)safelyMoveItemAtURL:(NSURL *)oldURL toURL:(NSURL *)newURL
{
    // this
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

+ (void)removeFilesWithNoMetadata:(NSArray *)notes
{
    NSError __autoreleasing *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self notesDirectoryURL]
                                                   includingPropertiesForKeys:nil
                                                                      options:0
                                                                        error:&error];
    if (!files) {
        NSLog(@"Couldn't get notes from directory! %@", error);
        [Flurry logError:@"Couldn't get notes from directory" message:[error localizedDescription] error:error];
    }
    
    NSMutableArray *_files = [files mutableCopy];
    for (NSURL *fileURL in files) {
        BOOL didMatch = [notes bk_any:^BOOL(NTDNote *note) {
            NSURL *noteURL = [note.fileURL URLByStandardizingPath];
            NSURL *_fileURL = [fileURL URLByStandardizingPath];
            return [noteURL isEqual:_fileURL];
        }];                         
        if (didMatch) [_files removeObject:fileURL];
    }
    for (NSURL *fileURL in _files) {
        if ([[fileURL pathExtension] isEqualToString:FileExtension])
            [NSFileManager.defaultManager removeItemAtURL:fileURL error:nil];
    }
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

+ (BOOL)reset
{
    BOOL success = [NSFileManager.defaultManager removeItemAtURL:self.notesDirectoryURL error:nil];
    success = success && [NSFileManager.defaultManager removeItemAtURL:self.backupDirectoryURL error:nil];
    [sharedDatastore resetStore];
    filenameCounter = 1;
    [self initialize];
    return success;
}

#pragma mark - UIDocument
- (id)initWithFileURL:(NSURL *)url
{
    if (self = [super initWithFileURL:url]) {
        self.pendingOpenOperations = [NSMutableArray new];
        
        //self.metadata = [NTDNoteMetadata alloc];
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
    } else {
        NSLog(@"*** Save - %@", self.filename);
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
        if (strongSelf.metadata.lastModifiedDate != nil)
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
    // For error information
    NSError __autoreleasing *error;
    
    // Create a fetch request for metadata
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NTDNoteMetadata"];
    NSSortDescriptor *filenameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:NO];
    fetchRequest.sortDescriptors = @[filenameSortDescriptor];
    
    // Query the metadata
    NSArray *records = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // check for empty results
    if (records == nil) {
        NSLog(@"WARNING: Couldn't fetch list of notes!");
        [Flurry logError:@"Couldn't fetch list of notes" message:[error localizedDescription] error:error];
    }
    
    // migration: files will now be named according to date
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[records count]];

    NSTimeInterval dateCreatedOffset = 0;
    NSDate *refDate = [NSDate date];
    for (NTDNoteMetadata *metadata in records) {
        // ensure all files have a dateCreated field.
        if (!metadata.dateCreated) {
            NSDate *fillerDateCreated = [refDate dateByAddingTimeInterval:dateCreatedOffset];
            [metadata setDateCreated:fillerDateCreated];
            dateCreatedOffset -= 5;
        }
        
        // check if the filename reflects its date created
        if (![metadata.filename isEqualToString:[NTDNoteDocument filenameFromDate:metadata.dateCreated]]) {
            
            // attempt to move the file to a new path
            NSString *newFilename = [NTDNoteDocument filenameFromDate:metadata.dateCreated];
            NSString *oldPath = [[self notesDirectoryURL].path stringByAppendingPathComponent:metadata.filename];
            NSString *newPath = [[self notesDirectoryURL].path stringByAppendingPathComponent:newFilename];
            NSLog(@"new filename: %@", newFilename);
            if ([[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
                NSLog(@"Rename successful");
                
                // change the record's filename to reflect the migrated file
                [metadata setFilename:newFilename];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }
        
        // finally we can continue building the notes array
        [notes addObject:[NTDNoteDocument documentFromMetadata:metadata]];
    }
    
    if ([self.managedObjectContext save:&error])
        NSLog(@"names saved");
    
    // order the notes according to dateCreated
    [notes sortUsingComparator:^NSComparisonResult(NTDNoteMetadata *metadata1, NTDNoteMetadata *metadata2) {
        return [metadata2.dateCreated compare:metadata1.dateCreated];
    }];
    
    handler(notes);
    
    // clean up filesystem
    [self removeFilesWithNoMetadata:notes];

}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:[self newFileURL]];
    [self newNoteWithDocument:document completionHandler:handler];
}

+ (void)newNoteWithDocument:(NTDNoteDocument *)document completionHandler:(void(^)(NTDNote *))handler {
    document.metadata = [NSEntityDescription insertNewObjectForEntityForName:@"NTDNoteMetadata"
                                                      inManagedObjectContext:[self managedObjectContext]];
    document.metadata.filename = [document.fileURL lastPathComponent];
    document.metadata.lastModifiedDate = [NSDate date];
    document.metadata.dateCreated = [NSDate date];
    [document saveToURL:document.fileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          if (success) {
              [Flurry logEvent:@"Note Created" withParameters:@{@"counter" : @(filenameCounter-1)}];
              handler((NTDNote *)document /* Shhh... */);
              [document autosaveWithCompletionHandler:nil]; /* In case the handler has introduced any changes. */
          } else {
              NSLog(@"WARNING: Couldn't create new note!");
              [Flurry logError:@"Couldn't create new note" message:nil error:nil];
              handler(nil);
          };
      }];
    NSLog(@"*** Create - %@", document.metadata.filename);
}

#pragma mark - Restoration & Backup

+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *))handler {
    
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:[self fileURLFromDate:deletedNote.dateCreated]];
    
    [self newNoteWithDocument:document completionHandler:^(NTDNote *note) {
        [note setTheme:deletedNote.theme];
        [note setLastModifiedDate:deletedNote.lastModifiedDate];
        [note setDateCreated:deletedNote.dateCreated];
        [note setText:deletedNote.bodyText];
        
        handler(note);
    }];
    NSLog(@"*** Restore - %@", document.metadata.filename);
    
}

+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [self handlerDispatchedToMainQueue:handler];
    
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

#pragma mark - Note Deletion

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
    NSLog(@"*** Delete - %@", self.filename);

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
                                             NSError __autoreleasing *fileDeletingError;

                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             [fileManager removeItemAtURL:writingURL error:&fileDeletingError];
                                             
                                             if (fileDeletingError) NSLog(@"Error deleting file: %@", fileDeletingError);
                                         }];
        BOOL success = !error;
        if (success) [Flurry logEvent:@"Note Deleted"];
        completionHandler(success);
    }];
}

#pragma mark - Metadata Getters

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

- (NSDate *)dateCreated
{
    return self.metadata.dateCreated;
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

#pragma mark - Metadata Setters

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

- (void)setLastModifiedDate:(NSDate *)date
{
    if (![date isEqualToDate:self.lastModifiedDate]) {
        self.metadata.lastModifiedDate = date;
        [self updateChangeCount:UIDocumentChangeDone];
    }
}

- (void)setDateCreated:(NSDate *)date
{
    if (![date isEqualToDate:self.dateCreated]) {
        self.metadata.dateCreated = date;
        [self updateChangeCount:UIDocumentChangeDone];
    }
}
@end
