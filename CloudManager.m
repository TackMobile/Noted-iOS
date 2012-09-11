//
//  ICloudManager.m
//  Noted
//
//  Created by Ben Pilcher on 9/6/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "CloudManager.h"
#import "NoteDocument.h"
#import "NoteEntry.h"
#import "NoteData.h"
#import "FileStorageState.h"
#import "TKPromise.h"

@interface CloudManager()
{
    NSMetadataQuery * _query;
    
    NSMutableArray * _iCloudURLs;
    BOOL _iCloudURLsReady;
    BOOL _moveLocalToiCloud;
    BOOL _copyiCloudToLocal;
    BOOL _iCloudAvailable;
    
    NSURL *_localRoot;
    NSURL *_iCloudRoot;
    
    // array of NoteEntry objects
    NSMutableArray *_objects;
    TKPromise *iCloudFileLoadPromise;
}

@property (nonatomic, copy) iCloudLoadingComplete loadingComplete;

@end

@implementation CloudManager

static CloudManager *sharedInstance;

+ (CloudManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (sharedInstance == NULL) {
            sharedInstance = [[super allocWithZone:NULL] init];
        }
    });
    
    return sharedInstance;
}

- (id)init
{
    if (self == [super init]) {
        _iCloudURLsReady = NO;
        _moveLocalToiCloud = NO;
        _copyiCloudToLocal = NO;
        _iCloudAvailable = NO;
        
        _objects = [[NSMutableArray alloc] init];
        _iCloudURLs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)initializeiCloudAccessWithCompletion:(iCloudAvailableBlock)available {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // return the 1st iCloud container by passing nil
        _iCloudRoot = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (_iCloudRoot != nil) {
            [FileStorageState setiCloudOn:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud available at: %@", _iCloudRoot);
                available(YES);
            });
        }
        else {
            [FileStorageState setiCloudOn:NO];
            //[FileStorageState setiCloudWasOn:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud not available. Loading files from local docs directory");
                available(NO);
                
            });
        }
    });
}

#pragma mark Public interface methods

- (void)refreshWithCompleteBlock:(iCloudLoadingComplete)complete failBlock:(iCloudLoadingFailed)failed
{
    self.loadingComplete = complete;
    
    _iCloudURLsReady = NO;
    [_iCloudURLs removeAllObjects];
    [_objects removeAllObjects];
    
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        _iCloudAvailable = available;
        
        if (!_iCloudAvailable) {
            
            // If iCloud isn't available, set prompted to NO (so we can ask them next time it becomes available)
            [FileStorageState setiCloudPrompted:NO];
            
            // If iCloud was toggled on previously, warn user that the docs will be loaded locally
            if ([FileStorageState iCloudWasOn]) {
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"You're Not Using iCloud" message:@"Your documents were loaded only locally but remain stored in iCloud." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
            
            // No matter what, iCloud isn't available so switch it to off.
            [FileStorageState setiCloudOn:NO];
            [FileStorageState setiCloudWasOn:NO];
            
            //[self copyFromCloudToLocal];
            
        } else {
            
            // Ask user if want to turn on iCloud if it's available and we haven't asked already
            if (![FileStorageState iCloudOn] && ![FileStorageState iCloudPrompted]) {
                
                [FileStorageState setiCloudPrompted:YES];
                
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"iCloud is Available" message:@"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web." delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Use iCloud", nil];
                alertView.tag = 1;
                [alertView show];
                
            }
            
            // If iCloud newly switched on, move local docs to iCloud
            BOOL iCloudOn = [FileStorageState iCloudOn];
            BOOL iCloudWasOn = [FileStorageState iCloudWasOn];
            if (iCloudOn && !iCloudWasOn) {
                [self localToiCloud];
            }
            
            // If iCloud newly switched off, move iCloud docs to local
            if (![FileStorageState iCloudOn] && [FileStorageState iCloudWasOn]) {
                [self iCloudToLocal];
            }
            
            // Start querying iCloud for files, whether on or off
            [self startQuery];
            
            // No matter what, refresh with current value of iCloudOn
            [FileStorageState setiCloudWasOn:[FileStorageState iCloudOn]];
            
        }
        
        if (![FileStorageState iCloudOn]) {
            // tell client (NoteFileManager) to load from local instead
            failed();
        }
        
    }];
}

#pragma mark iCloud Query

- (void)startQuery {
    
    [self stopQuery];
    
    NSLog(@"Starting to watch iCloud dir...");
    [EZToastView showToastMessage:[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__]];
    
    _query = [self documentQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFilesFromUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    [_query startQuery];
}

- (NSMetadataQuery *)documentQuery {
    
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    if (query) {
        
        // Search documents subdir only
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Add a predicate for finding any/all documents with extension .ntd
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

- (void)createFirstDoc
{
    NSLog(@"create a new doc here! [%d]",__LINE__);
}

- (int)removeEntryWithURL:(NSURL *)fileURL {
    int index = [self indexOfEntryWithFileURL:fileURL];
    [_objects removeObjectAtIndex:index];
    
    //[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    
    return index;
}

#pragma mark NoteEntry management methods

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
        //NSLog(@"%@ [%d]",_objects,__LINE__);
        NoteEntry * entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        if ([_objects count]>0) {
            BOOL found = NO;
            for(int i = 0; i < [_objects count]; i++) {
                NoteEntry *anEntry = [_objects objectAtIndex:i];
                
                if ([entry.fileURL isEqual:anEntry.fileURL]) {
                    [_objects insertObject:entry atIndex:[_objects indexOfObject:anEntry]];
                    found = YES;
                    anEntry = nil;
                    break;
                }
            /*
             if (entry.noteData.noteLocation.intValue < anEntry.noteData.noteLocation.intValue) {
             [_objects insertObject:entry atIndex:[_objects indexOfObject:anEntry]];
             found = YES;
             anEntry = nil;
             break;
             }
             */
            }
            if (!found) {
                [_objects addObject:entry];
            }
        }else {
            [_objects addObject:entry];
        }

        
        entry = nil;
        
    }
    
    // Found, so edit
    else {
        
        NoteEntry * entry = [_objects objectAtIndex:index];
        entry.noteData = noteData;
        entry.state = state;
        entry.version = version;
        
        //[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        
    }
    
}

#pragma mark File management

- (void)processiCloudFilesFromUpdate:(NSNotification *)notification
{
    [EZToastView showToastMessage:@"did query iCloud after update"];
    [self processFiles:notification];
}

- (void)processiCloudFiles:(NSNotification *)notification {
    
    [EZToastView showToastMessage:@"did query iCloud for refresh request"];
    [self processFiles:notification];
}

- (void)processFiles:(NSNotification *)notification
{
    // Always disable updates while processing results
    [_query disableUpdates];
    
    [_iCloudURLs removeAllObjects];
    [EZToastView showToastMessage:@"processing iCloud URLS"];
    
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
    
    if ([FileStorageState iCloudOn]) {
        
        // Remove deleted files
        // Iterate backwards because we need to remove items from the array
        for (int i = _objects.count -1; i >= 0; --i) {
            if ([[_objects objectAtIndex:i] isKindOfClass:[NSString class]]) {
                NSLog(@"This is an error with the object stored in the table view");
                return;
            }
            NoteEntry *entry = [_objects objectAtIndex:i];
            if (![_iCloudURLs containsObject:entry.fileURL]) {
                [self removeEntryWithURL:entry.fileURL];
            }
        }
        
        if (_iCloudURLs.count==0) {
            // no docs found
            [_query enableUpdates];
            self.loadingComplete(nil,nil);
            
            return;
            
        } else {
            
            // open the documents, and when they're all done
            // pass an NSMutableOrderedSet of NoteDocuments to a notification (didLoadNoteEntries:)
            NSMutableOrderedSet *noteEntriesList = [NSMutableOrderedSet orderedSet];
            NSMutableOrderedSet *noteDocsList = [NSMutableOrderedSet orderedSet];
            // we don't need a predicate to filter for docs with kNoteExtension
            // like we do when we load local files cause these urls are filtered
            // in the metadata query
            TKPromiseKeptBlock promiseKeptBlock = ^{
                // now we can pass to tableview and reload
                //[self performSelectorOnMainThread:@selector(didLoadNoteEntries:) withObject:openedDocsList waitUntilDone:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Number of docs: %d [%d]",noteDocsList.count,__LINE__);
                    
                    self.loadingComplete(noteEntriesList,noteDocsList);
                });
            };
            TKPromiseFailedBlock promiseFailedBlock = ^{
                //TODO can we get an error here?
                //TODO do this on the main thread, right?
                NSLog(@"promise failed %s [%d]",__PRETTY_FUNCTION__,__LINE__);
            };
            TKPromiseResolvedBlock promiseResolvedBlock = ^{
                iCloudFileLoadPromise = nil;
            };
            iCloudFileLoadPromise = [[TKPromise alloc] initWithPromiseKeptBlock:promiseKeptBlock
                                                             promiseFailedBlock:promiseFailedBlock
                                                           promiseResolvedBlock:promiseResolvedBlock
                                                                    commitments:nil];
            NSArray *absoluteFileURLs = [_iCloudURLs valueForKeyPath:@"absoluteString"];
            [iCloudFileLoadPromise addCommitments:[NSSet setWithArray:absoluteFileURLs]];
            
            for (NSURL * fileURL in _iCloudURLs) {
                NSLog(@"\n\nOpening doc with commitment: %@ [%d]\n\n",fileURL,__LINE__);
                [self loadDocAtURL:fileURL intoList:noteEntriesList docsList:noteDocsList promised:YES];
            }
            
        }
    }
    // just got everything from iCloud
    // so don't need to move anything local back up
    if (_moveLocalToiCloud) {
        _moveLocalToiCloud = NO;
        [self localToiCloudImpl];
    } else if (_copyiCloudToLocal) {
        _copyiCloudToLocal = NO;
        [self iCloudToLocalImpl];
    }
    [_query enableUpdates];
}

/*
 - (void) didLoadNoteEntries:(NSMutableOrderedSet *)entries
 {
 self.loadingComplete(entries,nil);
 }
 */

#pragma mark File management methods

- (void)loadDocAtURL:(NSURL *)fileURL intoList:(NSMutableOrderedSet *)list docsList:(NSMutableOrderedSet *)docsList promised:(BOOL)promised {
    
    // Open doc so we can read metadata
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];
    doc.noteEntry.adding = NO;
    [doc openWithCompletionHandler:^(BOOL success) {
        
        // Check status
        if (!success) {
            NSLog(@"Failed to open %@", fileURL);
            return;
        } else {
            NSLog(@"successfully opened a doc [%d]",__LINE__);
        }
        
        NoteEntry *entry = doc.noteEntry;
        NSLog(@"did it crash after this? %s [%d]",__PRETTY_FUNCTION__,__LINE__);
        if (list && docsList) {
            [list addObject:entry];
            [docsList addObject:doc];
        }
        
        if (promised) {
            // promise kept
            NSLog(@"Fulfilling promise for commitment: %@ [%d]",fileURL.absoluteString,__LINE__);
            [iCloudFileLoadPromise keepCommitment:fileURL.absoluteString];
        }
        
        // Close since we're done with it
        [doc closeWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
            
            // Add to the list of files on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addOrUpdateEntryWithURL:fileURL noteData:entry.noteData state:entry.state version:entry.version];
            });
        }];
    }];
    
}

- (NoteDocument *)insertNewEntryAtIndex:(int)index completion:(void(^)(NoteDocument *entry))completion
{
    
    [_query disableUpdates];
    NSURL * fileURL = [self getDocURL:[self getDocFilename:[NoteDocument uniqueNoteName] uniqueInLocalObjects:YES]];
    
    NoteDocument * doc = [[NoteDocument alloc] initWithFileURL:fileURL];
    
    [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            NSLog(@"Failed to create file at %@", fileURL);
            return;
        }
        
        // Add to the list of files on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [doc setEntryClosed];
            completion(doc);            
            [_objects insertObject:doc.noteEntry atIndex:index];
            [_query enableUpdates];
            
        });
    }];
    
    return doc;
}

- (void)deleteEntry:(NoteEntry *)entry withCompletion:(void (^)())completion
{
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
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 completion();
                                             });
                                             
                                         }];
    });
    
    // Fixup view
    [self removeEntryWithURL:entry.fileURL];
}

- (void)iCloudToLocalImpl {
    
    NSLog(@"iCloud => local impl");
    
    for (NSURL * fileURL in _iCloudURLs) {
        
        NSString * fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
        NSURL *destURL = [self getDocURL:[self getDocFilename:fileName uniqueInLocalObjects:YES]];
        
        // Perform copy on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newURL) {
                NSFileManager * fileManager = [[NSFileManager alloc] init];
                NSError * error;
                BOOL success = [fileManager copyItemAtURL:fileURL toURL:destURL error:&error];
                if (success) {
                    NSLog(@"Copied %@ to %@ (%d)", fileURL, destURL, [FileStorageState iCloudOn]);
#warning test this
                    [self loadDocAtURL:destURL intoList:nil docsList:nil promised:NO];
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
            NSURL *destURL = [self getDocURL:[self getDocFilename:fileName uniqueInLocalObjects:NO]];
            
            // Perform actual move in background thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSError * error;
                BOOL success = [[NSFileManager defaultManager] setUbiquitous:[FileStorageState iCloudOn] itemAtURL:fileURL destinationURL:destURL error:&error];
                if (success) {
                    NSLog(@"Moved %@ to %@", fileURL, destURL);
#warning test this
                    [self loadDocAtURL:fileURL intoList:nil docsList:nil promised:NO];
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

#pragma mark Helpers

- (NSURL *)localRoot {
    if (_localRoot != nil) {
        return _localRoot;
    }
    
    NSArray * paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    _localRoot = [paths objectAtIndex:0];
    return _localRoot;
}

- (NSString*)getDocFilename:(NSString *)prefix uniqueInLocalObjects:(BOOL)uniqueInLocalObjects {
    NSInteger docCount = 0;
    NSString* newDocName = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    BOOL first = YES;
    while (!done) {
        /*
         if (first) {
         first = NO;
         newDocName = [NSString stringWithFormat:@"%@.%@",
         prefix, kNoteExtension];
         } else {
         newDocName = [NSString stringWithFormat:@"%@ %d.%@",
         prefix, docCount, kNoteExtension];
         }
         */
        
        NSString *postfix = first ? @"" : [NSString stringWithFormat:@" %d",docCount];
        first = NO;
        
        newDocName = [NSString stringWithFormat:@"%@%@.%@",prefix,postfix,kNoteExtension];
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists;
        if (uniqueInLocalObjects) {
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

- (NSURL *)getDocURL:(NSString *)filename {
    if ([FileStorageState iCloudOn]) {
        NSURL * docsDir = [_iCloudRoot URLByAppendingPathComponent:@"Documents" isDirectory:YES];
        return [docsDir URLByAppendingPathComponent:filename];
    } else {
        return [self.localRoot URLByAppendingPathComponent:filename];
    }
}

@end
