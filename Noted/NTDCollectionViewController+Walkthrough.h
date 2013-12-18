//
//  NTDCollectionViewController+Walkthrough.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController.h"

@interface NTDCollectionViewController (Walkthrough)

- (void)willBeginWalkthrough:(NSNotification *)notification;
- (void)didAdvanceWalkthroughToStep:(NSNotification *)notification;
- (void)didEndWalkthrough:(NSNotification *)notification;
- (void)bindGestureRecognizers;
- (void)returnToListLayout;
@end
