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

@implementation ApplicationModel
@synthesize currentNoteEntries;

SHARED_INSTANCE_ON_CLASS_WITH_INIT_BLOCK(ApplicationModel, ^{
    return [[self alloc] init];
});

- (void) refreshNotes {
    // TODO add real implementation
    [self loadFakeNotes];
}

- (void) loadFakeNotes {
    NSMutableOrderedSet *notes = [NSMutableOrderedSet orderedSet];
    
    [notes addObject:[NoteEntry new]];
    [notes addObject:[NoteEntry new]];
    [notes addObject:[NoteEntry new]];
    [notes addObject:[NoteEntry new]];
    
    self.currentNoteEntries = notes;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
}

@end
