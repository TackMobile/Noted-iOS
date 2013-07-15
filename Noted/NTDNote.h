//
//  NTDNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//NOW: implement NTDNoteDocument using local file operations
//NOW: set up core data stack
//NOW: add file deletion
//LATER: add delegates/notifications for create, update, delete, list operations

#import <Foundation/Foundation.h>

@class NTDTheme;

@interface NTDNote : NSObject

typedef void (^NTDNoteDefaultCompletionHandler)();

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler;
+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler;

- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)deleteWithCompletionHandler:(void (^)(BOOL success))completionHandler;

- (NSURL *)fileURL;
- (NSString *)filename;
- (NSString *)headline;
- (NSDate *)lastModifiedDate;

- (NTDTheme *)theme;
- (NSString *)text;
- (void)setTheme:(NTDTheme *)theme;
- (void)setText:(NSString *)text;

//- (id<NTDNoteDelegate>)delegate;
//- (void)setDelegate:(id<NTDNoteDelegate>)delegate;
@end
