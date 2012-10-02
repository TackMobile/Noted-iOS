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
        [self performSelectorInBackground:@selector(loadICloudNoteEntriesInBackground) withObject:nil];
    } else if (storage==kTKlocal) {
        [self performSelectorInBackground:@selector(loadLocalNoteEntriesInBackground) withObject:nil];
    }
}

- (void)copyFromCloudAndLoadLocalNoteEntries
{
    //
}

- (void) didLoadNoteEntries:(NSMutableArray *)noteEntries {
    if (noteEntries.count==0) {
        NSLog(@"Error loading entries [%d]",__LINE__);
    }
    [self.delegate fileManager:self didLoadNoteEntries:noteEntries];
}

- (NSURL *)URLForFileNamed:(NSString *)filename {
    
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

- (NoteEntry *) addNoteNamed:(NSString *)noteName withCompletionBlock:(CreateNoteCompletionBlock)noteCreationCompleteBlock {
    
    // prepend appropriate path to our new randomly generated document name
    NSURL *fileURL = [self URLForFileNamed:noteName];
    NSLog(@"fileURL for new doc: %@",fileURL);
    
    // object to pass back to main thread for tableview
    __block NoteEntry *entry = [[NoteEntry alloc] init];
    entry.fileURL = fileURL;
    entry.adding = YES;
    
    NoteDocument *doc = nil;
    
    void(^docSaveCompleteBlock)() = ^(){
        // get default data for a new note
        // ie white background, now for creation date, etc
        NoteData *noteData = [NoteData noteDataWithLocation:@"0"];
        
        UIDocumentState state = doc.documentState;
        NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        entry.noteData = noteData;
        entry.state = state;
        entry.version = version;
        entry.adding = NO;
        noteCreationCompleteBlock(entry);
    };
    
    if ([FileStorageState preferredStorage]==kTKiCloud) {
        // have CloudManager do it
        NSLog(@"Want to create file at %@", fileURL);
        
        [[CloudManager sharedInstance] insertNewEntry:entry atIndex:0 completion:docSaveCompleteBlock];
        
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
                    
                    docSaveCompleteBlock();
                    
                });
            }];         
        }];

    }
    
    // we can immediately return just an
    // object with basic document metadata
    return entry;
}

- (void)deleteNoteEntry:(NoteEntry *)noteEntry  withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock {
    //TODO
    //[_query disableUpdates];
    
    if (noteEntry.adding) {
        return;
    }
    
    if ([FileStorageState preferredStorage]==kTKiCloud) {
        // have CloudManager do it
#warning TODO: reimplement!!!!!
        //[[CloudManager sharedInstance] deleteEntry:noteDocument.noteEntry withCompletion:completionBlock];
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            
            [fileCoordinator coordinateWritingItemAtURL:noteEntry.fileURL
                                                options:NSFileCoordinatorWritingForDeleting
                                                  error:nil
                                             byAccessor:^(NSURL* writingURL) {
                                                 
                                                 NSError *error;
                                                 NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                 [fileManager removeItemAtURL:writingURL error:&error];
#ifdef DEBUG
                                                 NSLog(@"Writing URL: %@ [%d]",writingURL,__LINE__);
                                                 NSLog(@"Deleted item at %@",noteEntry.fileURL);
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
    [[CloudManager sharedInstance] refreshWithCompleteBlock:^(NSMutableArray *noteEntries){
        
        if (IsEmpty(noteEntries)) {
            // if 1st use, create one
            if ([FileStorageState isFirstUse]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOULD_CREATE_NOTE object:nil];
            }
            
        } else {
            
            // show them
            [self performSelectorOnMainThread:@selector(didLoadNoteEntries:) withObject:noteEntries waitUntilDone:NO];
        }
        
    } failBlock:^{
        NSLog(@"iCloud load desired but unavailable [%d]",__LINE__);
        [self performSelectorInBackground:@selector(loadLocalNoteEntriesInBackground) withObject:nil];
    }];
}

- (void)loadLocalNoteEntriesInBackground
{
    NSMutableArray *list = [NSMutableArray array];
    // array of urls from NSFileManager
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:localDocumentRoot includingPropertiesForKeys:nil options:0 error:nil];
    NSPredicate *notedDocsPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"pathExtension", kNoteExtension];
    NSArray *notedDocuments = [localDocuments filteredArrayUsingPredicate:notedDocsPredicate];
    
    if (IsEmpty(notedDocuments)) {
#warning TODO: create first doc
        if ([FileStorageState isFirstUse]) {
            NSLog(@"Create the first doc if this is first use");
        }
        
        return;
    }
    
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

- (void)loadDocAtURL:(NSURL *)fileURL intoList:(NSMutableArray *)list
{
    NoteDocument *savedDocument = [[NoteDocument alloc] initWithFileURL:fileURL];
    [savedDocument openWithCompletionHandler:^(BOOL success) {
        if (!success) {
#ifdef DEBUG
            NSLog(@"Failed to open %@", fileURL);
#endif
            return;
        }
        
        // Preload metadata on background thread
        NoteData *noteData = savedDocument.data; // decodes from file wrapper or creates brand new
        //noteData.noteText = doc.text;
        //noteData.noteLocation = doc.location;
        //noteData.noteColor = doc.color;
        
        NSURL *fileURL = savedDocument.fileURL;
        UIDocumentState state = savedDocument.documentState;
        NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
#ifdef DEBUG
        /*
         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
         [dateFormatter setDoesRelativeDateFormatting:YES];
         [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
         [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
         NSLog(@"Loaded File URL: %@, State: %@, Last Modified: %@", [doc.fileURL lastPathComponent], [self stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);
         */
#endif
        
        NoteEntry *entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        
        if (entry) {
            [list addObject:entry];
            [fileLoadPromise keepCommitment:fileURL.absoluteString];
        } else {
#warning TODO: report error
            NSLog(@"Couldn't make note entry [%d]",__LINE__);
        }
        
        [savedDocument closeWithCompletionHandler:^(BOOL success) {
#ifdef DEBUG
            if (!success) {
                NSLog(@"Failed to close %@ [%d]", fileURL,__LINE__);
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