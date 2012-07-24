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

@interface NoteFileManager () {
    NSURL *localDocumentRoot;
    NSURL *iCloudDocumentRoot;
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

    }
    return self;
}

- (void) loadAllNoteEntriesFromICloud {
    
}

- (void) loadAllNoteEntriesFromLocal {
    [self performSelectorInBackground:@selector(loadLocalNoteEntriesInBackground) withObject:nil];
}

- (void) didLoadNoteEntries:(NSOrderedSet *)entries {
    [self.delegate fileManager:self didLoadNoteEntries:entries];
}

- (void) loadLocalNoteEntriesInBackground {
    NSMutableOrderedSet *list = [NSMutableOrderedSet orderedSet];
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:localDocumentRoot includingPropertiesForKeys:nil options:0 error:nil];
    NSPredicate *notedDocsPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"pathExtension", NOTE_EXTENSION];
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
        [self.delegate fileManager:self failedToLoadNoteEntriesWithError:nil];
    };
    TKPromiseResolveBlock promiseResolvedBlock = ^{
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
        NSLog(@"Loaded File URL: %@, State: %@, Last Modified: %@", [doc.fileURL lastPathComponent], [self stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);
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

- (void)checkICloudAvailabilityWithCompletionBlock:(void (^)(BOOL available)) completionWithICloudAvailable {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        iCloudDocumentRoot = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (iCloudDocumentRoot) {
            dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
                NSLog(@"iCloud available at: %@", iCloudDocumentRoot);
#endif
                currentDocumentRoot = iCloudDocumentRoot;
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