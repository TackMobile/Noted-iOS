//
//  NoteFileManager.h
//  Noted
//
//  Created by Tony Hillerson on 7/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoteEntry.h"

@class NoteFileManager;

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
- (NoteEntry *) addNoteNamed:(NSString *)noteName withCompletionBlock:(CreateNoteCompletionBlock)block;
- (void) deleteNoteEntry:(NoteEntry *)entry withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock;
- (void)checkICloudAvailabilityWithCompletionBlock:(void (^)(BOOL available)) completionWithICloudAvailable;
    
@end
