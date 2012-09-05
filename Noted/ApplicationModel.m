//
//  NotedModel.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "ApplicationModel.h"
#import "Utilities.h"
#import "NoteEntry.h"
#import "NoteFileManager.h"
#import "NSString+Digest.h"
#import "StorageSettingsDefaults.h"
#import "UIAlertView+Blocks.h"

@implementation ApplicationModel
@synthesize currentNoteEntries, noteFileManager, selectedNoteIndex;

SHARED_INSTANCE_ON_CLASS_WITH_INIT_BLOCK(ApplicationModel, ^{
    
    return [[self alloc] init];
});

- (NoteFileManager *) noteFileManager {
    if (nil == noteFileManager) {
        noteFileManager = [[NoteFileManager alloc] init];
        noteFileManager.delegate = self;
    }
    return noteFileManager;
}


- (NSMutableOrderedSet *)currentNoteEntries
{
    if (!currentNoteEntries) {
        currentNoteEntries = [[NSMutableOrderedSet alloc] init];
    }
    
    return currentNoteEntries;
}


- (void) refreshNotes {
    void(^refreshBlock)() = ^{
        [self.noteFileManager loadAllNoteEntriesFromPreferredStorage];
    };
    if ([StorageSettingsDefaults shouldPrompt]) {
        [self promptForPreferredStorageWithCompletion:^(){
            refreshBlock();
            [StorageSettingsDefaults setPreferredStoragePrompted:YES];
        }];
        
    } else {
        refreshBlock();
    }
}

- (void)promptForPreferredStorageWithCompletion:(void(^)())completionBlock
{
    RIButtonItem *iCloudButton = [RIButtonItem item];
    iCloudButton.label = @"Use iCloud";
    iCloudButton.action = ^{
        [StorageSettingsDefaults setPreferredStorage:kTKiCloud];
        completionBlock();
    };
    
    RIButtonItem *localBtn = [RIButtonItem item];
    localBtn.label = @"Later";
    localBtn.action = ^{
        [StorageSettingsDefaults setPreferredStorage:kTKlocal];
        completionBlock();
    };
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud is Available" message:@"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web." cancelButtonItem:nil otherButtonItems:localBtn,iCloudButton,nil];
    [alert show];
}

- (NoteEntry *) noteAtSelectedNoteIndex {
    return [self.currentNoteEntries objectAtIndex:self.selectedNoteIndex];
}

- (NoteEntry *) previousNoteInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger previousIndex = (index == 0) ? count - 1 : index - 1;
    return [self.currentNoteEntries objectAtIndex:previousIndex];
}

- (NoteEntry *) nextNoteInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger nextIndex = (index == count - 1) ? 0 : index + 1;
    return [self.currentNoteEntries objectAtIndex:nextIndex];
}

- (void) setCurrentNoteIndexToNext {
    int count = [self.currentNoteEntries count];
    self.selectedNoteIndex = (selectedNoteIndex == count - 1) ? 0 : selectedNoteIndex + 1;
}

- (void) setCurrentNoteIndexToPrevious {
    int count = [self.currentNoteEntries count];
    self.selectedNoteIndex = (selectedNoteIndex == 0) ? count - 1 : selectedNoteIndex - 1;
}

#pragma mark - CRUD

- (void) createNote {
    NSString *uniqueName = [NSString stringWithFormat:@"%@.%@", [NSString randomSHA1], NOTE_EXTENSION];
    CreateNoteCompletionBlock completionBlock = ^(NoteEntry *entry) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
    };
    NoteEntry *entry = [self.noteFileManager addNoteNamed:uniqueName withCompletionBlock:completionBlock];
    [self.currentNoteEntries insertObject:entry atIndex:0];
}

- (void) deleteNoteEntryAtIndex:(NSUInteger)index withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock {
    NoteEntry *entry = [self.currentNoteEntries objectAtIndex:index];
    [self deleteNoteEntry:entry withCompletionBlock:callersCompletionBlock];
}

- (void) deleteNoteEntry:(NoteEntry *)entry withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock {
    [self.currentNoteEntries removeObject:entry];
    [self.noteFileManager deleteNoteEntry:entry withCompletionBlock:callersCompletionBlock];
}

#pragma mark - Note File Manager Delegate

- (void) fileManager:(NoteFileManager *)fileManager didLoadNoteEntries:(NSMutableOrderedSet *)noteEntries {
    self.currentNoteEntries = noteEntries;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
}

#pragma mark - Preferences

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


@end
