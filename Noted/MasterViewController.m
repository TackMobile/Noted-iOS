//
//  MasterViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "NoteDocument.h"
#import "NoteEntry.h"
#import "NoteData.h"
#import "NoteEntryCell.h"
#import "TransformableNoteCell.h"
#import "NoteTableGestureRecognizer.h"
#import "UIColor+HexColor.h"
#import "Utilities.h"

@interface MasterViewController () <NoteTableGestureEditingRowDelegate, NoteTableGestureAddingRowDelegate, NoteTableGestureMoveRowDelegate> {
    NSMutableArray *_objects;
    NSURL *_localRoot;
    NoteDocument * _selDocument;
    UITextField * _activeTextField;
    NSURL * _iCloudRoot;
    BOOL _iCloudAvailable;
    NSMetadataQuery * _query;
    BOOL _iCloudURLsReady;
    NSMutableArray * _iCloudURLs;
    NSURL * _selURL;
    BOOL _moveLocalToiCloud;
    BOOL _copyiCloudToLocal;
    BOOL _addingCell;
    
}
@property (nonatomic, strong) NoteTableGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;

@end

@implementation MasterViewController
@synthesize tableViewRecognizer;
@synthesize grabbedObject;
@synthesize noteKeyOpVC;

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60

#pragma mark Helpers
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


- (BOOL)iCloudOn {    
    return NO;//[[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudOn"];
}

- (void)setiCloudOn:(BOOL)on {    
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)iCloudWasOn {    
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudWasOn"];
}

- (void)setiCloudWasOn:(BOOL)on {    
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudWasOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)iCloudPrompted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudPrompted"];
}

- (void)setiCloudPrompted:(BOOL)prompted {    
    [[NSUserDefaults standardUserDefaults] setBool:prompted forKey:@"iCloudPrompted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSURL *)localRoot {
    if (_localRoot != nil) {
        return _localRoot;
    }
    
    NSArray * paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    _localRoot = [paths objectAtIndex:0];
    return _localRoot;    
}

- (NSURL *)getDocURL:(NSString *)filename {    
    if ([self iCloudOn]) {
        NSURL * docsDir = [_iCloudRoot URLByAppendingPathComponent:@"Documents" isDirectory:YES];
        return [docsDir URLByAppendingPathComponent:filename];
    } else {
        return [self.localRoot URLByAppendingPathComponent:filename];    
    }
}

- (BOOL)docNameExistsInObjects:(NSString *)docName {
    BOOL nameExists = NO;
    for (NoteEntry *entry in _objects) {
        if ([[entry.fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

- (BOOL)docNameExistsIniCloudURLs:(NSString *)docName {
    BOOL nameExists = NO;
    for (NSURL * fileURL in _iCloudURLs) {
        if ([[fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

- (NSString*)getDocFilename:(NSString *)prefix uniqueInObjects:(BOOL)uniqueInObjects {
    NSInteger docCount = 0;
    NSString* newDocName = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    BOOL first = YES;
    while (!done) {
        if (first) {
            first = NO;
            newDocName = [NSString stringWithFormat:@"%@.%@",
                          prefix, kNoteExtension];
        } else {
            newDocName = [NSString stringWithFormat:@"%@ %d.%@",
                          prefix, docCount, kNoteExtension];
        }
        
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists;
        if (uniqueInObjects) {
            nameExists = [self docNameExistsInObjects:newDocName]; 
        } else {
            nameExists = [self docNameExistsIniCloudURLs:newDocName];
        }
        if (!nameExists) {            
            break;
        } else {
            docCount++;            
        }
        
    }
    
    
    
    return newDocName;
}

- (void)initializeiCloudAccessWithCompletion:(void (^)(BOOL available)) completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _iCloudRoot = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (_iCloudRoot != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud available at: %@", _iCloudRoot);
                completion(TRUE);
            });            
        }            
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud not available");
                completion(FALSE);
            });
        }
    });
}

-(void)sortObjects {
    [_query disableUpdates];
    for (NoteEntry* entry in _objects) {
        
        NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:entry.fileURL];        
        [doc openWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to open %@", entry.fileURL);
                return;
            }
            
            // Preload metadata on background thread
            NoteData * noteData = [NoteData new];
            noteData.noteText = doc.text;
            int loc = [_objects indexOfObject:entry];
            doc.location = [NSString stringWithFormat:@"%i",loc];
            noteData.noteLocation = doc.location;
            noteData.noteColor = doc.color;
            NSURL * fileURL = doc.fileURL;
            UIDocumentState state = doc.documentState;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDoesRelativeDateFormatting:YES];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
            NSLog(@"Sorted File URL: %@, State: %@, Last Modified: %@", [doc.fileURL lastPathComponent], [self stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);
            
            
            // Close since we're done with it
            [doc closeWithCompletionHandler:^(BOOL success) {
                
                // Check status
                if (!success) {
                    NSLog(@"Failed to close %@", fileURL);
                    // Continue anyway...
                }else {
                    NSLog(@"closed the document on reload of order");
                }
                
                // Add to the list of files on main thread
                dispatch_async(dispatch_get_main_queue(), ^{                
                    [self addOrUpdateEntryWithURL:fileURL noteData:noteData state:state version:version];
                });
            }];             
        }];    }
    [_query enableUpdates];
    
}

#pragma mark Entry management methods

- (int)indexOfEntryWithFileURL:(NSURL *)fileURL {
    __block int retval = -1;
    [_objects enumerateObjectsUsingBlock:^(NoteEntry * entry, NSUInteger idx, BOOL *stop) {
        if ([entry.fileURL isEqual:fileURL]) {
            retval = idx;
            *stop = YES;
            entry = nil;
        }
    }];
    return retval;    
}

- (void)addOrUpdateEntryWithURL:(NSURL *)fileURL noteData:(NoteData *)noteData state:(UIDocumentState)state version:(NSFileVersion *)version {
    int index = [self indexOfEntryWithFileURL:fileURL];

    // Not found, so add
    if (index == -1) {    
        
        NoteEntry * entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        if ([_objects count]>0) {
            BOOL found = NO;
            for(int i = 0; i < [_objects count]; i++) {
                NoteEntry *anEntry = [_objects objectAtIndex:i];
                if (entry.noteData.noteLocation.intValue < anEntry.noteData.noteLocation.intValue) {
                    [_objects insertObject:entry atIndex:[_objects indexOfObject:anEntry]];
                    found = YES;
                    anEntry = nil;
                    break;
                }
            }
            if (!found) {
                [_objects addObject:entry];
            }
        }else {
            [_objects addObject:entry];
        }
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:(_objects.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadData];
        entry = nil;
        
    } 
    
    // Found, so edit
    else {
        
        NoteEntry * entry = [_objects objectAtIndex:index];
        entry.noteData = noteData;    
        entry.state = state;
        entry.version = version;
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        
    }
    
}

- (BOOL)renameEntry:(NoteEntry *)entry to:(NSString *)filename {
    
    // Bail if not actually renaming
    if ([entry.description isEqualToString:filename]) {
        return YES;
    }
    
    // Check if can rename file
    NSString * newDocFilename = [NSString stringWithFormat:@"%@.%@",
                                 filename, kNoteExtension];
    if ([self docNameExistsInObjects:newDocFilename]) {
        NSString * message = [NSString stringWithFormat:@"\"%@\" is already taken.  Please choose a different name.", filename];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        return NO;
    }
    
    NSURL * newDocURL = [self getDocURL:newDocFilename];
    NSLog(@"Moving %@ to %@", entry.fileURL, newDocURL);
    
    
    // Rename by saving/deleting - hack?
/*
    NSURL * origURL = entry.fileURL;
    UIDocument * doc = [[PTKDocument alloc] initWithFileURL:entry.fileURL];
    [doc openWithCompletionHandler:^(BOOL success) {
        [doc saveToURL:newDocURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"Doc saved to %@", newDocURL);                        
            [doc closeWithCompletionHandler:^(BOOL success) {
                
                // Update version of file
                dispatch_async(dispatch_get_main_queue(), ^{
                    entry.version = [NSFileVersion currentVersionOfItemAtURL:newDocURL];
                    int index = [self indexOfEntryWithFileURL:entry.fileURL];
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];    
                });                
                
                // Delete old file
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                    [fileCoordinator coordinateWritingItemAtURL:origURL 
                                                        options:NSFileCoordinatorWritingForDeleting
                                                          error:nil 
                                                     byAccessor:^(NSURL* writingURL) {                                                   
                                                         NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                         [fileManager removeItemAtURL:writingURL error:nil];
                                                     }];
                });
                NSLog(@"Doc deleted at %@", origURL);
            }];
        }];
    }];
    
*/
    
    // Wrap in file coordinator
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSError * error;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL:entry.fileURL options: NSFileCoordinatorWritingForMoving writingItemAtURL:newDocURL options: NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
            
            // Simple renaming to start
            NSFileManager* fileManager = [[NSFileManager alloc] init];
            NSError * error;
            BOOL success = [fileManager moveItemAtURL:entry.fileURL toURL:newDocURL error:&error];
            if (!success) {
                NSLog(@"Failed to move file: %@", error.localizedDescription);
                return;
            }
            
        }];
    });
    
    // Fix up entry
    entry.fileURL = newDocURL;
    int index = [self indexOfEntryWithFileURL:entry.fileURL];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
    return YES;
    
}


- (void)removeEntryWithURL:(NSURL *)fileURL {
    int index = [self indexOfEntryWithFileURL:fileURL];
    [_objects removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark File management methods

- (void)loadDocAtURL:(NSURL *)fileURL {
    
    // Open doc so we can read metadata
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];        
    [doc openWithCompletionHandler:^(BOOL success) {
        
        // Check status
        if (!success) {
            NSLog(@"Failed to open %@", fileURL);
            return;
        }
        
        // Preload metadata on background thread
        NoteData * noteData = [NoteData new];
        noteData.noteText = doc.text;
        noteData.noteLocation = doc.location;
        noteData.noteColor = doc.color;
        NSURL * fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        NSLog(@"Loaded File URL: %@, State: %@, Last Modified: %@", [doc.fileURL lastPathComponent], [self stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);

        
        // Close since we're done with it
        [doc closeWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
            
            // Add to the list of files on main thread
            dispatch_async(dispatch_get_main_queue(), ^{                
                [self addOrUpdateEntryWithURL:fileURL noteData:noteData state:state version:version];
            });
        }];             
    }];
    
}

- (void)insertNewEntryAtIndex:(int)index {
    [_query disableUpdates];
    NSURL * fileURL = [self getDocURL:[self getDocFilename:@"Note" uniqueInObjects:YES]];
    NoteEntry *entry = [NoteEntry new];
    NSLog(@"Want to create file at %@", fileURL);
    // Create new document and save to the filename
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];
    [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            NSLog(@"Failed to create file at %@", fileURL);
            return;
        } 
        
        NSLog(@"File created at %@", fileURL);        
        NoteData * noteData = [NoteData new];
        doc.location = [NSString stringWithFormat:@"%i",index];
        noteData.noteLocation = doc.location;
        noteData.noteColor = doc.color;
        noteData.noteText = doc.text;
        NSURL * fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
            
        // Add to the list of files on main thread
        dispatch_async(dispatch_get_main_queue(), ^{                
            entry.fileURL = fileURL;
            entry.noteData = noteData;
            entry.state = state;
            entry.version = version;
            entry.adding = NO;
            [_objects insertObject:entry atIndex:index];
            //[self sortObjects];
            self.noteKeyOpVC.notes = _objects;
            [self.noteKeyOpVC openTheNote:doc];
            [_query enableUpdates];
            
        });
    }];   
    
    //we don't close the document since this document is automatically opened in the notekeyoptionsVC (cannot close documents twice)
    
    

}

- (void)deleteEntry:(NoteEntry *)entry {
    [_query disableUpdates];
    // Wrap in file coordinator
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:entry.fileURL 
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:nil 
                                         byAccessor:^(NSURL* writingURL) {                                                   
                                             // Simple delete to start
                                             NSError *error;
                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             [fileManager removeItemAtURL:entry.fileURL error:&error];
                                             NSLog(@"Deleted item at %@",entry.fileURL);
                                             NSLog(@"Error? %@", error);
                                             [_query enableUpdates];
                                         }];
    });    
    
    // Fixup view
    [self removeEntryWithURL:entry.fileURL];
}

- (void)iCloudToLocalImpl {
    
    NSLog(@"iCloud => local impl");
    
    for (NSURL * fileURL in _iCloudURLs) {
        
        NSString * fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
        NSURL *destURL = [self getDocURL:[self getDocFilename:fileName uniqueInObjects:YES]];
        
        // Perform copy on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {            
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newURL) {
                NSFileManager * fileManager = [[NSFileManager alloc] init];
                NSError * error;
                BOOL success = [fileManager copyItemAtURL:fileURL toURL:destURL error:&error];                     
                if (success) {
                    NSLog(@"Copied %@ to %@ (%d)", fileURL, destURL, self.iCloudOn);
                    [self loadDocAtURL:destURL];
                } else {
                    NSLog(@"Failed to copy %@ to %@: %@", fileURL, destURL, error.localizedDescription); 
                }
            }];
        });
    }
    
}

- (void)iCloudToLocal {
    NSLog(@"iCloud => local");
    
    // Wait to find out what user wants first
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"You're Not Using iCloud" message:@"What would you like to do with the documents currently on this device?" delegate:self cancelButtonTitle:@"Continue Using iCloud" otherButtonTitles:@"Keep a Local Copy", @"Keep on iCloud Only", nil];
    alertView.tag = 2;
    [alertView show];
}

- (void)localToiCloudImpl {
    
    NSLog(@"local => iCloud impl");
    
    NSArray * localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localRoot includingPropertiesForKeys:nil options:0 error:nil];
    for (int i=0; i < localDocuments.count; i++) {
        
        NSURL * fileURL = [localDocuments objectAtIndex:i];
        if ([[fileURL pathExtension] isEqualToString:kNoteExtension]) {
            
            NSString * fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
            NSURL *destURL = [self getDocURL:[self getDocFilename:fileName uniqueInObjects:NO]];
        
            // Perform actual move in background thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSError * error;
                BOOL success = [[NSFileManager defaultManager] setUbiquitous:self.iCloudOn itemAtURL:fileURL destinationURL:destURL error:&error];
                if (success) {
                    NSLog(@"Moved %@ to %@", fileURL, destURL);
                    [self loadDocAtURL:destURL];
                } else {
                    NSLog(@"Failed to move %@ to %@: %@", fileURL, destURL, error.localizedDescription); 
                }
            });
            
        }
    }
    
}

- (void)localToiCloud {
    NSLog(@"local => iCloud");
    
    // If we have a valid list of iCloud files, proceed
    if (_iCloudURLsReady) {
        [self localToiCloudImpl];
    } 
    // Have to wait for list of iCloud files to refresh
    else {
        _moveLocalToiCloud = YES;         
    }
}

#pragma mark iCloud Query

- (NSMetadataQuery *)documentQuery {
    
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    if (query) {
        
        // Search documents subdir only
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Add a predicate for finding the documents
        NSString * filePattern = [NSString stringWithFormat:@"*.%@", kNoteExtension];
        [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",
                             NSMetadataItemFSNameKey, filePattern]];        
        
    }
    return query;
    
}

- (void)stopQuery {
    
    if (_query) {
        
        NSLog(@"No longer watching iCloud dir...");
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
        [_query stopQuery];
        _query = nil;
    }
    
}

- (void)startQuery {
    
    [self stopQuery];
    
    NSLog(@"Starting to watch iCloud dir...");
    
    _query = [self documentQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    [_query startQuery];
}

- (void)processiCloudFiles:(NSNotification *)notification {
    
    // Always disable updates while processing results
    [_query disableUpdates];
    
    [_iCloudURLs removeAllObjects];
    
    // The query reports all files found, every time.
    NSArray * queryResults = [_query results];
    for (NSMetadataItem * result in queryResults) {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber * aBool = nil;
        
        // Don't include hidden files
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue]) {
            [_iCloudURLs addObject:fileURL];
        }        
        
    }        
    
    NSLog(@"Found %d iCloud files.", _iCloudURLs.count);
    _iCloudURLsReady = YES;
    
    if ([self iCloudOn]) {
        
        // Remove deleted files
        // Iterate backwards because we need to remove items from the array
        for (int i = _objects.count -1; i >= 0; --i) {
            if ([[_objects objectAtIndex:i] isKindOfClass:[NSString class]]) {
                NSLog(@"This is an error with the object stored in the table view");
                return;
            }
            NoteEntry * entry = [_objects objectAtIndex:i];
            if (![_iCloudURLs containsObject:entry.fileURL]) {
                [self removeEntryWithURL:entry.fileURL];
            }
        }
        
        // Add new files
        for (NSURL * fileURL in _iCloudURLs) {                
            [self loadDocAtURL:fileURL];        
        }
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
    } 
    if (_moveLocalToiCloud) {            
        _moveLocalToiCloud = NO;
        [self localToiCloudImpl];            
    }else if (_copyiCloudToLocal) {
        _copyiCloudToLocal = NO;
        [self iCloudToLocalImpl];
    }
    [_query enableUpdates];
}



#pragma mark Refresh Methods

- (void)loadLocal {

NSArray * localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localRoot includingPropertiesForKeys:nil options:0 error:nil];
NSLog(@"Found %d local files.", localDocuments.count);    
for (int i=0; i < localDocuments.count; i++) {
    
    NSURL * fileURL = [localDocuments objectAtIndex:i];
    if ([[fileURL pathExtension] isEqualToString:kNoteExtension]) {
        NSLog(@"Found local file: %@", fileURL);
        [self loadDocAtURL:fileURL];
    }        
}

self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh {
    _iCloudURLsReady = NO;
    [_iCloudURLs removeAllObjects];    
    [_objects removeAllObjects];
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        _iCloudAvailable = available;
        
        if (!_iCloudAvailable) {
            
            // If iCloud isn't available, set promoted to no (so we can ask them next time it becomes available)
            [self setiCloudPrompted:NO];
            
            // If iCloud was toggled on previously, warn user that the docs will be loaded locally
            if ([self iCloudWasOn]) {
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"You're Not Using iCloud" message:@"Your documents were removed from this iPad but remain stored in iCloud." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
            
            // No matter what, iCloud isn't available so switch it to off.
            [self setiCloudOn:NO]; 
            [self setiCloudWasOn:NO];
            
        } else {        
            
            // Ask user if want to turn on iCloud if it's available and we haven't asked already
            if (![self iCloudOn] && ![self iCloudPrompted]) {
                
                [self setiCloudPrompted:YES];
                
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"iCloud is Available" message:@"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web." delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Use iCloud", nil];
                alertView.tag = 1;
                [alertView show];
                
            } 
            
            // If iCloud newly switched off, move local docs to iCloud
            if ([self iCloudOn] && ![self iCloudWasOn]) {                    
                [self localToiCloud];                                                           
            }                
            
            // If iCloud newly switched on, move iCloud docs to local
            if (![self iCloudOn] && [self iCloudWasOn]) {
                [self iCloudToLocal];                    
            }
            
            // Start querying iCloud for files, whether on or off
            [self startQuery];
            
            // No matter what, refresh with current value of iCloudOn
            [self setiCloudWasOn:[self iCloudOn]];
            
        }
        
        if (![self iCloudOn]) {
            [self loadLocal];        
        }
        
    }];
}

// Add right after the refresh method
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // @"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web."
    // Cancel: @"Later"
    // Other: @"Use iCloud"
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.firstOtherButtonIndex) 
        {
            [self setiCloudOn:YES];            
            [self refresh];
        }                
    } else if (alertView.tag == 2) {
        
        if (buttonIndex == alertView.cancelButtonIndex) {
            
            [self setiCloudOn:YES];
            [self refresh];
            
        } else if (buttonIndex == alertView.firstOtherButtonIndex) {
            
            if (_iCloudURLsReady) {
                [self iCloudToLocalImpl];
            } else {
                _copyiCloudToLocal = YES;
            }
            
        } else if (buttonIndex == alertView.firstOtherButtonIndex + 1) {            
            
            // Do nothing
            
        } 
        
    }
}


#pragma mark Text Views

- (void)textChanged:(UITextField *)textField {
    UIView * view = textField.superview;
    while( ![view isKindOfClass: [NoteEntryCell class]]){
        view = view.superview;
    }
    NoteEntryCell *cell = (NoteEntryCell *) view;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    NoteEntry * entry = [_objects objectAtIndex:indexPath.row];
    NSLog(@"Want to rename %@ to %@", entry.description, textField.text);
    [self renameEntry:entry to:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    [self textChanged:textField];
	return YES;
}


#pragma mark View lifecycle


@synthesize detailViewController = _detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    self.tableView.backgroundView = backgroundView;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight       = NORMAL_CELL_FINISHING_HEIGHT;
    
    _objects = [[NSMutableArray alloc] init];
    _iCloudURLs = [[NSMutableArray alloc] init];
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)didBecomeActive:(NSNotification *)notification {    
    [self refresh];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated {
    [_query enableUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_query disableUpdates];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *object = [_objects objectAtIndex:indexPath.row];
    UIColor *backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.05 * indexPath.row / [self tableView:tableView numberOfRowsInSection:indexPath.section]];
    NoteEntry *anEntry = [_objects objectAtIndex:indexPath.row];
    if (anEntry.adding == YES) {
        NSString *cellIdentifier = nil;
        TransformableNoteCell *cell = nil;
        
        // IndexPath.row == 0 is the case we wanted to pick the pullDown style
        if (indexPath.row == 0) {
            cellIdentifier = @"PullDownTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableNoteCell transformableNoteCellWithStyle:TransformableNoteCellStylePullDown
                                                             reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                //cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pulling...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
            
        } else {
            // Otherwise is the case we wanted to pick the pinching style
            cellIdentifier = @"UnfoldingTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableNoteCell transformableNoteCellWithStyle:TransformableNoteCellStyleUnfolding
                                                             reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                //cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pinching...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
        }
        
    } else {
        static NSString *cellIdentifier = @"NoteEntryCell";
        NoteEntryCell *cell = (NoteEntryCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            cell = [topLevelObjects objectAtIndex:0];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if ([object isKindOfClass:[NoteEntry class]]) {
            NoteEntry *entry = [_objects objectAtIndex:indexPath.row];
            
            NSArray *allLines = [entry.noteData.noteText componentsSeparatedByString:@"\n"];
            if ([allLines count]>0) {
                NSString *firstLine = [allLines objectAtIndex:0];
                cell.subtitleLabel.text = firstLine;
            }else {
                cell.subtitleLabel.text = entry.noteData.noteText;
            }
            if (entry.version) {
                cell.relativeTimeText.text = [Utilities formatRelativeDate:entry.version.modificationDate];
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.contentView.backgroundColor = backgroundColor;
           
            }else if (entry.moving) {
                cell.textLabel.text = @"";
                cell.contentView.backgroundColor = [UIColor clearColor];
            } else {
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.contentView.backgroundColor = backgroundColor;
            }
            
            return cell;
        }
        
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {                
        NoteEntry * entry = [_objects objectAtIndex:indexPath.row];
        [self deleteEntry:entry];
        entry = nil;
    } 
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NoteEntry * entry = [_objects objectAtIndex:indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        _selDocument = [[NoteDocument alloc] initWithFileURL:entry.fileURL];    
        [_selDocument openWithCompletionHandler:^(BOOL success) {
            NSLog(@"Selected doc with state: %@", [self stringForState:_selDocument.documentState]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_selDocument closeWithCompletionHandler:^(BOOL success) {                
                    self.noteKeyOpVC = [NoteKeyOpViewController new];
                    self.noteKeyOpVC.notes = _objects;
                    [self.noteKeyOpVC openTheNote:_selDocument];
                    self.noteKeyOpVC.delegate = self;
                    //[self presentModalViewController:self.noteKeyOpVC animated:YES];
                    [self presentViewController:self.noteKeyOpVC animated:YES completion:nil];
                }];
            });
        }];

   // }
} 

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NORMAL_CELL_FINISHING_HEIGHT;
}

#pragma mark NoteKeyOpViewControllerDelegate

-(void)closeNote {
    //[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.noteKeyOpVC = nil;
    _selDocument = nil;
    [self refresh];
}

-(void)addNoteAtIndex:(int)index {
    [self insertNewEntryAtIndex:index];
}

-(void)deleteNote:(NoteDocument *)noteDocument {
    NSPredicate *findByFileURLPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"fileURL", noteDocument.fileURL];
    NSArray *foundEntries = [_objects filteredArrayUsingPredicate:findByFileURLPredicate];
    NoteEntry *entryToDelete = [foundEntries lastObject]; // only expecting one
    [self deleteEntry:entryToDelete];
    [self closeNote];
}


#pragma mark -
#pragma mark NoteTableGestureAddingRowDelegate

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSURL * fileURL = [self getDocURL:[self getDocFilename:@"Note" uniqueInObjects:YES]];
    NoteEntry * entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:nil state:UIDocumentStateClosed version:nil];
    entry.adding = YES;
    [_objects insertObject:entry atIndex:indexPath.row];
    
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = gestureRecognizer.tableView;
    [_query disableUpdates];
    [tableView beginUpdates];
    NoteEntry *entry = [_objects objectAtIndex:indexPath.row];
//    [_objects removeObjectAtIndex:indexPath.row];
//    NSURL * fileURL = [self getDocURL:[self getDocFilename:@"Note" uniqueInObjects:YES]];
//    [_objects insertObject:temp atIndex:indexPath.row];
    NSURL *fileURL = entry.fileURL;
    NSLog(@"Want to create file at %@", fileURL);
    // Create new document and save to the filename
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];
    [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            NSLog(@"Failed to create file at %@", fileURL);
            return;
        } 
        
        NSLog(@"File created at %@", fileURL);        
        NoteData * noteData = [NoteData new];
        doc.location = [NSString stringWithFormat:@"%i",indexPath.row];
        noteData.noteLocation = doc.location;
        noteData.noteColor = doc.color;
        noteData.noteText = doc.text;
        NSURL * fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        // Close since we're done with it
        [doc closeWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
            
            // Add to the list of files on main thread
            dispatch_async(dispatch_get_main_queue(), ^{                
                entry.noteData = noteData;
                entry.state = state;
                entry.version = version;
                entry.adding = NO;
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        //        [self sortObjects];
                [tableView endUpdates];
                [_query enableUpdates];
            });
        }];         
    }]; //
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    [_objects removeObjectAtIndex:indexPath.row];
}

#pragma mark NoteTableGestureEditingRowDelegate

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer didEnterEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    UIColor *backgroundColor = nil;
    switch (state) {
        case NoteCellEditingStateMiddle:
            backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.05 * indexPath.row / [self tableView:self.tableView numberOfRowsInSection:indexPath.section]];
            break;
        case NoteCellEditingStateRight:
            backgroundColor = [UIColor greenColor];
            break;
        default:
            backgroundColor = [UIColor darkGrayColor];
            break;
    }
    cell.contentView.backgroundColor = backgroundColor;
    if ([cell isKindOfClass:[TransformableNoteCell class]]) {
        ((TransformableNoteCell *)cell).tintColor = backgroundColor;
    }
}

// This is needed to be implemented to let our delegate choose whether the panning gesture should work
- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer commitEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = gestureRecognizer.tableView;
    [tableView beginUpdates];
    if (state == NoteCellEditingStateLeft) {
        // An example to discard the cell at JTTableViewCellEditingStateLeft
        NoteEntry * entry = [_objects objectAtIndex:indexPath.row];
        [self deleteEntry:entry];
    } else if (state == NoteCellEditingStateRight) {
        // An example to retain the cell at commiting at JTTableViewCellEditingStateRight
    //    [_objects replaceObjectAtIndex:indexPath.row withObject:DONE_CELL];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]
    }
    [tableView endUpdates];
//    [self sortObjects];
    // Row color needs update after datasource changes, reload it.
    [tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:indexPath afterDelay:NoteTableRowAnimationDuration];
    

 }

#pragma mark NoteTableGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [_objects objectAtIndex:indexPath.row];
    NSURL * fileURL = [self getDocURL:[self getDocFilename:@"Note" uniqueInObjects:YES]];
    NoteEntry * entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:nil state:UIDocumentStateClosed version:nil];
    entry.adding = NO;
    entry.moving = YES;
    [_objects replaceObjectAtIndex:indexPath.row withObject:entry];
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id object = [_objects objectAtIndex:sourceIndexPath.row];
    [_objects removeObjectAtIndex:sourceIndexPath.row];
    [_objects insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    [_objects replaceObjectAtIndex:indexPath.row withObject:self.grabbedObject];
//    [self sortObjects];
    self.grabbedObject = nil;
}

@end
