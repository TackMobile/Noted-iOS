//
//  NTDCollectionViewController+Walkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController+Walkthrough.h"
#import "NTDNote.h"
#import "NTDTheme.h"
#import "NTDWalkthroughGestureIndicatorView.h"

@implementation NTDCollectionViewController (Walkthrough)

- (void)willBeginWalkthrough:(NSNotification *)notification
{
    NSArray *initialNotes = @[
        @"Note 3",
        @"Note 2",
        @"Note 1"
    ];
    
    NSArray *initialThemes = @[
       [NTDTheme themeForColorScheme:NTDColorSchemeTack],
       [NTDTheme themeForColorScheme:NTDColorSchemeLime],
       [NTDTheme themeForColorScheme:NTDColorSchemeWhite]
    ];
        for (NTDNote *note in self.notes.copy) {
            [self.notes removeObject:note];
            [note deleteWithCompletionHandler:nil];
        }
        
        [NTDNote newNoteWithText:initialNotes[0] theme:initialThemes[0] completionHandler:^(NTDNote *note) {
            [self.notes insertObject:note atIndex:0];
            [NTDNote newNoteWithText:initialNotes[1] theme:initialThemes[1] completionHandler:^(NTDNote *note) {
                [self.notes insertObject:note atIndex:0];
                [NTDNote newNoteWithText:initialNotes[2] theme:initialThemes[2] completionHandler:^(NTDNote *note) {
                    [self.notes insertObject:note atIndex:0];
                    [self.collectionView reloadData];
                }];
            }];
        }];
        
}

- (void)didDeclineWalkthrough:(NSNotification *)notification
{
    
}

- (void)bindGestureRecognizers
{
    
}
@end
