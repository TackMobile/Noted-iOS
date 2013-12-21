//
//  NTDDropboxObserver.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/20/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "NTDDropboxObserver.h"
#import "NTDDropboxNote.h"
#import "NTDNote.h"

@interface NTDDropboxObserver()
@property (nonatomic, strong) NSMutableDictionary *fileToPathMap, *fileinfoToNoteMap;
@end

@interface NSArray (NTDArrayComparison)

-(void)compareAgainst:(NSArray *)newArray withResults:(void(^)(NSIndexSet *insertedObjects, NSIndexSet *deletedObjects))differenceBlock;

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
        self.fileToPathMap = [NSMutableDictionary dictionary];
        self.fileinfoToNoteMap = [NSMutableDictionary dictionary];
    }
    return self;
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
    
    self.fileToPathMap = [NSMutableDictionary dictionary];
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
        [files compareAgainst:newFiles withResults:^(NSIndexSet *insertedObjects, NSIndexSet *deletedObjects) {
            NSLog(@"Searching for newly inserted & deleted files. %d vs %d", files.count, newFiles.count);
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            NSArray *insertedFiles = [newFiles objectsAtIndexes:insertedObjects];
            for (DBFileInfo *fileinfo in insertedFiles) {
                [files addObject:fileinfo];
                NTDDropboxNote *note = [NTDDropboxNote noteFromFileInfo:fileinfo];
                [notificationCenter postNotificationName:NTDNoteWasAddedNotification object:note];
                NSLog(@"Found new inserted file: %@", fileinfo.path);
            }
            NSArray *deletedFiles = [files objectsAtIndexes:deletedObjects];
            for (DBFileInfo *fileinfo in deletedFiles) {
                [files removeObject:fileinfo];
                NSLog(@"Found new deleted file: %@", fileinfo.path);
                NTDDropboxNote *note = self.fileinfoToNoteMap[fileinfo];
                if (note) {
                    [notificationCenter postNotificationName:NTDNoteWasDeletedNotification object:note];                    
                }
                
            }
        }];
        
    }];
}

-(BOOL)observeNote:(NTDDropboxNote *)note
{
    self.fileinfoToNoteMap[[note valueForKey:@"fileinfo"]] = note;
    return YES;
}

@end

@implementation NSArray (NTDArrayComparison)

-(void)compareAgainst:(NSArray *)newArray withResults:(void(^)(NSIndexSet *insertedObjects, NSIndexSet *deletedObjects))differenceBlock
{
    NSIndexSet *insertedObjects = [newArray indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ![self containsObject:obj];
    }];
    
    NSIndexSet *deletedObjects = [self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ![newArray containsObject:obj];
    }];

    differenceBlock(insertedObjects, deletedObjects);
}

@end