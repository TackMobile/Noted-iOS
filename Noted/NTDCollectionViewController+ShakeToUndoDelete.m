//
//  NTDCollectionViewController+ShakeToUndoDelete.m
//  Noted
//
//  Created by Nick Place on 1/8/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController+ShakeToUndoDelete.h"
#import "NTDNote.h"
#import "NTDModalView.h"
#import "NTDWalkthrough.h"
#import "UIDeviceHardware.h"

static NSString *const NTDShakeToUndoDidShowModalKey = @"NTDShakeToUndoDidShowModalKey";

@implementation NTDCollectionViewController (ShakeToUndoDelete)

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
    }
}


-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)    {
        [self restoreDeletedNote];
    }
}

-(void)showShakeToUndoModalIfNecessary
{
    BOOL isWalkthroughActive = [[NTDWalkthrough sharedWalkthrough] isActive];
    BOOL hasShownModal = [[NSUserDefaults standardUserDefaults] boolForKey:NTDShakeToUndoDidShowModalKey];
    BOOL isShowing = [NTDModalView isShowing];
    if (!hasShownModal && !isWalkthroughActive && !isShowing)
        [self performSelector:@selector(showShakeToUndoModal) withObject:nil afterDelay:NTDDefaultInitialModalDelay];
}

-(void)showShakeToUndoModal
{
    if ([NTDModalView isShowing]) return; /* The modal was triggered again before the timer fired this selector. Just ignore. */
    NSString *device = [UIDeviceHardware deviceType];
    NSString *msg = [NSString stringWithFormat:@"You can restore the note you just deleted by shaking your %@.", device];
    NTDModalView *modalView = [[NTDModalView alloc] initwithMessage:msg buttons:@[@"OK"] dismissalHandler:^(NSUInteger index){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NTDShakeToUndoDidShowModalKey];
    }];
    [modalView show];
}
@end
