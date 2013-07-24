//
//  NTDWalkthroughViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughViewController.h"
#import "NTDWalkthroughGestureIndicatorView.h"

@interface NTDWalkthroughViewController ()

@end

@implementation NTDWalkthroughViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.userInteractionEnabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)beginDisplayingViewsForStep:(NTDWalkthroughStep)step
{
//    NTDWalkthroughGestureIndicatorView *indicatorView = [NTDWalkthroughGestureIndicatorView gestureIndicatorViewForStep:step];
//    [self.view addSubview:indicatorView];
}

- (void)endDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    
}

@end
