//
//  NotedModel.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "ApplicationModel.h"
#import "Utilities.h"
#import "NoteDocument.h"
#import "NoteEntry.h"
#import "NoteFileManager.h"
#import "NSString+Digest.h"
#import "FileStorageState.h"
#import "UIAlertView+Blocks.h"

@implementation ApplicationModel

@synthesize currentNoteEntries=_currentNoteEntries;
@synthesize currentNoteDocuments;
@synthesize noteFileManager;
@synthesize selectedNoteIndex;

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
    if (!_currentNoteEntries) {
        _currentNoteEntries = [[NSMutableOrderedSet alloc] init];
    }
   
    return _currentNoteEntries;
}

- (void)setCurrentNoteEntries:(NSMutableOrderedSet *)noteEntries
{
    _currentNoteEntries = [self sortEntries:noteEntries];
}

- (NSMutableOrderedSet *)sortEntries:(NSMutableOrderedSet *)set
{
    NSLog(@"Sort before:");
    for (NoteDocument *doc in set) {
        NSLog(@"%@: %@",doc.dateCreated,doc.text);
    }
    
    [set sortUsingComparator:(NSComparator)^(id obj1, id obj2){
        
        NoteDocument *doc1 = (NoteDocument *)obj1;
        NoteDocument *doc2 = (NoteDocument *)obj2;
        
        return [doc2.dateCreated compare:doc1.dateCreated];
    }];
    
    NSLog(@"Sort after:");
    for (NoteDocument *doc in set) {
        NSLog(@"%@: %@",doc.dateCreated,doc.text);
    }
    
    return set;
}

- (void)refreshNotes {
    
    
    [EZToastView showToastMessage:@"refreshing notes explicitly"];
    void(^refreshBlock)() = ^{
        [self.noteFileManager loadAllNoteEntriesFromPreferredStorage];
    };
    if ([FileStorageState shouldPrompt]) {
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"createNote" object:nil queue:nil usingBlock:^(NSNotification *note){
            [self createNote];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"createNote" object:nil];
            
        }];
        
        [self promptForPreferredStorageWithCompletion:^(){
            refreshBlock();
            [FileStorageState setPreferredStoragePrompted:YES];
        }];
        
    } else {
        [EZToastView showToastMessage:@"refreshing notes"];
        refreshBlock();
    }
}

- (void)promptForPreferredStorageWithCompletion:(void(^)())completionBlock
{
    RIButtonItem *iCloudButton = [RIButtonItem item];
    iCloudButton.label = @"Use iCloud";
    iCloudButton.action = ^{
        [FileStorageState setPreferredStorage:kTKiCloud];
        completionBlock();
    };
    
    RIButtonItem *localBtn = [RIButtonItem item];
    localBtn.label = @"Later";
    localBtn.action = ^{
        [FileStorageState setPreferredStorage:kTKlocal];
        completionBlock();
    };
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud is Available" message:@"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web." cancelButtonItem:nil otherButtonItems:localBtn,iCloudButton,nil];
    [alert show];
}

- (NoteEntry *) noteAtIndex:(int)index {
    return [[self noteDocumentAtIndex:index] noteEntry];
}

- (NoteEntry *) noteAtSelectedNoteIndex {
    return [[self noteDocumentAtIndex:selectedNoteIndex] noteEntry];
}

- (NoteDocument *)noteDocumentAtIndex:(int)index
{
    return [self.currentNoteEntries objectAtIndex:index];
}

- (NoteEntry *) previousNoteInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger previousIndex = (index == 0) ? count - 1 : index - 1;
    return [self noteAtIndex:previousIndex];
}

- (NoteEntry *) nextNoteInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger nextIndex = (index == count - 1) ? 0 : index + 1;
    return [self noteAtIndex:nextIndex];;
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
    [EZToastView showToastMessage:@"create note called"];
    NSString *uniqueName = [NoteDocument uniqueNoteName];

    CreateNoteCompletionBlock completionBlock = ^(NoteDocument *entry) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
    };
    
    NoteDocument *noteDoc = [self.noteFileManager addNoteNamed:uniqueName withCompletionBlock:completionBlock];
    [self.currentNoteEntries insertObject:noteDoc atIndex:0];
    
}

- (void) deleteNoteEntryAtIndex:(NSUInteger)index withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock
{
    NoteDocument *noteDoc = [self.currentNoteEntries objectAtIndex:index];
    [self deleteNoteEntry:noteDoc withCompletionBlock:callersCompletionBlock];
}

- (void) deleteNoteEntry:(NoteDocument *)noteDoc withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock {
    
    // in-memory model updated, notify ui
    [self.currentNoteEntries removeObject:noteDoc];
    
    [self.noteFileManager deleteNoteEntry:noteDoc withCompletionBlock:callersCompletionBlock];
    
}

#pragma mark - Note File Manager Delegate

- (void) fileManager:(NoteFileManager *)fileManager didLoadNoteEntries:(NSMutableOrderedSet *)noteEntries {
    
    self.currentNoteEntries = noteEntries;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
}

#pragma mark - Preferences

/*
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
 */


@end
