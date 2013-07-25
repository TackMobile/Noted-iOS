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
                    [self bindGestureRecognizers];
                    [self.collectionView reloadData];
                }];
            }];
        }];
        
}

- (void)didDeclineWalkthrough:(NSNotification *)notification
{
    
}

- (void)didAdvanceWalkthroughToStep:(NSNotification *)notification
{
    NTDWalkthroughStep step = [NTDWalkthrough.sharedWalkthrough currentStep];
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
            self.selectCardGestureRecognizer.enabled = NO;
            self.removeCardGestureRecognizer.enabled = NO;
            break;
            
        case NTDWalkthroughSwipeToCloseKeyboardStep:
            self.selectCardGestureRecognizer.enabled = YES;
            self.removeCardGestureRecognizer.enabled = YES;

            self.pinchToListLayoutGestureRecognizer.enabled = NO;
            self.panCardGestureRecognizer.enabled = NO;
            self.twoFingerPanGestureRecognizer.enabled = NO;
            self.collectionView.scrollEnabled = NO;
//            [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:[self.visibleCell.textView valueForKey:@"keyboardPanRecognizer"]
//                                                              forStep:NTDWalkthroughSwipeToCloseKeyboardStep];
            break;
            
        case NTDWalkthroughTapOptionsStep:
            break;
            
        case NTDWalkthroughChangeColorsStep:
            self.panCardWhileViewingOptionsGestureRecognizer.enabled = NO;
            self.tapCardWhileViewingOptionsGestureRecognizer.enabled = NO; /*no need to re-enable*/
            break;
            
        case NTDWalkthroughCloseOptionsStep:
            self.panCardWhileViewingOptionsGestureRecognizer.enabled = YES;
            
            break;

        case NTDWalkthroughSwipeToLastNoteStep:
            self.collectionView.scrollEnabled = YES;
            self.panCardGestureRecognizer.enabled = YES;
            
            break;
        
        case NTDWalkthroughTwoFingerDeleteStep:
            self.twoFingerPanGestureRecognizer.enabled = YES;
            
            break;
            
        case NTDWalkthroughPinchToListStep:
            self.pinchToListLayoutGestureRecognizer.enabled = YES;
            
            break;
            
        case NTDWalkthroughOneFingerDeleteStep:
            self.removeCardGestureRecognizer.enabled = YES;
            
            self.selectCardGestureRecognizer.enabled = NO;            
            break;
            
        default:
            break;
    }
}

- (void)didCompleteWalkthrough:(NSNotification *)notification
{
    self.selectCardGestureRecognizer.enabled = YES;
}

- (void)bindGestureRecognizers
{
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.collectionView.panGestureRecognizer
                                                      forStep:NTDWalkthroughMakeANoteStep];
    [NTDWalkthroughGestureIndicatorView bindControl:self.visibleCell.settingsButton
                                             events:UIControlEventTouchUpInside
                                            forStep:NTDWalkthroughTapOptionsStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.panCardWhileViewingOptionsGestureRecognizer
                                                      forStep:NTDWalkthroughCloseOptionsStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.panCardGestureRecognizer
                                                      forStep:NTDWalkthroughSwipeToLastNoteStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.twoFingerPanGestureRecognizer
                                                      forStep:NTDWalkthroughTwoFingerDeleteStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.pinchToListLayoutGestureRecognizer
                                                      forStep:NTDWalkthroughPinchToListStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.removeCardGestureRecognizer
                                                      forStep:NTDWalkthroughOneFingerDeleteStep];
}
@end
