//
//  NoteFileManager.h
//  Noted
//
//  Created by Tony Hillerson on 7/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NoteFileManager;
@class NoteDocument;
@class NoteEntry;

typedef void (^CreateNoteCompletionBlock)(NoteEntry *entry);
typedef void (^DeleteNoteCompletionBlock)();

@protocol NoteFileManagerDelegate <NSObject>
@optional
- (void) fileManager:(NoteFileManager *)fileManager didLoadNoteEntries:(NSMutableOrderedSet *)noteEntries;
- (void) fileManager:(NoteFileManager *)fileManager failedToLoadNoteEntriesFromICloudWithLocalNoteEntries:(NSMutableOrderedSet *)noteEntries;
- (void) fileManager:(NoteFileManager *)fileManager failedToLoadNoteEntriesWithError:(NSError *)error;

@end

@interface NoteFileManager : NSObject

@property(nonatomic,strong) id<NoteFileManagerDelegate> delegate;

- (void) loadAllNoteEntriesFromPreferredStorage;
- (NoteEntry *)addNoteNamed:(NSString *)noteName withCompletionBlock:(CreateNoteCompletionBlock)block;
- (void)deleteNoteEntry:(NoteEntry *)noteEntry withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock;
    
@end
