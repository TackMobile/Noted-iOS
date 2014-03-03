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
@property (nonatomic, strong) NSMutableDictionary *fileToPathMap, *fileinfoToNoteMap, *recordIdNoteMap;
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
    }
    return self;
}

-(void)clearMaps
{
    self.fileToPathMap = [NSMutableDictionary dictionary];
    self.fileinfoToNoteMap = [NSMutableDictionary dictionary];
    self.recordIdNoteMap = [NSMutableDictionary dictionary];
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

-(BOOL)observeRootPath:(DBPath *)path
{
    __autoreleasing DBError *error;
    DBFilesystem *filesystem = [DBFilesystem sharedFilesystem];
    NSMutableArray *files = [[filesystem listFolder:path error:&error] mutableCopy];
    if (error || !files) {
        NSLog(@"%s: Couldn't get a list of files: %@", sel_getName(_cmd), error);
        return NO;
    }

    return [filesystem addObserver:self forPathAndChildren:path block:^{
        __autoreleasing DBError *error;
        NSArray *newFiles = [[DBFilesystem sharedFilesystem] listFolder:path error:&error];
        if (error || !files) {
            NSLog(@"%s: Couldn't get new list of files: %@", sel_getName(_cmd), error);
            return;
        }
        [self compare:files against:newFiles withResults:^(NSArray *insertedFiles, NSArray *updatedFiles, NSArray *deletedFiles) {
            NSLog(@"Searching for newly inserted, updated & deleted files. %d vs %d", files.count, newFiles.count);
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            for (DBFileInfo *fileinfo in insertedFiles) {
                [files addObject:fileinfo];
                NTDDropboxNote *note = [NTDDropboxNote noteFromFileInfo:fileinfo];
                self.fileinfoToNoteMap[fileinfo] = note;
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
                }
                
            }
        }];
        
    }];
}

-(BOOL)observeNote:(NTDDropboxNote *)note
{
    self.fileinfoToNoteMap[note.fileinfo] = note;
    self.recordIdNoteMap[note.metadata.recordId] = note;
    return YES;
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
@end