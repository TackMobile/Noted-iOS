//
//  NTDWalkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthrough.h"
#import "NTDWalkthroughViewController.h"

static NSString *const DidCompleteWalkthroughKey = @"DidCompleteWalkthroughKey";
static NTDWalkthrough *sharedInstance;

@interface NTDWalkthrough ()
@property (nonatomic, assign) NSInteger numberOfSteps, currentStep;
@property (nonatomic, strong) NTDWalkthroughViewController *viewController;
@end

@implementation NTDWalkthrough

+ (void)initializeWalkthroughIfNecessary
{
    BOOL didCompleteWalkthrough = [NSUserDefaults.standardUserDefaults boolForKey:DidCompleteWalkthroughKey];
    if (!didCompleteWalkthrough) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[NTDWalkthrough alloc] init];
            sharedInstance.numberOfSteps = NTDWalkthroughNumberOfSteps;
            sharedInstance.currentStep = -1;
        });
    }
}

+ (instancetype)sharedWalkthrough
{
    return sharedInstance;
}

- (void)beginWalkthrough
{
    self.currentStep = NTDWalkthroughShouldBeginWalkthroughStep;
    
    self.viewController = [[NTDWalkthroughViewController alloc] init];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController.view addSubview:self.viewController.view];
    [self.viewController beginDisplayingViewsForStep:NTDWalkthroughShouldBeginWalkthroughStep];
    NSLog(@"beginWalkthrough");
}

- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step
{
    if (self.currentStep != step);
        return;
    self.currentStep++;
    [self.viewController beginDisplayingViewsForStep:self.currentStep];
    NSLog(@"advancing to step: %d", self.currentStep);
}

- (void)stepShouldEnd:(NTDWalkthroughStep)step
{
    if (self.currentStep != step)
        return;
    [self.viewController endDisplayingViewsForStep:step];
    NSLog(@"stepShouldEnd: %d", self.currentStep);
}

@end
