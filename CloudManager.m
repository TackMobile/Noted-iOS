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

NSString *const kDeletedNotesArray = @"deletedNotesArray";

@interface CloudManager()
{
    NSMetadataQuery * _query;
    
    // array of NSURLs retrieved from iCloud
    NSMutableArray * _documentURLs;
    // array of NoteEntry objects in memory
    NSMutableArray *_noteEntryObjects;
    
    BOOL documentsReady;
    BOOL _moveLocalToiCloud;
    BOOL _copyiCloudToLocal;
    BOOL _iCloudAvailable;
    BOOL _deleting;
    
    NoteEntry *_deletedNoteEntry;
    
    NSURL *_localRoot;
    NSURL *_iCloudRoot;
    
    
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
    if (self = [super init]) {
        documentsReady = NO;
        _moveLocalToiCloud = NO;
        _copyiCloudToLocal = NO;
        _iCloudAvailable = NO;
        _deleting = NO;
        
        _noteEntryObjects = [[NSMutableArray alloc] init];
        _documentURLs = [[NSMutableArray alloc] init];
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
                if (available) {
                    available(YES);
                }
                
            });
        }
        else {
            [FileStorageState setiCloudOn:NO];
            //[FileStorageState setiCloudWasOn:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (available) {
                    available(NO);
                }
                
            });
        }
    });
}

#pragma mark Public interface methods

- (void)refreshWithCompleteBlock:(iCloudLoadingComplete)complete failBlock:(iCloudLoadingFailed)failed
{
    NSArray *syms = [NSThread  callStackSymbols];
    if ([syms count] > 1) {
        NSLog(@"caller: %@ ",[syms objectAtIndex:1]);
    } else {
        NSLog(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
    }
    
    self.loadingComplete = complete;
    
    documentsReady = NO;
    [_documentURLs removeAllObjects];
    //[_noteEntryObjects removeAllObjects];
    
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        _iCloudAvailable = available;
        
        if (!_iCloudAvailable) {
            
            [self handleRefreshForCloudUnavailable];
            
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
            NSLog(@"iCloudOn: %s",iCloudOn ? "YES" : "NO");
            BOOL iCloudWasOn = [FileStorageState iCloudWasOn];
            NSLog(@"iCloudWasOn: %s",iCloudWasOn ? "YES" : "NO");
            if (iCloudOn && !iCloudWasOn) {
                [self localToiCloud];
            }
            
            // If iCloud newly switched off, move iCloud docs to local
            if (!iCloudOn && iCloudWasOn) {
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

- (void)handleRefreshForCloudUnavailable
{
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
}

#pragma mark iCloud Query

- (void)startQuery {
    
    [self stopQuery];
    
    NSLog(@"Starting to watch iCloud dir...");
    
    _query = [self documentQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processFiles:)
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
    
    NSLog(@"%d is count of _documentURLs before delete of %@",_documentURLs.count,fileURL.lastPathComponent);
    
    int index = [self indexOfNoteEntryObjectWithFileURL:fileURL];
    
    if ([_documentURLs indexOfObject:fileURL] != NSNotFound){
        [_documentURLs removeObject:fileURL];
    } else {
        NSLog(@"not found [%i]",__LINE__);
    }
    
    NSLog(@"%d is count of _documentURLs after delete of %@",_documentURLs.count,fileURL.lastPathComponent);
    
    return index;
}

#pragma mark NoteEntry management methods

- (int)indexOfNoteEntryObjectWithFileURL:(NSURL *)fileURL {
    __block int retval = -1;
    [_noteEntryObjects enumerateObjectsUsingBlock:^(NoteEntry * entry, NSUInteger idx, BOOL *stop) {
        if ([entry.fileURL isEqual:fileURL]) {
            retval = idx;
            *stop = YES;
            entry = nil;
        }
    }];
    return retval;
}

- (void)addOrUpdateEntryWithURL:(NSURL *)fileURL noteData:(NoteData *)noteData state:(UIDocumentState)state version:(NSFileVersion *)version {
    int index = [self indexOfNoteEntryObjectWithFileURL:fileURL];
    
    // Not found, so add
    if (index == -1) {
        //NSLog(@"%@ [%d]",_noteEntryObjects,__LINE__);
        NoteEntry * entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        if ([_noteEntryObjects count]>0) {
            BOOL found = NO;
            for(int i = 0; i < [_noteEntryObjects count]; i++) {
                NoteEntry *anEntry = [_noteEntryObjects objectAtIndex:i];
                
                if ([entry.fileURL isEqual:anEntry.fileURL]) {
                    [_noteEntryObjects insertObject:entry atIndex:[_noteEntryObjects indexOfObject:anEntry]];
                    found = YES;
                    anEntry = nil;
                    break;
                }
            /*
             if (entry.noteData.noteLocation.intValue < anEntry.noteData.noteLocation.intValue) {
             [_noteEntryObjects insertObject:entry atIndex:[_noteEntryObjects indexOfObject:anEntry]];
             found = YES;
             anEntry = nil;
             break;
             }
             */
            }
            if (!found) {
                if (![self deletedNotesContainsNoteURL:entry.fileURL]) {
                    NSLog(@"adding %@ [%i]",entry.fileURL.lastPathComponent,__LINE__);
                    [_noteEntryObjects addObject:entry];
                }
            }
        } else {
            
            
            if (![self deletedNotesContainsNoteURL:entry.fileURL]) {
                NSLog(@"adding %@ [%i]",entry.fileURL.lastPathComponent,__LINE__);
                [_noteEntryObjects addObject:entry];
            }
        }
        
        entry = nil;
        
    }
    
    // Found, so edit
    else {
        
        NoteEntry * entry = [_noteEntryObjects objectAtIndex:index];
        entry.noteData = noteData;
        entry.state = state;
        entry.version = version;
        
        //[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

#pragma mark File management

- (NSString *)fileURLShorthand:(NSURL *)fileURL
{
    return [fileURL.absoluteString substringFromIndex:fileURL.absoluteString.length-10];
}


- (NSArray *)deletedNotes
{
    NSArray *deletedNotesURLS = [[NSUserDefaults standardUserDefaults] objectForKey:kDeletedNotesArray];
    if (deletedNotesURLS) {
        return deletedNotesURLS;
    }
    
    return nil;
}

- (void)saveDeletedNoteURL:(NSURL *)url
{
    NSMutableArray *deletedNotesURLS = [[[NSUserDefaults standardUserDefaults] objectForKey:kDeletedNotesArray] mutableCopy];
    if (!deletedNotesURLS) {
        deletedNotesURLS = [[NSMutableArray alloc] init];
    }
    
    [deletedNotesURLS addObject:url.absoluteString];
    
    [[NSUserDefaults standardUserDefaults] setObject:deletedNotesURLS forKey:kDeletedNotesArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeDeletedNoteURL:(NSURL *)url
{
    NSMutableArray *deletedNotesURLS = [[[NSUserDefaults standardUserDefaults] objectForKey:kDeletedNotesArray] mutableCopy];
    if (deletedNotesURLS) {
        if ([deletedNotesURLS containsObject:url.absoluteString]) {
            [deletedNotesURLS removeObject:url.absoluteString];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:deletedNotesURLS forKey:kDeletedNotesArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)deletedNotesContainsNoteURL:(NSURL *)url
{
    NSMutableArray *deletedNotesURLS = [[[NSUserDefaults standardUserDefaults] objectForKey:kDeletedNotesArray] mutableCopy];
    if (deletedNotesURLS) {
        if ([deletedNotesURLS containsObject:url.absoluteString]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)processFiles:(NSNotification *)notification
{
    // Always disable updates while processing results
    [_query disableUpdates];
    
    if (_deleting) {
        NSLog(@"preventing processing during deletion");
        return;
    }
    
    for (NSURL *url in _documentURLs) {
        NSLog(@"found %@",[self fileURLShorthand:url]);
    }
    
    NSMutableArray *discoveredFiles = [NSMutableArray array];
    
    // The query reports all files found, every time.
    NSArray * queryResults = [_query results];
    for (NSMetadataItem * result in queryResults) {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber * aBool = nil;
        
        // Don't include hidden files
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue]) {
            if (_deletedNoteEntry) {
                if ([_deletedNoteEntry.fileURL.lastPathComponent isEqualToString:fileURL.lastPathComponent]) {
                    NSLog(@"Re-adding a just-deleted doc from iCloud! [%i]",__LINE__);
                }
            }
            
            NSLog(@"adding %@ [%i]",fileURL.lastPathComponent,__LINE__);
            [discoveredFiles addObject:fileURL];
        }
    }
    
    // _documentURLs is an array of NSURLs
    [_documentURLs removeAllObjects];
    [_documentURLs addObjectsFromArray:discoveredFiles];
    NSLog(@"Found %d iCloud file URLS", _documentURLs.count);
    documentsReady = YES;
    
    if ([FileStorageState iCloudOn]) {
        // Remove deleted files
        // Iterate backwards because we need to remove items from the NoteEntries array
        
#ifdef DEBUG
        NSLog(@"Documents:");
        for (NSURL *url in _documentURLs) {
            NSLog(@"%@",url.lastPathComponent);
        }
        NSLog(@"\n\n");
        
        NSLog(@"Objects count: %i",_noteEntryObjects.count);
#endif
        
        NSArray *deletedURLS = [self deletedNotes];
        BOOL checkDeleted = !IsEmpty(deletedURLS);
                    
        for (int i = _documentURLs.count -1; i >= 0; --i) {
            
            NSURL *entryURL = [_documentURLs objectAtIndex:i];
            
            if (checkDeleted) {
                for (NSString *absPath in deletedURLS) {
                    NSURL *fileURL = [NSURL URLWithString:absPath];
                    
                    if ([entryURL isEqual:fileURL]) {
                        
                        NSLog(@"Possibly stale/deleted file: %@",entryURL.lastPathComponent);
                        [self removeEntryWithURL:entryURL];
                        
                        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                                [self performDeleteOnURL:entryURL withCompletionHandler:^{
                                    NSLog(@"check re-deletion of document %@",entryURL.lastPathComponent);
                                    [self removeDeletedNoteURL:entryURL];
                                }];
                            });
                        } else {
                            NSLog(@"Removing url from deleted docs that wasn't found in iCloud");
                            
                            [self removeDeletedNoteURL:entryURL];
                        }
                        
                        break;
                    }
                }
            }
         
        }
        
        if (_documentURLs.count==0) {
            // no docs found
            [_query enableUpdates];
            self.loadingComplete(nil);
            
            return;
            
        } else {
            
            [self loadDocuments];
                        
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
}

- (void)loadDocuments
{
    // we don't need a predicate to filter for docs with kNoteExtension
    // like we do when we load local files cause these urls are filtered
    // in the metadata query
    TKPromiseKeptBlock promiseKeptBlock = ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"Count of note entries in _noteEntryObjects: %d",_noteEntryObjects.count);
            self.loadingComplete(_noteEntryObjects);
        });
        
        [_query enableUpdates];
    };
    TKPromiseFailedBlock promiseFailedBlock = ^{
        //TODO can we get an error here?
        //TODO do this on the main thread, right?
        NSLog(@"promise failed %s [%d]",__PRETTY_FUNCTION__,__LINE__);
        [_query enableUpdates];
    };
    TKPromiseResolvedBlock promiseResolvedBlock = ^{
        iCloudFileLoadPromise = nil;
    };
    iCloudFileLoadPromise = [[TKPromise alloc] initWithPromiseKeptBlock:promiseKeptBlock
                                                     promiseFailedBlock:promiseFailedBlock
                                                   promiseResolvedBlock:promiseResolvedBlock
                                                            commitments:nil];
    NSArray *absoluteFileURLs = [_documentURLs valueForKeyPath:@"absoluteString"];
    [iCloudFileLoadPromise addCommitments:[NSSet setWithArray:absoluteFileURLs]];
    
    for (NSURL *fileURL in _documentURLs) {
        NSLog(@"\n\nOpening doc with commitment: %@ [%d]\n\n",fileURL.lastPathComponent,__LINE__);
        [self loadDocAtURL:fileURL promised:YES];
    }
}

#pragma mark File management methods

- (void)loadDocAtURL:(NSURL *)fileURL promised:(BOOL)promised {
    
    // Open doc so we can read metadata
    NoteDocument * savedDocument = [[NoteDocument alloc] initWithFileURL:fileURL];
    //doc.noteEntry.adding = NO;
    if (_deletedNoteEntry) {
        if ([savedDocument.fileURL.lastPathComponent isEqualToString:_deletedNoteEntry.fileURL.lastPathComponent]) {
            NSLog(@"opening the deleted note! [%i]",__LINE__);
            
        }
    }
    
    [savedDocument openWithCompletionHandler:^(BOOL success) {
        
        // Check status
        if (!success) {
            NSLog(@"Failed to open %@", fileURL);
            return;
        }
        
        NoteData *noteData = savedDocument.data; // decodes from file wrapper or creates brand new
        
        NSURL *fileURL = savedDocument.fileURL;
        UIDocumentState state = savedDocument.documentState;
        NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        //NoteEntry *entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
        
        [self addOrUpdateEntryWithURL:fileURL noteData:noteData state:state version:version];
        if (promised) {
            [iCloudFileLoadPromise keepCommitment:fileURL.absoluteString];
        }
        
        /*
         // Add to the list of files on main thread
         dispatch_async(dispatch_get_main_queue(), ^{
         
         NSLog(@"Count of note entries in _noteEntryObjects: %d",_noteEntryObjects.count);
         NSLog(@"1st object in _noteEntryObjects: %@, %@",[_noteEntryObjects objectAtIndex:0],NSStringFromClass([[_noteEntryObjects objectAtIndex:0] class]));
         });
         */
        
        // Close since we're done with it
        [savedDocument closeWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
            
        }];
    }];
    
}

- (NoteDocument *)insertNewEntry:(NoteEntry *)noteEntry atIndex:(int)index completion:(CloudManagerDocSaveCompleteBlock)completion
{
    
    [_query disableUpdates];
    [self stopQuery];
    
    NoteDocument *doc = [[NoteDocument alloc] initWithFileURL:noteEntry.fileURL];

    [doc saveToURL:noteEntry.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            NSLog(@"Failed to create file at %@", noteEntry.fileURL);
            return;
        }
        
        // Add to the list of files on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_noteEntryObjects insertObject:noteEntry atIndex:index];
            [_query enableUpdates];
            
            if (completion) {
                completion(doc);
            }
   
        });
    }];
    
    return doc;
}

- (void)deleteEntry:(NoteEntry *)entry withCompletion:(void (^)())completion
{
    //[_query disableUpdates];
    //[self stopQuery];
    
    [self saveDeletedNoteURL:entry.fileURL];
    
    //_deletedNoteEntry = entry;
    _deleting = YES;
    
    NSLog(@"%@",_documentURLs);
    NSLog(@"%@",_noteEntryObjects);
    
    int index = [self indexOfNoteEntryObjectWithFileURL:entry.fileURL];
    
    if (index != -1) {
        [_noteEntryObjects removeObjectAtIndex:index];
    } else {
        NSLog(@"fileUrl not found in _noteEntryObjects");
    }
    
    [self performDeleteOnURL:entry.fileURL withCompletionHandler:completion];
    
    /*
     // Wrap in file coordinator
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
     
     if (![[NSFileManager defaultManager] fileExistsAtPath:entry.fileURL.path])
     {
     NSLog(@"Ubiquitous file not found!");
     //return NO;
     }
     
     NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
     [fileCoordinator coordinateWritingItemAtURL:entry.fileURL
     options:NSFileCoordinatorWritingForDeleting
     error:nil
     byAccessor:^(NSURL* writingURL) {
     // Simple delete to start
     NSError *error;
     NSFileManager* fileManager = [[NSFileManager alloc] init];
     
     BOOL success;
     [fileManager setUbiquitous:NO itemAtURL:entry.fileURL destinationURL:nil error:&error];
     success = [fileManager removeItemAtURL:entry.fileURL error:&error];
     
     if (success) {
     
     NSLog(@"\n\nDid delete item at:\n%@\n\n",entry.fileURL);
     dispatch_async(dispatch_get_main_queue(), ^{
     completion();
     });
     } else {
     NSLog(@"Failed to delete item at %@",entry.fileURL);
     if (error) {
     NSLog(@"error deleting doc: %@",error.localizedDescription);
     }
     }
     
     _deleting = NO;
     [_query enableUpdates];
     
     //[self startQuery];
     }];
     });
     
     
     */
}

- (void)performDeleteOnURL:(NSURL *)fileURL withCompletionHandler:(void(^)())completion {
    // Wrap in file coordinator
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path])
        {
            NSLog(@"Ubiquitous file not found!");
            //return NO;
        }
        
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:fileURL
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:nil
                                         byAccessor:^(NSURL* writingURL) {
                                             // Simple delete to start
                                             NSError *error;
                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             
                                             BOOL success;
                                             //[fileManager setUbiquitous:NO itemAtURL:fileURL destinationURL:nil error:&error];
                                             success = [fileManager removeItemAtURL:writingURL error:&error];
                                             
                                             if (success) {
                                                 
                                                 NSLog(@"\n\nDid delete item at:\n%@\n\n",writingURL);
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     completion();
                                                 });
                                             } else {
                                                 NSLog(@"Failed to delete item at %@",writingURL);
                                                 if (error) {
                                                     NSLog(@"error deleting doc: %@",error.localizedDescription);
                                                 }
                                             }
                                             
                                             _deleting = NO;
                                             [_query enableUpdates];
                                         }];
    });

}

- (void)iCloudToLocalImpl {
    
    NSLog(@"iCloud => local impl");
    
    for (NSURL * fileURL in _documentURLs) {
        
        NSString *fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
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
                    [self loadDocAtURL:destURL promised:NO];
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
                    [self loadDocAtURL:fileURL promised:NO];
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
    if (documentsReady) {
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
    
    NSLog(@"yielding doc name of %@",newDocName);
    
    return newDocName;
}

- (BOOL)docNameExistsInObjects:(NSString *)docName {
    BOOL nameExists = NO;
    for (NoteEntry *entry in _noteEntryObjects) {
        if ([[entry.fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

- (BOOL)docNameExistsIniCloudURLs:(NSString *)docName {
    BOOL nameExists = NO;
    for (NSURL * fileURL in _documentURLs) {
        if ([[fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

- (NSURL *)getDocURL:(NSString *)filename {
    if ([FileStorageState iCloudOn]) {
        NSURL *docsDir = [_iCloudRoot URLByAppendingPathComponent:@"Documents" isDirectory:YES];
        NSURL *docURL = [docsDir URLByAppendingPathComponent:filename];
        return docURL;
    } else {
        return [self.localRoot URLByAppendingPathComponent:filename];
    }
}

#pragma mark Retrieving files utils

/*
 + (BOOL) isLocal: (NSString *) filename
 
 {
 if (!filename) return NO;
 NSURL *targetURL = [self localFileURL:filename];
 if (!targetURL) return NO;
 return [[NSFileManager defaultManager]
 fileExistsAtPath:targetURL.path];
 }
 
 + (BOOL) isUbiquitousData: (NSString *) filename
 forContainer: (NSString *) container
 {
 if (!filename) return NO;
 NSURL *targetURL = [self ubiquityDataFileURL:filename
 forContainer:container];
 if (!targetURL) return NO;
 return [[NSFileManager defaultManager]
 fileExistsAtPath:targetURL.path];
 }
 
 + (BOOL) isUbiquitousDocument: (NSString *) filename
 forContainer: (NSString *) container
 {
 if (!filename) return NO;
 NSURL *targetURL = [self ubiquityDocumentsFileURL:filename
 forContainer:container];
 if (!targetURL) return NO;
 return [[NSFileManager defaultManager]
 fileExistsAtPath:targetURL.path];
 }
 
 + (NSURL *) fileURL: (NSString *) filename
 forContainer:(NSString *)container
 {
 if ([self isLocal:filename])
 return [self localFileURL:filename];
 if ([self isUbiquitousDocument:filename
 forContainer:container])
 return [self ubiquityDocumentsFileURL:filename
 forContainer:container];
 if ([self isUbiquitousData:filename
 forContainer:container])
 return [self ubiquityDataFileURL:filename
 forContainer:container];
 return nil;
 }
 
 */
@end
