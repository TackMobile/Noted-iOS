//
//  NTDCollectionViewController+Walkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <BlocksKit/NSObject+BlockObservation.h>
#import "NTDCollectionViewController+Walkthrough.h"
#import "NTDWalkthroughGestureIndicatorView.h"
#import "NTDNote.h"
#import "NTDTheme.h"
#import "NTDListCollectionViewLayout.h"

@implementation NTDCollectionViewController (Walkthrough)

//TODO move this to the walkthrough class?
- (void)willBeginWalkthrough:(NSNotification *)notification
{
    [self hideOriginalNotes];
    self.tokenRecognizerTable = [NSMapTable weakToStrongObjectsMapTable];        
}

- (void)didDeclineWalkthrough:(NSNotification *)notification
{
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

- (void)didCompleteWalkthrough:(NSNotification *)notification
{
    self.selectCardGestureRecognizer.enabled = YES;
    for (UIGestureRecognizer *recognizer in self.tokenRecognizerTable.keyEnumerator) {
        [recognizer removeObserversWithIdentifier:[self.tokenRecognizerTable objectForKey:recognizer]];
    }
    self.tokenRecognizerTable = nil;
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

- (NSURL *)walkthroughBackupDirectoryURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectoryURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *walkthroughBackupDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:@"WalkthroughBackup" isDirectory:YES];
    return walkthroughBackupDirectoryURL;
}

- (void)hideOriginalNotes
{    
    // flush pending file operations
    dispatch_group_t close_group = dispatch_group_create();
    int i = 0;
    for (NTDNote *note in self.notes) {
        i++;
        if (note.fileState == NTDNoteFileStateClosed) {
            NSLog(@"closed already (%d)", i);
            continue;
        }
        dispatch_group_enter(close_group);
        NSLog(@"entering group (%d), %d", i, [(UIDocument *)note documentState]);
        [note closeWithCompletionHandler:^(BOOL success) {
            NSLog(@"leaving group (%d), <%d>%@", i, success, note);
            dispatch_group_leave(close_group);
        }];
    }
    dispatch_group_notify(close_group, dispatch_get_main_queue(), ^{
        // create subfolder
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError __autoreleasing *error;
        [fileManager removeItemAtURL:[self walkthroughBackupDirectoryURL] error:nil];
        [fileManager createDirectoryAtURL:[self walkthroughBackupDirectoryURL]
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:&error];
        // move files
        if (error) {
            //TODO bail walkthrough
            NSLog(@"Couldn't hide original notes: %@", error);
        } else {
            //TODO wait until done
            [NTDNote moveNotesToDirectory:[self walkthroughBackupDirectoryURL] completionHandler:^(BOOL success) {
                self.notes = [NSMutableArray array];
                [self createWalkthroughNotes];
//                [self reloadNotes];
            }];
        }
    });
}

- (void)restoreOriginalNotes
{
    // for every file, delete
    for (NTDNote *note in self.notes.copy) {
        [self.notes removeObject:note];
        [note deleteWithCompletionHandler:nil];
    }

    [NTDNote restoreNotesFromDirectory:[self walkthroughBackupDirectoryURL] completionHandler:^(BOOL success) {
        [self reloadNotes];
    }];
}

- (void)createWalkthroughNotes
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

@end
