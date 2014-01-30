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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:NTDShakeToUndoDidShowModalKey])
        [self showShakeToUndoModal];
}

-(void)showShakeToUndoModal
{
    NSString *device = (IS_IPHONE) ? @"iPhone" : @"iPad";
    NSString *msg = [NSString stringWithFormat:@"You can restore the note you just deleted by shaking your %@.", device];
    NTDModalView *modalView = [[NTDModalView alloc] initwithMessage:msg buttons:@[@"OK"] dismissalHandler:^(NSUInteger index){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NTDShakeToUndoDidShowModalKey];
    }];
    [modalView show];
}
@end
