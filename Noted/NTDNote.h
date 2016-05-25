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
+ (void)getNoteDocumentByFilename:(NSString *)filename andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)getNoteMetadataByDropboxRev:(NSString *)rev andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)getNoteDocumentByDropboxRev:(NSString *)rev andCompletionHandler:(void(^)(NTDNote *))handler;

+ (void)updateNoteWithFilename:(NSString *)filename text:(NSString *)text andCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)updateNoteWithFilename:(NSString *)oldFilename newFilename:(NSString *)newFilename text:(NSString *)text lastModifiedDate:(NSDate *)lastModifiedDate dropboxClientMtime:(NSDate *)clientMtime dropboxRev:(NSString *)rev andCompletionHandler:(void(^)(NTDNote *))handler;

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNoteWithFilename:(NSString *)filename text:(NSString *)text lastModifiedDate:(NSDate *)lastModifiedDate andCompletionHandler:(void(^)(NTDNote *))handler;

+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *note))handler;
+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme lastModifiedDate:(NSDate *)lastModifiedDate filename:(NSString *)filename dropboxRev:(NSString *)rev dropboxClientMtime:(NSDate *)clientMtime completionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNotesWithTexts:(NSArray *)texts themes:(NSArray *)themes completionHandler:(void(^)(NSArray *notes))handler;

+ (void)updateNoteWithDropboxMetadata:(NSString *)oldFilename newFilename:(NSString *)newFilename rev:(NSString *)rev clientMtime:(NSDate *)clientMtime lastModifiedDate:(NSDate *)lastModifiedDate completionHandler:(void(^)(NTDNote *note))handler;
+ (void)updateNoteWithText:(NSString *)text filename:(NSString *)filename completionHandler:(void(^)(NTDNote *note))handler;
+ (void)updateNoteFromDropbox:(NSString *)rev filename:(NSString *)filename text:(NSString *)text clientMtime:(NSDate *)clientMtime lastUpdatedDate:(NSDate *)lastUpdatedDate completionHandler:(void(^)(NTDNote *note))handler;

+ (void)deleteNoteWithFilename:(NSString *)filename completionHandler:(void(^)(BOOL success))handler;

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
- (NSDate *)dropboxClientMtime;
- (NSString *)dropboxRev;

- (NTDTheme *)theme;
- (NSString *)text;
- (void)setFilename:(NSString *)filename;
- (void)setTheme:(NTDTheme *)theme;
- (void)setText:(NSString *)text;
- (void)setLastModifiedDate:(NSDate *)date;
- (void)setDropboxClientMtime:(NSDate *)clientMtime;
- (void)setDropboxRev:(NSString *)rev;

@end

UIKIT_EXTERN NSString *const NTDNoteWasChangedNotification;
UIKIT_EXTERN NSString *const NTDNoteWasAddedNotification;
UIKIT_EXTERN NSString *const NTDNoteWasDeletedNotification;
UIKIT_EXTERN NSString *const NTDNoteHasConflictNotification;
