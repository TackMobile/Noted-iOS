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
#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"
#import "NTDNote.h"
#import "NTDCoreDataStore.h"

static NSString *const FileExtension = @"txt";
static const NSUInteger HeadlineLength = 35;

@interface NTDNoteDocument ()
@property (nonatomic, strong) NSString *bodyText;
@property (nonatomic, strong) NTDNoteMetadata *metadata;
@end

@implementation NTDNoteDocument

#pragma mark - Helpers
+ (NSURL*)localDocumentsDirectoryURL
{
    static NSURL *localDocumentsDirectoryURL = nil;
    if (localDocumentsDirectoryURL == nil) {
        NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                                                NSUserDomainMask, YES ) objectAtIndex:0];
        localDocumentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectoryPath];
    }
    return localDocumentsDirectoryURL;
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
    return [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:filename];
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

+ (instancetype)documentFromMetadata:(NTDNoteMetadata *)metadata
{
    NSURL *fileURL = [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:metadata.filename];
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:fileURL];
    document.metadata = metadata;
    return document;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    return [[NTDCoreDataStore sharedStore] persistingManagedObjectContext];
}

- (void)setBodyText:(NSString *)bodyText
{
//    if (0 == [bodyText length])
//        NSLog(@"Changing bodyText from \"%@\" to \"%@\".", _bodyText, bodyText);
    _bodyText = bodyText;
    return;
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

+ (void)moveNotesToDirectory:(NSURL *)newDirectory completionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    if (!handler) handler = ^(BOOL _){};
    
    // lock PSC
    [[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] lock];

    // for every file, move into subfolder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError __autoreleasing *error;
    NSArray *existingItems = [fileManager contentsOfDirectoryAtURL:[self localDocumentsDirectoryURL]
                                        includingPropertiesForKeys:nil
                                                           options:0
                                                             error:&error];
    if (error) {
        NSLog(@"Couldn't list contents of %@: %@", [self localDocumentsDirectoryURL], error);
        handler(NO);
        return;
    }
    
    for (NSURL *file in existingItems) {
        NSURL *newFile = [newDirectory URLByAppendingPathComponent:[file lastPathComponent] isDirectory:NO];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:[file path] isDirectory:&isDir] && isDir)
            continue;
        [fileManager moveItemAtURL:file toURL:newFile error:&error];
        if (error) {
            NSLog(@"Couldn't move file from %@ to %@: %@", file, newFile, error);
            handler(NO);
            return;
        }
    }
    
    // unlock PSC
    [[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] unlock];

    // reset PSC
    [[NTDCoreDataStore sharedStore] resetStore];

    handler(YES);
}

+ (void)restoreNotesFromDirectory:(NSURL *)directory completionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    if (!handler) handler = ^(BOOL _){};
    
    // delete store
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError __autoreleasing *error;

    [[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] lock];
    NSPersistentStore *mainStore = [[[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] persistentStores] objectAtIndex:0];
    [fileManager removeItemAtURL:[mainStore URL] error:&error];
    if (error) {
        NSLog(@"Couldn't delete persistent store: %@", error);
        handler(NO);
        return;
    }
    
    // nil PSC
    [[[NTDCoreDataStore sharedStore] persistentStoreCoordinator] unlock];
    [[NTDCoreDataStore sharedStore] resetStore];

    // move all files from subfolder into folder
    NSArray *existingItems = [fileManager contentsOfDirectoryAtURL:directory
                                        includingPropertiesForKeys:nil
                                                           options:0
                                                             error:&error];
    
    for (NSURL *file in existingItems) {
        NSURL *newFile = [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:[file lastPathComponent] isDirectory:NO];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:[newFile path] isDirectory:&isDir] && isDir)
            continue;
        [fileManager moveItemAtURL:file toURL:newFile error:&error];
        if (error) {
            NSLog(@"Couldn't move file from %@ to %@: %@", file, newFile, error);
            handler(NO);
            return;
        }
    }

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
