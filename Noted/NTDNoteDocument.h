//
//  NTDNoteDocument.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"

@interface NTDNoteDocument : UIDocument
+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler;
+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *))handler;
+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
- (void)deleteWithCompletionHandler:(void (^)(BOOL success))completionHandler;

+ (NSURL *)notesDirectoryURL;

#if __NOTED_TESTS__
+ (BOOL)reset;
#endif
@end
