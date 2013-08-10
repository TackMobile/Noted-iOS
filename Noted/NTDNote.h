//
//  NTDNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//TODO: add delegates/notifications for create, update, delete, list operations

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NTDNoteFileState) {
    NTDNoteFileStateOpened = 0,
    NTDNoteFileStateClosed = 1 <<  0,
    NTDNoteFileStateError = 1 << 1
};

@class NTDTheme;

@interface NTDNote : NSObject

typedef void (^NTDNoteDefaultCompletionHandler)(BOOL success);

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler;
+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler;
+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler;
+ (void)moveNotesToDirectory:(NSURL *)directory completionHandler:(NTDNoteDefaultCompletionHandler)handler;
+ (void)restoreNotesFromDirectory:(NSURL *)directory completionHandler:(NTDNoteDefaultCompletionHandler)handler;

- (void)openWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)closeWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)deleteWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;

- (NSURL *)fileURL;
- (NSString *)filename;
- (NSString *)headline;
- (NSDate *)lastModifiedDate;
- (NTDNoteFileState)fileState;

- (NTDTheme *)theme;
- (NSString *)text;
- (void)setTheme:(NTDTheme *)theme;
- (void)setText:(NSString *)text;

//- (id<NTDNoteDelegate>)delegate;
//- (void)setDelegate:(id<NTDNoteDelegate>)delegate;
@end
