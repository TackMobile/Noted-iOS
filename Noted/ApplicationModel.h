//
//  NotedModel.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utilities.h"
#import "NoteFileManager.h"

#define kNoteListChangedNotification @"kNoteListChangedNotification"

@interface ApplicationModel : NSObject <NoteFileManagerDelegate>

DEFINE_SHARED_INSTANCE_METHODS_ON_CLASS(ApplicationModel);

@property(nonatomic,readonly) NoteFileManager *noteFileManager;
@property(nonatomic,strong) NSMutableOrderedSet *currentNoteEntries;
@property(nonatomic,assign) NSInteger selectedNoteIndex;

- (void) refreshNotes;

- (BOOL)iCloudOn;
- (void)setiCloudOn:(BOOL)on;
- (BOOL)iCloudWasOn;
- (void)setiCloudWasOn:(BOOL)on;
- (BOOL)iCloudPrompted;
- (void)setiCloudPrompted:(BOOL)prompted;

- (void) createNote;
- (void) deleteNoteEntryAtIndex:(NSUInteger)index withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock;
- (void) deleteNoteEntry:(NoteEntry *)entry withCompletionBlock:(DeleteNoteCompletionBlock)completionBlock;
    
@end
