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
#import <QuartzCore/QuartzCore.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>

@interface NTDWalkthroughViewController ()
@property (nonatomic, strong) NTDWalkthroughGestureIndicatorView *currentIndicatorView;
@property (nonatomic, strong) NTDWalkthroughModalView *currentModalView;
@end

@implementation NTDWalkthroughViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.userInteractionEnabled = NO;
    self.view.$origin = CGPointZero;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)beginDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    if (self.currentIndicatorView) [self.currentIndicatorView removeFromSuperview];
    if (self.currentModalView) [self.currentModalView removeFromSuperview];
    
    switch (step) {
        case NTDWalkthroughShouldBeginWalkthroughStep:
        case NTDWalkthroughCompletedStep:
            self.view.userInteractionEnabled = YES;
            break;
            
        default:
            self.view.userInteractionEnabled = NO;
            break;
    }

    self.currentIndicatorView = [NTDWalkthroughGestureIndicatorView gestureIndicatorViewForStep:step];
    [self.view addSubview:self.currentIndicatorView];
    
    
    if (step == NTDWalkthroughShouldBeginWalkthroughStep) {
        void(^promptHandler)(BOOL) = ^(BOOL userClickedYes) {
            if (userClickedYes) {
                [[NTDWalkthrough sharedWalkthrough] stepShouldEnd:NTDWalkthroughShouldBeginWalkthroughStep];
                [[NTDWalkthrough sharedWalkthrough] shouldAdvanceFromStep:NTDWalkthroughShouldBeginWalkthroughStep];
            } else {
                [[NTDWalkthrough sharedWalkthrough] endWalkthrough:NO];
            }
        };
        
        self.currentModalView = [[NTDWalkthroughModalView alloc] initWithStep:step handler:promptHandler];
        
    } else if (step == NTDWalkthroughCompletedStep) {
        void(^promptHandler)(BOOL) = ^(BOOL userClickedYes) {
            if (userClickedYes) {
                [[NTDWalkthrough sharedWalkthrough] stepShouldEnd:NTDWalkthroughCompletedStep];
                [[NTDWalkthrough sharedWalkthrough] shouldAdvanceFromStep:NTDWalkthroughCompletedStep];
            }
        };
        
        self.currentModalView = [[NTDWalkthroughModalView alloc] initWithStep:step handler:promptHandler];
    } else {
        self.currentModalView = [[NTDWalkthroughModalView alloc] initWithStep:step];
    }
    
    [self.view addSubview:self.currentModalView];
}

- (void)endDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    NSLog(@"hiding step %i", step);
    self.currentIndicatorView.layer.position = [[self.currentIndicatorView.layer presentationLayer] position];
    self.currentIndicatorView.shouldCancelAnimations = YES;
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.currentModalView.alpha = 0;
                         self.currentModalView.transform = CGAffineTransformMakeScale(1.3, 1.3);
                         self.currentIndicatorView.alpha = 0;
    } completion:^(BOOL finished) {
//        [self.currentModalView removeFromSuperview];
//        [self.currentIndicatorView removeFromSuperview];
    }];
}

@end
