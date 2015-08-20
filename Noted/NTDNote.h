//
//  NTDNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//TODO: add delegates/notifications for create, update, delete, list operations

#import <Foundation/Foundation.h>

@class NTDDeletedNotePlaceholder;

typedef NS_ENUM(NSInteger, NTDNoteFileState) {
    NTDNoteFileStateOpened = 0,
    NTDNoteFileStateClosed = 1 <<  0,
    NTDNoteFileStateError = 1 << 1
};

@class NTDTheme;

@interface NTDNote : NSObject

typedef void (^NTDNoteDefaultCompletionHandler)(BOOL success);

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler;
+ (void)getNoteByFilename:(NSString *)filename andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)updateNoteWithFilename:(NSString *)filename text:(NSString *)text andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNoteWithFilename:(NSString *)filename text:(NSString *)text andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *note))handler;
+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme filename:(NSString *)filename completionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNotesWithTexts:(NSArray *)texts themes:(NSArray *)themes completionHandler:(void(^)(NSArray *notes))handler;
+ (void)updateNoteWithText:(NSString *)text filename:(NSString *)filename completionHandler:(void(^)(NTDNote *note))handler;

+ (void)refreshStoragePreferences;
+ (NSInteger)indexForNote:(NTDNote *)note amongNotes:(NSArray *)notes;

- (void)openWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)closeWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)deleteWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)updateWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;

- (NSURL *)fileURL;
- (NSString *)filename;
- (NSString *)headline;
- (NSDate *)lastModifiedDate;
- (NTDNoteFileState)fileState;

- (NTDTheme *)theme;
- (NSString *)text;
- (void)setFilename:(NSString *)filename;
- (void)setTheme:(NTDTheme *)theme;
- (void)setText:(NSString *)text;
- (void)setLastModifiedDate:(NSDate *)date;

//- (id<NTDNoteDelegate>)delegate;
//- (void)setDelegate:(id<NTDNoteDelegate>)delegate;
@end

UIKIT_EXTERN NSString *const NTDNoteWasChangedNotification;
UIKIT_EXTERN NSString *const NTDNoteWasAddedNotification;
UIKIT_EXTERN NSString *const NTDNoteWasDeletedNotification;
UIKIT_EXTERN NSString *const NTDNoteHasConflictNotification;
