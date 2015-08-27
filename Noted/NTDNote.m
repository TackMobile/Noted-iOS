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
#import "NTDNote+ImplUtils.h"

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

+ (void)getNoteByFilename:(NSString *)filename andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass getNoteByFilename:(NSString *)filename andCompletionHandler:(void(^)(NTDNote *))handler];
}

+ (void)getNoteDocumentByFilename:(NSString *)filename andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass getNoteDocumentByFilename:filename andCompletionHandler:handler];
}

+ (void)getNoteMetadataByDropboxRev:(NSString *)rev andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass getNoteMetadataByDropboxRev:rev andCompletionHandler:handler];
}

+ (void)getNoteDocumentByDropboxRev:(NSString *)rev andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass getNoteDocumentByDropboxRev:rev andCompletionHandler:handler];
}

+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *note))handler
{
    [PrivateImplentingClass restoreNote:deletedNote completionHandler:handler];
}

+ (NSURL *)notesDirectoryURL
{
    return [PrivateImplentingClass notesDirectoryURL];
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    [PrivateImplentingClass newNoteWithCompletionHandler:handler];
}

+ (void)newNoteWithFilename:(NSString *)filename text:(NSString *)text lastModifiedDate:(NSDate *)lastModifiedDate andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass newNoteWithFilename:filename text:text lastModifiedDate:lastModifiedDate andCompletionHandler:handler];
}

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler
{
    [self newNoteWithCompletionHandler:^(NTDNote *note) {
      if (note != nil) {
        NSParameterAssert(note);
        note.text = text;
        note.theme = theme;
        handler(note);
      }
    }];
}

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme lastModifiedDate:(NSDate *)lastModifiedDate filename:(NSString *)filename dropboxRev:(NSString *)rev dropboxClientMtime:(NSDate *)clientMtime completionHandler:(void(^)(NTDNote *note))handler
{
  [self newNoteWithFilename:filename text:text lastModifiedDate:lastModifiedDate andCompletionHandler:^(NTDNote *note) {
    if (note != nil) {
      NSParameterAssert(note);
      note.filename = filename;
      note.text = text;
      note.theme = theme;
      note.lastModifiedDate = lastModifiedDate;
      note.dropboxRev = rev;
      note.dropboxClientMtime = clientMtime;
      handler(note);
    }
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

+ (void)updateNoteWithDropboxMetadata:(NSString *)oldFilename newFilename:(NSString *)newFilename rev:(NSString *)rev clientMtime:(NSDate *)clientMtime lastModifiedDate:(NSDate *)lastModifiedDate completionHandler:(void(^)(NTDNote *note))handler
{
  if ([oldFilename isEqualToString:newFilename]) {
    [self getNoteByFilename:oldFilename andCompletionHandler:^(NTDNote *note) {
      if (note != nil) {
        note.dropboxRev = rev;
        note.dropboxClientMtime = clientMtime;
        note.lastModifiedDate = lastModifiedDate;
        handler(note);
      } else {
        handler(nil);
      }
    }];
  } else {
    [PrivateImplentingClass updateNoteWithFilename:oldFilename newFilename:newFilename text:nil lastModifiedDate:lastModifiedDate andCompletionHandler:^(NTDNote *note) {
      if (note != nil) {
        note.filename = newFilename;
        note.dropboxRev = rev;
        note.dropboxClientMtime = clientMtime;
        note.lastModifiedDate = lastModifiedDate;
        handler(note);
      } else {
        handler(nil);
      }
    }];
  }
}

+ (void)updateNoteWithFilename:(NSString *)filename text:(NSString *)text andCompletionHandler:(void(^)(NTDNote *))handler
{
  [PrivateImplentingClass updateNoteWithFilename:filename text:text andCompletionHandler:handler];
}

+ (void)updateNoteFromDropbox:(NSString *)rev filename:(NSString *)filename text:(NSString *)text clientMtime:(NSDate *)clientMtime lastUpdatedDate:(NSDate *)lastUpdatedDate completionHandler:(void(^)(NTDNote *note))handler
{
  [self getNoteDocumentByDropboxRev:rev andCompletionHandler:^(NTDNote *note) {
    if (note != nil) {
      note.filename = filename;
      note.text = text;
      note.dropboxClientMtime = clientMtime;
      note.dropboxRev = rev;
      note.lastModifiedDate = lastUpdatedDate;
    }
  }];
}

+ (void)updateNoteWithText:(NSString *)text filename:(NSString *)filename completionHandler:(void(^)(NTDNote *note))handler
{
  [self updateNoteWithFilename:filename text:text andCompletionHandler:^(NTDNote *note) {
    if (note != nil) {
      NSParameterAssert(note);
      note.text = text;
      handler(note);
    }
  }];
}

+ (void)deleteNoteWithFilename:(NSString *)filename completionHandler:(void(^)(BOOL success))handler
{
  [PrivateImplentingClass deleteNoteWithFilename:filename completionHandler:handler];
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
    PrivateImplentingClass = [NTDNoteDocument class];
}

+ (NSInteger)indexForNote:(NTDNote *)note amongNotes:(NSArray *)notes
{
    return [self indexForNote_:note amongNotes:notes];
}
@end
