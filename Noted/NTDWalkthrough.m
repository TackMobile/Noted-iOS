//
//  NTDWalkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthrough.h"
#import "NTDWalkthroughViewController.h"

NSString *const NTDWillBeginWalkthroughNotification = @"NTDUserWillBeginWalkthroughNotification";
NSString *const NTDDidDeclineWalkthroughNotification = @"NTDUserDidDeclineWalkthroughNotification";
NSString *const NTDDidCompleteWalkthroughNotification = @"NTDUserDidCompleteWalkthroughNotification";
NSString *const NTDDidAdvanceWalkthroughToStepNotification = @"NTDDidAdvanceWalkthroughToStepNotification";

static NSString *const DidCompleteWalkthroughKey = @"DidCompleteWalkthroughKey";
static NTDWalkthrough *sharedInstance;

@interface NTDWalkthrough ()
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

- (void)promptUserToStartWalkthrough
{
    self.currentStep = NTDWalkthroughShouldBeginWalkthroughStep;
    
    self.viewController = [[NTDWalkthroughViewController alloc] init];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController.view addSubview:self.viewController.view];
    [self.viewController beginDisplayingViewsForStep:self.currentStep];
    NSLog(@"beginWalkthrough");
    [self performSelector:@selector(makeANote)
               withObject:nil
               afterDelay:1.0];
}

/* HACK */
- (void)makeANote
{
    [NSNotificationCenter.defaultCenter postNotificationName:NTDWillBeginWalkthroughNotification object:self];
    [self stepShouldEnd:NTDWalkthroughShouldBeginWalkthroughStep];
    [self shouldAdvanceFromStep:NTDWalkthroughShouldBeginWalkthroughStep];
}

- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step
{
    if (self.currentStep != step)
        return;
    self.currentStep++;
    if (self.currentStep == self.numberOfSteps) {
        [NSNotificationCenter.defaultCenter postNotificationName:NTDDidCompleteWalkthroughNotification object:self];
    } else {
        [self.viewController beginDisplayingViewsForStep:self.currentStep];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:NTDDidAdvanceWalkthroughToStepNotification object:self];
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
