//
//  NTDNote.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"
#import "NTDNoteDocument.h"

static Class PrivateSubclass;

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NTDNote

+ (void)initialize
{
    /* In the future, we'll probably look up some configuration variable
     and set this appropriately. */
    PrivateSubclass = [NTDNoteDocument class];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [PrivateSubclass allocWithZone:zone];
}

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *))handler
{
    [PrivateSubclass listNotesWithCompletionHandler:handler];
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    [PrivateSubclass newNoteWithCompletionHandler:handler];
}

@end
