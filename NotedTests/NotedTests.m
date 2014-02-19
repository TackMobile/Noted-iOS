//
//  NotedTests.m
//  NotedTests
//
//  Created by Vladimir Fleurima on 2/14/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "NTDNote.h"
#import "NTDNoteDocument.h"
#import "NTDTheme.h"

SPEC_BEGIN(NTDNoteSpec)

describe(@"NTDNoteDocument", ^{
    it(@"should start empty", ^{
        __block NSUInteger noteCount;
        [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
            noteCount = notes.count;
        }];
        [[expectFutureValue(theValue(noteCount)) shouldEventually] beZero];
    });
    
    context(@"CRUD", ^{
        __block NTDNote *note;
        
        it (@"should save properties when creating notes", ^{
            NSString *noteText = @"ABC";
            NTDTheme *theme = [NTDTheme themeForColorScheme:NTDColorSchemeKernal];
            [NTDNote newNoteWithText:noteText theme:theme completionHandler:^(NTDNote *_note) {
                note = _note;
            }];
            [[expectFutureValue(note) shouldEventually] beNonNil];
            [[expectFutureValue(note.text) shouldEventually] equal:noteText];
            [[expectFutureValue(note.theme) shouldEventually] equal:theme];
        });
    });
});
SPEC_END
