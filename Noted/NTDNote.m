//
//  NTDNote.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"
#import "NTDNoteDocument.h"
#import "NTDDropboxManager.h"
#import "NTDDropboxNote.h"
#import "NTDNote+ImplUtils.h"
#import "NTDInMemoryNote.h"

static Class PrivateImplentingClass;

NSString *const NTDNoteWasChangedNotification = @"NTDNoteWasChangedNotification";
NSString *const NTDNoteWasAddedNotification = @"NTDNoteWasAddedNotification";
NSString *const NTDNoteWasDeletedNotification = @"NTDNoteWasDeletedNotification";
NSString *const NTDNoteHasConflictNotification =@"NTDNoteHasConflictNotification";

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NTDNote

+ (void)initialize
{
    [self refreshStoragePreferences];
//     PrivateImplentingClass = [NTDNoteDocument class];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [PrivateImplentingClass allocWithZone:zone];
}

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *))handler
{
    [PrivateImplentingClass listNotesWithCompletionHandler:handler];
}

+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *note))handler
{
    [PrivateImplentingClass restoreNote:deletedNote completionHandler:handler];
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    [PrivateImplentingClass newNoteWithCompletionHandler:handler];
}

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler
{
    [self newNoteWithCompletionHandler:^(NTDNote *note) {
        NSParameterAssert(note);
        note.text = text;
        note.theme = theme;
        handler(note);
    }];
}

+ (void)newNotesWithTexts:(NSArray *)texts themes:(NSArray *)themes completionHandler:(void(^)(NSArray *notes))handler
{
    NSAssert(texts && themes && handler, @"All parameters must be non-nil");
    NSAssert(texts.count == themes.count, @"texts must be the same length as themes");
    
    NSMutableArray *_texts = [texts mutableCopy], *_themes = [themes mutableCopy];
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:texts.count];
    
    __block NTDVoidBlock retainedRecursiveBlock;
    NTDVoidBlock recursiveBlock = ^(){
        if (0==_texts.count) {
            handler(notes);
            retainedRecursiveBlock = nil;
        } else {
            NSString *text = [_texts lastObject];
            NTDTheme *theme = [_themes lastObject];
            [self newNoteWithText:text theme:theme completionHandler:^(NTDNote *note) {
                [notes insertObject:note atIndex:0];
                [_texts removeLastObject];
                [_themes removeLastObject];
                retainedRecursiveBlock();
            }];
        }
    };
    retainedRecursiveBlock = recursiveBlock;
    recursiveBlock();
}

static Class BackupImplementingClass;
+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    BackupImplementingClass = PrivateImplentingClass;
    PrivateImplentingClass = [NTDInMemoryNote class];
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    [NTDInMemoryNote reset];
    PrivateImplentingClass = BackupImplementingClass;
    BackupImplementingClass = Nil;
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

+ (void)refreshStoragePreferences
{
    if ([NTDDropboxManager isDropboxEnabled] && [NTDDropboxManager isDropboxLinked])
        PrivateImplentingClass = [NTDDropboxNote class];
    else
        PrivateImplentingClass = [NTDNoteDocument class];
}

+ (NSInteger)indexForNote:(NTDNote *)note amongNotes:(NSArray *)notes
{
    return [self indexForNote_:note amongNotes:notes];
}
@end
