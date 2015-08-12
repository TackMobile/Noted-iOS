//
//  NTDCollectionViewController+ShakeToUndoDelete.m
//  Noted
//
//  Created by Nick Place on 1/8/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "NTDCollectionViewController+ShakeToUndoDelete.h"
#import "NTDNote.h"
#import "NTDModalView.h"
#import "NTDWalkthrough.h"
#import "UIDeviceHardware.h"

static NSString *const NTDShakeToUndoDidShowModalKey = @"NTDShakeToUndoDidShowModalKey";

@implementation NTDCollectionViewController (ShakeToUndoDelete)

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    BOOL isWalkthroughActive = [[NTDWalkthrough sharedWalkthrough] isActive];
    BOOL isUserEditing = [self.visibleCell.textView isFirstResponder];
    if (motion == UIEventSubtypeMotionShake && !isUserEditing && !isWalkthroughActive) {
        [self restoreDeletedNote];
    } else {
        [super motionEnded:motion withEvent:event];
    }
}

-(void)showShakeToUndoModalIfNecessary
{
    BOOL isWalkthroughActive = [[NTDWalkthrough sharedWalkthrough] isActive];
    BOOL hasShownModal = [[NSUserDefaults standardUserDefaults] boolForKey:NTDShakeToUndoDidShowModalKey];
    BOOL isShowing = [NTDModalView isShowing];
    if (!hasShownModal && !isWalkthroughActive && !isShowing)
        [self performSelector:@selector(showShakeToUndoModal) withObject:nil afterDelay:.25];
}

-(void)showShakeToUndoModal
{
    if ([NTDModalView isShowing]) return; /* The modal was triggered again before the timer fired this selector. Just ignore. */
    NSString *device = [UIDeviceHardware deviceType];
    NSString *msg = [NSString stringWithFormat:@"You can restore the note you just deleted by shaking your %@.", device];

    AVPlayer *player = [AVPlayer playerWithURL:[[NSBundle mainBundle] URLForResource:@"ShakeToUndoAnimation" withExtension:@"mov"]];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = (CGRect){.origin = CGPointZero, .size.width = 220, .size.height = 190};
    [player play];
    
    id observer;
    NTDModalView *modalView = [[NTDModalView alloc] initWithMessage:msg
                                                              layer:playerLayer
                                                    backgroundColor:[UIColor blackColor]
                                                            buttons:@[@"OK"]
                                                   dismissalHandler:^(NSUInteger index) {
                                                       [NSUserDefaults.standardUserDefaults setBool:YES forKey:NTDShakeToUndoDidShowModalKey];
                                                       [NSUserDefaults.standardUserDefaults synchronize];
                                                       [NSNotificationCenter.defaultCenter removeObserver:observer];
    }];
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                 object:player.currentItem
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
                                                                  AVPlayerItem *p = [note object];
                                                                  [p seekToTime:kCMTimeZero];
                                                              }];
    [modalView show];
}
@end
