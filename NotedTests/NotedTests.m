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
    
    NTDTheme *const DefaultTheme = [NTDTheme themeForColorScheme:NTDColorSchemeWhite];
    
    beforeEach(^{
        [NTDNoteDocument reset];
    });

    it(@"should start empty", ^{
        __block NSUInteger noteCount;
        [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
            noteCount = notes.count;
        }];
        [[expectFutureValue(theValue(noteCount)) shouldEventually] beZero];
    });
    
    it (@"should save properties when creating notes", ^{
        __block NTDNote *_note;
        NSString *noteText = @"ABC";
        NTDTheme *theme = [NTDTheme themeForColorScheme:NTDColorSchemeKernal];
        [NTDNote newNoteWithText:noteText theme:theme completionHandler:^(NTDNote *note) {
            _note = note;
        }];
        [[expectFutureValue(_note) shouldEventually] beNonNil];
        [[expectFutureValue(_note.text) shouldEventually] equal:noteText];
        [[expectFutureValue(_note.theme) shouldEventually] equal:theme];
    });
});
SPEC_END
