//
//  NTDCollectionViewController+Walkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <BlocksKit/NSObject+BlockObservation.h>
#import <FlurrySDK/Flurry.h>
#import "NTDCollectionViewController+Walkthrough.h"
#import "NTDWalkthroughGestureIndicatorView.h"
#import "NTDNote.h"
#import "NTDTheme.h"
#import "NTDListCollectionViewLayout.h"

@implementation NTDCollectionViewController (Walkthrough)

//TODO move this to the walkthrough class?
- (void)willBeginWalkthrough:(NSNotification *)notification
{
    if (self.collectionView.collectionViewLayout != self.listLayout) {
        [self updateLayout:self.listLayout animated:NO];
        self.collectionView.contentOffset = CGPointZero; /* a bit of a hack. */
    }
    dispatch_group_notify(self.note_refresh_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self hideOriginalNotes];
    });
    self.tokenRecognizerTable = [NSMapTable weakToStrongObjectsMapTable];
}

- (void)setEnabled:(BOOL)enabled forRecognizer:(UIGestureRecognizer *)recognizer
{
    [self setEnabled:enabled aggressively:!enabled forRecognizer:recognizer];
}

- (void)setEnabled:(BOOL)enabled aggressively:(BOOL)shouldBeADick forRecognizer:(UIGestureRecognizer *)recognizer
{
    NSString *previousToken = [self.tokenRecognizerTable objectForKey:recognizer];
    if (previousToken)
        [recognizer removeObserversWithIdentifier:previousToken];
    
    __block BOOL isSetting = NO;
    recognizer.enabled = enabled;
    if (shouldBeADick) {
        NSString *token = [recognizer addObserverForKeyPath:@"enabled" task:^(id sender) {
            if (!isSetting) {
                isSetting = YES;
                /* This call will trigger our block again, which is why we use the isSetting variable.
                 * Since the 2nd call to our block happens sequentially, we don't need to worry
                 * about concurrency issues. */
                [sender setEnabled:enabled];
                isSetting = NO;
            }
        }];
        [self.tokenRecognizerTable setObject:token forKey:recognizer];
    }
}

- (void)didAdvanceWalkthroughToStep:(NSNotification *)notification
{
    NTDWalkthroughStep step = [NTDWalkthrough.sharedWalkthrough currentStep];
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
            [self setEnabled:NO forRecognizer:self.selectCardGestureRecognizer];
            [self setEnabled:NO forRecognizer:self.removeCardGestureRecognizer];
            break;
            
        case NTDWalkthroughSwipeToCloseKeyboardStep:
            [self setEnabled:NO forRecognizer:self.pinchToListLayoutGestureRecognizer];
            [self setEnabled:NO forRecognizer:self.panCardGestureRecognizer];
            [self setEnabled:NO forRecognizer:self.twoFingerPanGestureRecognizer];
            [self setEnabled:NO forRecognizer:(UIGestureRecognizer *)self.visibleCell.settingsButton];
            break;
            
        case NTDWalkthroughTapOptionsStep:
            break;
            
        case NTDWalkthroughChangeColorsStep:
            [self setEnabled:NO forRecognizer:self.panCardWhileViewingOptionsGestureRecognizer];
            [self setEnabled:NO forRecognizer:self.tapCardWhileViewingOptionsGestureRecognizer];
            break;
            
        case NTDWalkthroughCloseOptionsStep:
            break;

        case NTDWalkthroughSwipeToLastNoteStep:
            [self setEnabled:YES forRecognizer:self.panCardGestureRecognizer];
            break;
        
        case NTDWalkthroughTwoFingerDeleteStep:
            [self setEnabled:YES forRecognizer:self.twoFingerPanGestureRecognizer];
            break;
            
        case NTDWalkthroughPinchToListStep:
            [self setEnabled:NO forRecognizer:self.twoFingerPanGestureRecognizer]; /* note: never re-enabled */
            [self setEnabled:YES forRecognizer:self.pinchToListLayoutGestureRecognizer];            
            break;
            
        case NTDWalkthroughOneFingerDeleteStep:
            [self setEnabled:NO forRecognizer:self.selectCardGestureRecognizer];
            self.listLayout.pullToCreateEnabled = NO;
            self.pullToCreateLabel.hidden = YES;
            break;
            
        default:
            break;
    }
}

- (void)willEndWalkthroughStep:(NSNotification *)notification
{
    NTDWalkthroughStep step = [NTDWalkthrough.sharedWalkthrough currentStep];
    switch (step) {
        case NTDWalkthroughShouldBeginWalkthroughStep:
            self.collectionView.userInteractionEnabled = NO;
        case NTDWalkthroughMakeANoteStep:
            [self setEnabled:YES forRecognizer:self.selectCardGestureRecognizer];
            [self setEnabled:YES forRecognizer:self.removeCardGestureRecognizer];
            break;
            
        case NTDWalkthroughSwipeToCloseKeyboardStep:
            [self setEnabled:YES forRecognizer:(UIGestureRecognizer *)self.visibleCell.settingsButton];
            break;
            
        case NTDWalkthroughTapOptionsStep:
            break;
            
        case NTDWalkthroughChangeColorsStep:
            [self setEnabled:YES forRecognizer:self.panCardWhileViewingOptionsGestureRecognizer];
            break;
            
        case NTDWalkthroughCloseOptionsStep:
            [self setEnabled:YES forRecognizer:self.tapCardWhileViewingOptionsGestureRecognizer];
            break;
            
        case NTDWalkthroughSwipeToLastNoteStep:
            break;
            
        case NTDWalkthroughTwoFingerDeleteStep:
            break;
            
        case NTDWalkthroughPinchToListStep:
            break;
            
        case NTDWalkthroughOneFingerDeleteStep:
            [self setEnabled:YES forRecognizer:self.selectCardGestureRecognizer];
            self.listLayout.pullToCreateEnabled = YES;
            self.pullToCreateLabel.hidden = NO;
            break;
            
        default:
            break;
    }
}

- (void)didEndWalkthrough:(NSNotification *)notification
{
    for (UIGestureRecognizer *recognizer in self.tokenRecognizerTable.keyEnumerator) {
        [recognizer removeObserversWithIdentifier:[self.tokenRecognizerTable objectForKey:recognizer]];
    }
    self.tokenRecognizerTable = nil;
    BOOL wasCompleted = [notification.userInfo[NTDDidCompleteWalkthroughUserInfoKey] boolValue];
    if (wasCompleted)
        [self restoreOriginalNotes];
}

- (void)bindGestureRecognizers
{
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.collectionView.panGestureRecognizer
                                                      forStep:NTDWalkthroughMakeANoteStep];
//    [NTDWalkthroughGestureIndicatorView bindControl:self.visibleCell.settingsButton
//                                             events:UIControlEventTouchUpInside
//                                            forStep:NTDWalkthroughTapOptionsStep];
//    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.panCardWhileViewingOptionsGestureRecognizer
//                                                      forStep:NTDWalkthroughCloseOptionsStep];
//    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.panCardGestureRecognizer
//                                                      forStep:NTDWalkthroughSwipeToLastNoteStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.twoFingerPanGestureRecognizer
                                                      forStep:NTDWalkthroughTwoFingerDeleteStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.pinchToListLayoutGestureRecognizer
                                                      forStep:NTDWalkthroughPinchToListStep];
    [NTDWalkthroughGestureIndicatorView bindGestureRecognizer:self.removeCardGestureRecognizer
                                                      forStep:NTDWalkthroughOneFingerDeleteStep];
}

- (void)closeNotesWithCompletionHandler:(void(^)())handler
{
    // flush pending file operations
    static dispatch_group_t close_group;
    close_group = dispatch_group_create();
    for (NTDNote *note in self.notes) {
        dispatch_group_enter(close_group);
        [note closeWithCompletionHandler:^(BOOL success) {
            dispatch_group_leave(close_group);
        }];
    }
    dispatch_group_notify(close_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        close_group = nil;
        handler();
    });
}

- (void)hideOriginalNotes
{    
    [self closeNotesWithCompletionHandler:^{
        [NTDNote backupNotesWithCompletionHandler:^(BOOL success) {
            if (success) {
                [self createWalkthroughNotes];
            } else {
                //TODO cancel walkthrough
                NSLog(@"Canceling walkthrough");
            }
        }];
    }];
}

- (void)restoreOriginalNotes
{
    [self closeNotesWithCompletionHandler:^{
        [NTDNote restoreNotesFromBackupWithCompletionHandler:^(BOOL success) {
            if (!success) {
                //TODO log this using analytics. this is a bad situation.
                NSLog(@"Couldn't restore notes backup....");
                [Flurry logError:@"Couldn't restore notes backup" message:nil error:nil];
            }
            [self reloadNotes];
        }];
    }];
}

- (void)createWalkthroughNotes
{
    NSArray *initialNotes = @[
                              @"“That’s been one of my mantras – focus and simplicity. Simple can be harder than complex. You have to work hard to get your thinking clean to make it simple. But it’s worth it in the end because once you get there, you can move mountains.” ― Steve Jobs",
                              @"“Good design is a lot like clear thinking made visual.” ― Edward Tufte",
                              @"“It is not a daily increase, but a daily decrease. Hack away at the inessentials.” ― Bruce Lee",
                              ];
    
    NSArray *initialThemes = @[
                               [NTDTheme themeForColorScheme:NTDColorSchemeShadow],
                               [NTDTheme themeForColorScheme:NTDColorSchemeTack],
                               [NTDTheme themeForColorScheme:NTDColorSchemeKernal]
                               ];

    [NTDNote newNotesWithTexts:initialNotes themes:initialThemes completionHandler:^(NSArray *notes) {
        self.notes = [notes mutableCopy];
        [self.collectionView reloadData];
        self.collectionView.userInteractionEnabled = YES;
    }];
}

@end
