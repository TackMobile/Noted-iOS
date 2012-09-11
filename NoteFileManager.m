//
//  NoteFileManager.m
//  Noted
//
//  Created by Tony Hillerson on 7/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteFileManager.h"
#import "NoteDocument.h"
#import "NoteData.h"
#import "NoteEntry.h"
#import "TKPromise.h"
#import "FileStorageState.h"
#import "CloudManager.h"
#import "ApplicationModel.h"

@interface NoteFileManager ()
{
    NSURL *localDocumentRoot;
    NSURL *currentDocumentRoot;
    TKPromise *fileLoadPromise;
}

@end

@implementation NoteFileManager

@synthesize delegate;

- (id) init {
    if (self == [super init]) {
        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        localDocumentRoot = [paths objectAtIndex:0];
        currentDocumentRoot = localDocumentRoot;
    }
    return self;
}

- (void) loadAllNoteEntriesFromPreferredStorage
{
    TKPreferredStorage storage = [FileStorageState preferredStorage];
    
    if (storage==kTKiCloud) {
        [self loadAllNoteEntriesFromICloud];
    } else if (storage==kTKlocal) {
        [self loadAllNoteEntriesFromLocal];
    }
}

- (void) loadAllNoteEntriesFromICloud {
    [self performSelectorInBackground:@selector(loadICloudNoteEntriesInBackground) withObject:nil];
}

- (void)copyFromCloudAndLoadLocalNoteEntries
{
    //
}

- (void) loadAllNoteEntriesFromLocal {
    [self performSelectorInBackground:@selector(loadLocalNoteEntriesInBackground) withObject:nil];
}

- (void) didLoadNoteEntries:(NSMutableOrderedSet *)entries {
    [self.delegate fileManager:self didLoadNoteEntries:entries];
}

- (NSURL *) URLForFileNamed:(NSString *)filename {
    
    NSURL *filePath = nil;
    if ([FileStorageState preferredStorage]==kTKlocal) {
        filePath = [currentDocumentRoot URLByAppendingPathComponent:filename];
    } else {
        filePath = [[CloudManager sharedInstance] getDocURL:filename];
    }
    
    NSLog(@"%@ [%d]",filePath.absoluteString,__LINE__);
    
    return filePath;
}

#pragma mark - Create update delete

- (NoteDocument *) addNoteNamed:(NSString *)noteName withCompletionBlock:(CreateNoteCompletionBlock)noteCreationCompleteBlock {
    
    NSURL *fileURL = [self URLForFileNamed:noteName];
    NoteDocument *doc = nil;
    if ([FileStorageState preferredStorage]==kTKiCloud) {
        // have CloudManager do it
        doc = [[CloudManager sharedInstance] insertNewEntryAtIndex:0 completion:noteCreationCompleteBlock];
        
    } else {

        NSLog(@"Want to create file at %@", fileURL);
        
        doc = [[NoteDocument alloc] initWithFileURL:fileURL];
        
        [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            
            if (!success) {
                NSLog(@"Failed to create file at %@", fileURL);
                return;
            }
            
            [doc closeWithCompletionHandler:^(BOOL success) {
                if (!success) {
                    NSLog(@"Failed to close %@", fileURL);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [doc setEntryClosed];
                    noteCreationCompleteBlock(doc);
                    
                });
            }];         
        }];

    }
    
    return doc;
}

- (void)deleteNoteEntry:(NoteDocument *)noteDocument withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock {
    //TODO
    //[_query disableUpdates];
    
    
    if ([FileStorageState preferredStorage]==kTKiCloud) {
        // have CloudManager do it
        [[CloudManager sharedInstance] deleteEntry:noteDocument.noteEntry withCompletion:completionBlock];
    } else {
        NoteEntry *entry = [noteDocument noteEntry];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            
            [fileCoordinator coordinateWritingItemAtURL:entry.fileURL
                                                options:NSFileCoordinatorWritingForDeleting
                                                  error:nil
                                             byAccessor:^(NSURL* writingURL) {
                                                 
                                                 NSError *error;
                                                 NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                 [fileManager removeItemAtURL:writingURL error:&error];
#ifdef DEBUG
                                                 NSLog(@"Writing URL: %@ [%d]",writingURL,__LINE__);
                                                 NSLog(@"Deleted item at %@",entry.fileURL);
                                                 NSLog(@"Error? %@", error);
                                                 
                                                 
#endif
                                                 if (completionBlock) {
                                                     completionBlock();
                                                 }
                                                 //TODO
                                                 //[_query enableUpdates];
                                             }];
        });    

    }
    
       
}

#pragma mark - Loading

- (void) loadICloudNoteEntriesInBackground {

    // check what's there
    [[CloudManager sharedInstance] refreshWithCompleteBlock:^(NSMutableOrderedSet *noteObjects,NSMutableOrderedSet *docs){
        
        if (IsEmpty(docs)) {
            // if 1st use, create one
            if ([FileStorageState isFirstUse]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"createNote" object:nil];
            }
            
        } else {
            
            // show them
            [self performSelectorOnMainThread:@selector(didLoadNoteEntries:) withObject:docs waitUntilDone:NO];
        }
        
    } failBlock:^{
        NSLog(@"iCloud load desired but unavailable [%d]",__LINE__);
        [self performSelectorInBackground:@selector(loadLocalNoteEntriesInBackground) withObject:nil];
    }];
}

- (void) loadLocalNoteEntriesInBackground
{
    NSMutableOrderedSet *list = [NSMutableOrderedSet orderedSet];
    // array of urls from NSFileManager
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:localDocumentRoot includingPropertiesForKeys:nil options:0 error:nil];
    NSPredicate *notedDocsPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"pathExtension", kNoteExtension];
    NSArray *notedDocuments = [localDocuments filteredArrayUsingPredicate:notedDocsPredicate];
    NSArray *fileURLs = [notedDocuments valueForKeyPath:@"absoluteString"];
    
#ifdef DEBUG
    NSLog(@"Found %d local noted documents.", notedDocuments.count);    
    NSLog(@" at URLs %@", fileURLs);    
#endif
    NSSet *fileURLSet = [NSSet setWithArray:fileURLs];
    TKPromiseKeptBlock promiseKeptBlock = ^{
        [self performSelectorOnMainThread:@selector(didLoadNoteEntries:) withObject:list waitUntilDone:NO];
    };
    TKPromiseFailedBlock promiseFailedBlock = ^{
        //TODO can we get an error here?
        //TODO do this on the main thread, right?
        [self.delegate fileManager:self failedToLoadNoteEntriesWithError:nil];
    };
    TKPromiseResolvedBlock promiseResolvedBlock = ^{
        fileLoadPromise = nil;
    };
    
    fileLoadPromise = [[TKPromise alloc] initWithPromiseKeptBlock:promiseKeptBlock
                                               promiseFailedBlock:promiseFailedBlock
                                             promiseResolvedBlock:promiseResolvedBlock
                                                      commitments:nil];
    [fileLoadPromise addCommitments:fileURLSet];
    
    [notedDocuments enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        [self loadDocAtURL:fileURL intoList:list];
    }];
}

- (void)loadDocAtURL:(NSURL *)fileURL intoList:(NSMutableOrderedSet *)list {
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];
    doc.noteEntry.adding = NO;
    [doc openWithCompletionHandler:^(BOOL success) {
        if (!success) {
#ifdef DEBUG
            NSLog(@"Failed to open %@", fileURL);
#endif
            return;
        }
        
        // Preload metadata on background thread
        NoteData * noteData = [NoteData new];
        noteData.noteText = doc.text;
        noteData.noteLocation = doc.location;
        noteData.noteColor = doc.color;
        NSURL *fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
#ifdef DEBUG
        //NSLog(@"Loaded File URL: %@, State: %@, Last Modified: %@", [doc.fileURL lastPathComponent], [self stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);
#endif
        
        NoteEntry *entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        [list addObject:entry];
        [fileLoadPromise keepCommitment:fileURL.absoluteString];
        
        [doc closeWithCompletionHandler:^(BOOL success) {
#ifdef DEBUG
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
#endif
        }];             
    }];
    
}

#pragma mark - iCloud

- (void)checkICloudAvailability:(void (^)(BOOL available))completionWithICloudAvailable
{
    CloudManager *manager = [CloudManager sharedInstance];
    [manager initializeiCloudAccessWithCompletion:^(BOOL available){
        completionWithICloudAvailable(available);
    }];
}

/*
 - (void)checkICloudAvailabilityWithCompletionBlock:(void (^)(BOOL available)) completionWithICloudAvailable {
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 iCloudDocumentRoot = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
 if (iCloudDocumentRoot) {
 dispatch_async(dispatch_get_main_queue(), ^{
 #ifdef DEBUG
 NSLog(@"iCloud available at: %@", iCloudDocumentRoot);
 #endif
 currentDocumentRoot = [iCloudDocumentRoot URLByAppendingPathComponent:@"Documents" isDirectory:YES];
 completionWithICloudAvailable(YES);
 });
 } else {
 dispatch_async(dispatch_get_main_queue(), ^{
 #ifdef DEBUG
 NSLog(@"iCloud not available");
 #endif
 currentDocumentRoot = localDocumentRoot;
 completionWithICloudAvailable(NO);
 });
 }
 });
 }
 */

#pragma mark - Helpers

- (NSString *)stringForState:(UIDocumentState)state {
    NSMutableArray * states = [NSMutableArray array];
    if (state == 0) {
        [states addObject:@"Normal"];
    }
    if (state & UIDocumentStateClosed) {
        [states addObject:@"Closed"];
    }
    if (state & UIDocumentStateInConflict) {
        [states addObject:@"In Conflict"];
    }
    if (state & UIDocumentStateSavingError) {
        [states addObject:@"Saving error"];
    }
    if (state & UIDocumentStateEditingDisabled) {
        [states addObject:@"Editing disabled"];
    }
    return [states componentsJoinedByString:@", "];
}

@end