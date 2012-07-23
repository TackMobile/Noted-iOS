//
//  NoteFileManager.h
//  Noted
//
//  Created by Tony Hillerson on 7/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NOTE_EXTENSION @"ntd"

@class NoteFileManager;

@protocol NoteFileManagerDelegate <NSObject>
@optional
- (void) fileManager:(NoteFileManager *)fileManager didLoadNoteEntries:(NSOrderedSet *)noteEntries;
- (void) fileManager:(NoteFileManager *)fileManager failedToLoadNoteEntriesFromICloudWithLocalNoteEntries:(NSOrderedSet *)noteEntries;
- (void) fileManager:(NoteFileManager *)fileManager failedToLoadNoteEntriesWithError:(NSError *)error;

@end

@interface NoteFileManager : NSObject

@property(nonatomic,strong) id<NoteFileManagerDelegate> delegate;

- (void) loadAllNoteEntriesFromICloud;
- (void) loadAllNoteEntriesFromLocal;

@end
