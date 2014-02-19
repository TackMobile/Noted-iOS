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
    afterAll(^{
        [NTDNoteDocument reset];
    });

    it(@"should start empty", ^{
        __block NSUInteger noteCount;
        [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
            noteCount = notes.count;
        }];
        [[expectFutureValue(theValue(noteCount)) shouldEventually] beZero];
    });
    
    context(@"CRUD", ^{
        __block NTDNote *_note;
        
        it (@"should save properties when creating notes", ^{
            NSString *noteText = @"ABC";
            NTDTheme *theme = [NTDTheme themeForColorScheme:NTDColorSchemeKernal];
            [NTDNote newNoteWithText:noteText theme:theme completionHandler:^(NTDNote *note) {
                _note = note;
            }];
            [[expectFutureValue(_note) shouldEventually] beNonNil];
            [[expectFutureValue(_note.text) shouldEventually] equal:noteText];
            [[expectFutureValue(_note.theme) shouldEventually] equal:theme];
        });
        
        it (@"should work fine with large strings", ^{
            NSUInteger capacity = 10000;
            NSMutableString *noteText = [NSMutableString stringWithCapacity:capacity];
            NSString *dummyText = @"ABCDEFGHI\n";
            for (int i = 0; i < capacity/dummyText.length; i++)
                [noteText appendString:dummyText];
            [NTDNote newNoteWithText:noteText theme:DefaultTheme completionHandler:^(NTDNote *note) {
                _note = note;
            }];
            [[expectFutureValue(_note.text) shouldEventually] equal:noteText];
        });
    });
});
SPEC_END
