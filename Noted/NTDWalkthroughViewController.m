//
//  NTDWalkthroughViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughViewController.h"
#import "NTDWalkthroughGestureIndicatorView.h"
#import "NTDWalkthroughModalView.h"

@interface NTDWalkthroughViewController ()
@property (nonatomic, strong) NTDWalkthroughGestureIndicatorView *currentIndicatorView;
@property (nonatomic, strong) NTDWalkthroughModalView *currentModalView;
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
    self.currentIndicatorView = [NTDWalkthroughGestureIndicatorView gestureIndicatorViewForStep:step];
    [self.view addSubview:self.currentIndicatorView];
    self.currentModalView = [[NTDWalkthroughModalView alloc] initWithStep:step];
    [self.view addSubview:self.currentModalView];
}

- (void)endDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    NSLog(@"hiding step %i", step);
    [UIView animateWithDuration:.1 animations:^{
        self.currentModalView.alpha = 0;
        self.currentModalView.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.currentIndicatorView.alpha = 0;
    } completion:^(BOOL finished) {
//        [self.currentModalView removeFromSuperview];
//        [self.currentIndicatorView removeFromSuperview];
    }];
}

@end
