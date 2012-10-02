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

@interface ApplicationModel()
{
    BOOL _refreshingiCloudData;
}

@end

@implementation ApplicationModel

@synthesize currentNoteEntries=_currentNoteEntries;
@synthesize noteFileManager;
@synthesize selectedNoteIndex;

SHARED_INSTANCE_ON_CLASS_WITH_INIT_BLOCK(ApplicationModel, ^{
    
    return [[self alloc] init];
});

- (NoteFileManager *) noteFileManager {
    if (nil == noteFileManager) {
        noteFileManager = [[NoteFileManager alloc] init];
        noteFileManager.delegate = self;
        _refreshingiCloudData = NO;
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
    /*
     NSLog(@"Sort before:");
     for (NoteDocument *doc in set) {
     NSLog(@"%@: %@",doc.dateCreated,doc.text);
     }
     */
    
    [set sortUsingComparator:(NSComparator)^(id obj1, id obj2){
        
        NoteDocument *doc1 = (NoteDocument *)obj1;
        NoteDocument *doc2 = (NoteDocument *)obj2;
        
        return [doc2.dateCreated compare:doc1.dateCreated];
    }];
    
    /*
     NSLog(@"Sort after:");
     for (NoteDocument *doc in set) {
     NSLog(@"%@: %@",doc.dateCreated,doc.text);
     }
     */
    
    return set;
}

- (void)refreshNotes {
    
    if (_refreshingiCloudData) {
        return;
    }
    
    _refreshingiCloudData = YES;
    
    void(^refreshBlock)() = ^{
        [self.noteFileManager loadAllNoteEntriesFromPreferredStorage];
    };
    if ([FileStorageState shouldPrompt]) {
        
        [[NSNotificationCenter defaultCenter] addObserverForName:SHOULD_CREATE_NOTE object:nil queue:nil usingBlock:^(NSNotification *note){
            [self createNote];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:SHOULD_CREATE_NOTE object:nil];
            
        }];
        
        [self promptForPreferredStorageWithCompletion:^(){
            refreshBlock();
            [FileStorageState setPreferredStoragePrompted:YES];
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
    return [self.currentNoteEntries objectAtIndex:index];
}

- (NoteEntry *) noteAtSelectedNoteIndex {
    return [self noteAtIndex:selectedNoteIndex];
}

- (NoteDocument *)noteDocumentAtIndex:(int)index
{
    return [self.currentNoteEntries objectAtIndex:index];
}

- (NoteDocument *) previousNoteDocInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger previousIndex = (index == 0) ? count - 1 : index - 1;
    return [self noteDocumentAtIndex:previousIndex];
}

- (NoteEntry *) previousNoteInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger previousIndex = (index == 0) ? count - 1 : index - 1;
    return [self noteAtIndex:previousIndex];
}

- (NoteDocument *) nextNoteDocInStackFromIndex:(NSInteger)index {
    int count = [self.currentNoteEntries count];
    assert(index <= count);
    assert(index >= 0);
    NSInteger nextIndex = (index == count - 1) ? 0 : index + 1;
    return [self noteDocumentAtIndex:nextIndex];;
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

- (void) setCurrentNoteIndexToNextPriorToDelete {
    int count = [self.currentNoteEntries count] - 1;
    self.selectedNoteIndex = ((selectedNoteIndex+1) > count - 1) ? 0 : selectedNoteIndex;
}

- (void) setCurrentNoteIndexToPrevious {
    int count = [self.currentNoteEntries count];
    self.selectedNoteIndex = (selectedNoteIndex == 0) ? count - 1 : selectedNoteIndex - 1;
}

#pragma mark - CRUD

// when you don't need to know exactly when it's complete
- (void) createNote {
    [self createNoteWithCompletionBlock:nil];
}

- (void)createNoteWithCompletionBlock:(CreateNoteCompletionBlock)completion
{
    NSString *uniqueName = [NoteDocument uniqueNoteName];
    NSLog(@"Unique name for doc: %@",uniqueName);
    
    NoteEntry *noteEntry = [self.noteFileManager addNoteNamed:uniqueName withCompletionBlock:completion];

    [self.currentNoteEntries insertObject:noteEntry atIndex:0];
}

- (void) deleteNoteEntryAtIndex:(NSUInteger)index withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock
{
    NoteEntry *noteEntry = [self.currentNoteEntries objectAtIndex:index];
    [self deleteNoteEntry:noteEntry withCompletionBlock:callersCompletionBlock];
}

- (void) deleteNoteEntry:(NoteEntry *)noteEntry withCompletionBlock:(DeleteNoteCompletionBlock)callersCompletionBlock
{
    
    [self.currentNoteEntries removeObject:noteEntry];
    [self.noteFileManager deleteNoteEntry:noteEntry withCompletionBlock:callersCompletionBlock];
  
}

#pragma mark - Note File Manager Delegate

- (void) fileManager:(NoteFileManager *)fileManager didLoadNoteEntries:(NSMutableArray *)noteEntries {
    
    self.currentNoteEntries = [NSMutableOrderedSet orderedSetWithArray:noteEntries];
    _refreshingiCloudData = NO;
    NSLog(@"currentNoteEntries count: %d",self.currentNoteEntries.count);
    
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
