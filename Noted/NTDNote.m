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

static Class PrivateImplentingClass;

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NTDNote

+ (void)initialize
{
//    [self refreshStoragePreferences];
     PrivateImplentingClass = [NTDNoteDocument class];
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

+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    [PrivateImplentingClass backupNotesWithCompletionHandler:handler];
}

+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    [PrivateImplentingClass restoreNotesFromBackupWithCompletionHandler:handler];
}

+ (void)refreshStoragePreferences
{
    if ([NTDDropboxManager isDropboxEnabled] && [NTDDropboxManager isDropboxLinked])
        PrivateImplentingClass = [NTDDropboxNote class];
    else
        PrivateImplentingClass = [NTDNoteDocument class];
}
@end
