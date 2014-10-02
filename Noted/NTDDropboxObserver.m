//
//  NTDDropboxObserver.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/20/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import <BlocksKit/BlocksKit.h>
#import "NTDDropboxObserver.h"
#import "NTDDropboxNote.h"
#import "NTDNote.h"

@interface NTDDropboxObserver()
@property (nonatomic, strong) NSMutableDictionary *fileToPathMap, *fileinfoToNoteMap, *filenameToNoteMap, *filenameToRecordMap;
@property (nonatomic, strong) dispatch_queue_t serial_queue;
@end

@implementation NTDDropboxObserver

+(instancetype)sharedObserver
{
    static dispatch_once_t onceToken;
    static NTDDropboxObserver *sharedObserver;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[self alloc] init];
    });
    return sharedObserver;
}

-(id)init
{
    if (self == [super init]) {
        [self clearMaps];
        self.serial_queue = dispatch_queue_create("NTDDropboxObserver Serial Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)clearMaps
{
    self.fileToPathMap = [NSMutableDictionary dictionary];
    self.fileinfoToNoteMap = [NSMutableDictionary dictionary];
    self.filenameToNoteMap = [NSMutableDictionary dictionary];
    self.filenameToRecordMap = [NSMutableDictionary dictionary];
}

-(void)stopObserving:(id)observed
{
    [observed removeObserver:self];
}

-(void)removeAllObservers
{
    for (DBFile *file in self.fileToPathMap.keyEnumerator) {
        [file removeObserver:self];
    }
    
    [[DBFilesystem sharedFilesystem] removeObserver:self];
    
    [self clearMaps];
}

-(BOOL)observeNote:(NTDDropboxNote *)note
{
    self.fileinfoToNoteMap[note.fileinfo] = note;
    self.filenameToNoteMap[[(NTDNote *)note filename]] = note;
    return YES;
}

-(BOOL)observeRootPath:(DBPath *)path
{
    __autoreleasing DBError *error;
    DBFilesystem *filesystem = [DBFilesystem sharedFilesystem];
    NSMutableArray *files = [[filesystem listFolder:path error:&error] mutableCopy];
    if (error || !files) {
        NSLog(@"%s: Couldn't get a list of files: %@", sel_getName(_cmd), error);
        return NO;
    }

    DBObserver observerBlock = ^{
        __autoreleasing DBError *error;
        NSArray *newFiles = [[DBFilesystem sharedFilesystem] listFolder:path error:&error];
        if (error || !files) {
            NSLog(@"%s: Couldn't get new list of files: %@", sel_getName(_cmd), error);
            return;
        }
        [self compare:files against:newFiles withResults:^(NSArray *insertedFiles, NSArray *updatedFiles, NSArray *deletedFiles) {
            NSLog(@"Searching for newly inserted, updated & deleted files. %lu vs %lu", (unsigned long)files.count, (unsigned long)newFiles.count);
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            for (DBFileInfo *fileinfo in insertedFiles) {
                [files addObject:fileinfo];
                NTDDropboxNote *note = [NTDDropboxNote noteFromFileInfo:fileinfo];
                if (self.filenameToRecordMap[note.filename]) {
                    note.metadata = self.filenameToRecordMap[note.filename];
                    [self.filenameToRecordMap removeObjectForKey:note.filename];
                }
                [self observeNote:note];
                [notificationCenter postNotificationName:NTDNoteWasAddedNotification object:note];
                NSLog(@"Found new inserted file: %@", fileinfo.path);
            }
            for (DBFileInfo *fileinfo in updatedFiles) {
                NSLog(@"Found new updated file: %@", fileinfo.path);
                DBFileInfo *fileinfoWithMatchingPath = [files bk_match:^BOOL(DBFileInfo *oldFileInfo) {
                    return ([fileinfo.path isEqual:oldFileInfo.path]);
                }];
                NTDDropboxNote *note = self.fileinfoToNoteMap[fileinfoWithMatchingPath];
                NSUInteger index = [files indexOfObject:fileinfoWithMatchingPath];
                if (index != NSNotFound) [files replaceObjectAtIndex:index withObject:fileinfo];
                if (note) {
                    [self.fileinfoToNoteMap removeObjectForKey:fileinfoWithMatchingPath];
                    self.fileinfoToNoteMap[fileinfo] = note;
                    DBFileStatus *newerStatus = note.file.newerStatus;
                    if (newerStatus.cached)
                        [notificationCenter postNotificationName:NTDNoteWasChangedNotification object:note];
                    else {
                        DBFile *file = note.file;
                        __weak typeof(file) weakFile = file;
                        NSObject *observer = [NSObject new];
                        [file addObserver:observer block:^{
                            if (weakFile.newerStatus.cached) {
                                [notificationCenter postNotificationName:NTDNoteWasChangedNotification object:note];
                                [weakFile removeObserver:observer];
                            }
                        }];
                    }
                }
            }
            for (DBFileInfo *fileinfo in deletedFiles) {
                [files removeObject:fileinfo];
                NSLog(@"Found new deleted file: %@", fileinfo.path);
                NTDDropboxNote *note = self.fileinfoToNoteMap[fileinfo];
                if (note) {
                    [notificationCenter postNotificationName:NTDNoteWasDeletedNotification object:note];
                    [self.fileinfoToNoteMap removeObjectForKey:fileinfo];
                    [self.filenameToNoteMap removeObjectForKey:note.filename];
                }
                
            }
        }];
    };
    return [filesystem addObserver:self forPathAndChildren:path block:^{
        dispatch_async(self.serial_queue, observerBlock);
    }];
}

-(void)compare:(NSArray *)oldArray against:(NSArray *)newArray withResults:(void(^)(NSArray *insertedFiles, NSArray *updatedFiles, NSArray *deletedFiles))differenceBlock
{
    NSMutableArray *insertedFiles = [NSMutableArray array];
    NSMutableArray *updatedFiles = [NSMutableArray array];
    NSMutableArray *deletedFiles = [NSMutableArray array];
    [deletedFiles addObjectsFromArray:oldArray];

    for (DBFileInfo *newFileInfo in newArray) {
        if ([oldArray containsObject:newFileInfo]) {
            [deletedFiles removeObject:newFileInfo];
            continue;
        }
        /* If our original array doesn't contain this new object, either it's path is different or another property is different.
         * If the path has remained the same, let's consider that an update, else it's an insert. */
        DBFileInfo *fileinfoWithMatchingPath = [oldArray bk_match:^BOOL(DBFileInfo *oldFileInfo) {
            return ([newFileInfo.path isEqual:oldFileInfo.path]);
        }];
        
        if (fileinfoWithMatchingPath) {
            [updatedFiles addObject:newFileInfo];
            [deletedFiles removeObject:fileinfoWithMatchingPath];
        } else {
            [insertedFiles addObject:newFileInfo];
        }
    }
    
    differenceBlock(insertedFiles, updatedFiles, deletedFiles);
}

- (void)observeDatastore:(DBDatastore *)datastore
{
    __weak DBDatastore *weakDatastore = datastore;
    DBObserver observerBlock = ^{
        LogDatastoreStatusDebug(weakDatastore);
        if (!(weakDatastore.status & DBDatastoreIncoming))
            return;
        NSDictionary *syncResults = [weakDatastore sync:nil];
        NSSet *changedRecords = syncResults[@"metadata"];
        for (DBRecord *changedRecord in changedRecords) {
            NSLog(@"Incoming Record #%@. Fields: %@", changedRecord.recordId, changedRecord.fields);
            // There are three cases we need to deal with. Insertion, Modification and Deletion.
            NTDDropboxNote *note = self.filenameToNoteMap[changedRecord[@"filename"]];

            /* Deletion
             * --------
             * Deletion of a metadata record implies that a note was deleted in another instance of Noted.
             * Since deletion of a metadata record corresponds with deletion of a note, we can simply wait
             * for -observeRootPath: to observe the note deletion.
             */
            if (changedRecord.isDeleted) {
                NSString *filename = changedRecord[@"filename"];
                if (filename) [self.filenameToRecordMap removeObjectForKey:filename];
                continue;
            }
            
            /* Insertion
             * ---------
             * Insertion of a metadata record implies that the user created a note in another instance of Noted.
             * There are two scenarios we need to deal with here: a) this notification has come before the filesystem-level notification
             * or b) this notification has come after the filesystem-level notification.
             *
             * A) We won't have a entry for this record in our mapping. We need to keep this record around and until the filesystem-level notification
             * comes through. Then we can associate the new text file with this record and have a successful sync.
             *
             * B) We will have an entry for this record in our mapping (we utilize serial dispatch queues to ensure this.) We need to set the note's underlying
             * metadata to this new record, then tell the UI to update. The latter step will be handled by the "Modification" case below.
             *
             */
            if (!note)
                self.filenameToRecordMap[changedRecord[@"filename"]] = changedRecord;
            
            // If this incoming record shares the same filename with an existing record, assume that we're in case B and overwrite local metadata.
            if (note && ![note.metadata.recordId isEqualToString:changedRecord.recordId]) {
                NSLog(@"Record ID collision: Incoming (%@), Existing (%@)", changedRecord.recordId, note.metadata.recordId);
                [note.metadata deleteRecord];
                note.metadata = changedRecord;
            }
            
            
            /* Modification
             * ------------
             * Modification of a metadata record implies that a note was modified in another instance of Noted.
             * That implies that a) the note text was changed, changing the headline; b) the note color was changed
             * or c) both.
             *
             * To trigger a UI change, we can send a NTDNoteWasChangedNotification notification.
             * Since the DBRecord underlying the note's metadata will change automatically, we don't need to do anything
             * else for the note to alter its internal state.
             */
            if (note) {
                [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasChangedNotification object:note];
            }
        }
    };
    [datastore addObserver:self block:^{
        dispatch_async(self.serial_queue, observerBlock);
    }];
}

void LogDatastoreStatusDebug(DBDatastore *datastore)
{
    NSMutableArray *states = [NSMutableArray new];
    DBDatastoreStatus status = datastore.status;
    if (status & DBDatastoreOutgoing) [states addObject:@"Outgoing"];
    if (status & DBDatastoreIncoming) [states addObject:@"Incoming"];
    if (status & DBDatastoreUploading) [states addObject:@"Uploading"];
    if (status & DBDatastoreDownloading) [states addObject:@"Downloading"];
    if (status & DBDatastoreConnected) [states addObject:@"Connected"];
    NSString *state = [states componentsJoinedByString:@" | "];
    NSLog(@"%@ %@", datastore, state);
}
@end