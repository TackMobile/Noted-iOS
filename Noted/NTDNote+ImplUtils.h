//
//  NTDNote+ImplUtils.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"

typedef NSComparisonResult(^NTDNoteComparator)(NTDNote *note1, NTDNote *note2);
static NSString *const NTDNoteFileExtension = @"txt";
static const NSUInteger HeadlineLength = 280;

@interface NTDNote (ImplUtils)

+ (void)logError:(NSError *)error withMessage:(NSString *)message, ...;
+ (NSUInteger)indexFromFilename:(NSString *)filename;
+ (NTDNoteComparator)comparatorUsingFilenames;
+ (NTDNoteDefaultCompletionHandler)handlerDispatchedToMainQueue:(NTDNoteDefaultCompletionHandler)handler;
+ (NSString *)headlineForString:(NSString *)text;
@end
