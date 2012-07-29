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

- (void) refreshNotes {
    [self.noteFileManager loadAllNoteEntriesFromLocal];
}

- (void) createNote {
    NSString *uniqueName = [NSString stringWithFormat:@"%@.%@", [NSString randomSHA1], NOTE_EXTENSION];
    CreateNoteCompletionBlock completionBlock = ^(NoteEntry *entry) {
        [self.currentNoteEntries addObject:entry];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
    };
    [self.noteFileManager addNoteNamed:uniqueName withCompletionBlock:completionBlock];
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
