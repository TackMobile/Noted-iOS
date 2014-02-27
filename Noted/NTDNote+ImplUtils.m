//
//  NTDNote+ImplUtils.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <FlurrySDK/Flurry.h>
#import "NTDNote+ImplUtils.h"

@implementation NTDNote (ImplUtils)

+ (void)logError:(NSError *)error withMessage:(NSString *)message, ...;
{
    va_list passedInArgs, passedThroughArgs;
    va_start(passedInArgs, message);
    va_copy(passedThroughArgs, passedInArgs);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:passedThroughArgs];
#if DEBUG
    NSLog(@"%@: %@:", formattedMessage, error);
#endif
    [Flurry logError:@"NTDNoteError" message:message error:error];
}

+ (NSUInteger)indexFromFilename:(NSString *)filename
{
    /* Depends on filename structure as defined by +newFileURL */
    static NSUInteger NilIndex = 0;
    static NSRegularExpression *matcher;
    if (!matcher) {
        NSError __autoreleasing *error;
        matcher = [NSRegularExpression regularExpressionWithPattern:@"^Note ([0-9]+)$"
                                                            options:0
                                                              error:&error];
        if (error) return NilIndex;
    }
    
    filename = [filename stringByDeletingPathExtension];
    if (!filename || 0==filename.length) return NilIndex;
    
    NSTextCheckingResult *result = [matcher firstMatchInString:filename options:0 range:[filename rangeOfString:filename]];
    if (!result) return NilIndex;
    
    NSRange range = [result rangeAtIndex:1];
    if (NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) {
        return NilIndex;
    } else {
        return [[filename substringWithRange:range] integerValue];
    }
}

+ (NTDNoteComparator)comparatorUsingFilenames
{
    return ^NSComparisonResult(NTDNote *note1, NTDNote *note2) {
        NSUInteger i = [self indexFromFilename:note1.filename];
        NSUInteger j = [self indexFromFilename:note2.filename];
        
        if (i > j) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if (i < j) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    };
}

+ (NSInteger)indexForNote_:(NTDNote *)note amongNotes:(NSArray *)notes
{
    NTDNoteComparator dateComparator = ^NSComparisonResult(NTDNote *note1, NTDNote *note2) {
        return [note1.lastModifiedDate compare:note2.lastModifiedDate];
    };
    NTDNoteComparator comparatorUsingFilenamesAndDates = ^NSComparisonResult(NTDNote *note1, NTDNote *note2) {
        NSComparisonResult result = [self comparatorUsingFilenames](note1, note2);
        if (result == (NSComparisonResult)NSOrderedSame)
            return dateComparator(note1, note2);
        else
            return result;
    };
    for (NSInteger i = 0; i < notes.count; i++) {
        NSComparisonResult result = comparatorUsingFilenamesAndDates(note, notes[i]);
        if (result == (NSComparisonResult)NSOrderedAscending)
            continue;
        else
            return i;
    }
    return notes.count;
}

+ (NTDNoteDefaultCompletionHandler)handlerDispatchedToMainQueue:(NTDNoteDefaultCompletionHandler)handler
{
    return ^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) handler(success);
        });
    };
}

+(NSString *)headlineForString:(NSString *)text
{
    if (!text) {
        return @"";
    } else if (text.length < HeadlineLength) {
        return text;
    } else {
        return [text substringToIndex:HeadlineLength];
    }
}
@end
