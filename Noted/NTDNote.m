//
//  NTDNote.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"
#import "NTDNoteDocument.h"

static Class PrivateImplentingClass;

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NTDNote

+ (void)initialize
{
    /* In the future, we'll probably look up some configuration variable
     and set this appropriately. */
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

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    [PrivateImplentingClass newNoteWithCompletionHandler:handler];
}

+ (void)newNoteWithText:(NSString *)text theme:(NTDTheme *)theme completionHandler:(void(^)(NTDNote *note))handler
{
    [self newNoteWithCompletionHandler:^(NTDNote *note) {
        note.text = text;
        note.theme = theme;
        handler(note);
    }];
}

@end
