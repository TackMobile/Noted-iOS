//
//  NTDWalkthrough.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthrough.h"
#import "NTDWalkthroughViewController.h"
#import <QuartzCore/QuartzCore.h>

NSString *const NTDWillBeginWalkthroughNotification = @"NTDUserWillBeginWalkthroughNotification";
NSString *const NTDDidEndWalkthroughNotification = @"NTDUserDidCompleteWalkthroughNotification";
NSString *const NTDDidCompleteWalkthroughUserInfoKey = @"NTDDidCompleteWalkthroughKey";
NSString *const NTDDidAdvanceWalkthroughToStepNotification = @"NTDDidAdvanceWalkthroughToStepNotification";
NSString *const NTDWillEndWalkthroughStepNotification = @"NTDWillEndWalkthroughStepNotification";

static NSString *const DidCompleteWalkthroughKey = @"DidCompleteWalkthroughKey";
static NTDWalkthrough *sharedInstance;

@interface NTDWalkthrough ()
@property (nonatomic, strong) NTDWalkthroughViewController *viewController;
@end

@implementation NTDWalkthrough

+ (instancetype)sharedWalkthrough
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NTDWalkthrough alloc] init];
        sharedInstance.numberOfSteps = NTDWalkthroughNumberOfSteps;
        sharedInstance.currentStep = -1;
    });
    return sharedInstance;
}

+ (BOOL)isCompleted
{
    BOOL didCompleteWalkthrough = [NSUserDefaults.standardUserDefaults boolForKey:DidCompleteWalkthroughKey];
    return didCompleteWalkthrough;
}

- (void)promptUserToStartWalkthrough
{
    self.currentStep = NTDWalkthroughShouldBeginWalkthroughStep;
    self.viewController = [[NTDWalkthroughViewController alloc] init];

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UICollectionViewController *rootController = (UICollectionViewController *)window.rootViewController;
    [rootController.view addSubview:self.viewController.view];

    [self.viewController beginDisplayingViewsForStep:self.currentStep];
}

- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step
{
    if (self.currentStep != step)
        return;
    
    if (step == NTDWalkthroughShouldBeginWalkthroughStep) {
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:DidCompleteWalkthroughKey];
        [NSNotificationCenter.defaultCenter postNotificationName:NTDWillBeginWalkthroughNotification object:self];
    }
    
    self.currentStep++;
    
    if (self.currentStep == self.numberOfSteps) {
        [self endWalkthrough:YES];
    } else {
        [self.viewController beginDisplayingViewsForStep:self.currentStep];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:NTDDidAdvanceWalkthroughToStepNotification object:self];
//    NSLog(@"advancing to step: %d", self.currentStep);
}

- (void)stepShouldEnd:(NTDWalkthroughStep)step
{
    if (self.currentStep != step)
        return;
    [self.viewController endDisplayingViewsForStep:step];
    [NSNotificationCenter.defaultCenter postNotificationName:NTDWillEndWalkthroughStepNotification object:self];
//    NSLog(@"stepShouldEnd: %d", self.currentStep);
}

- (void)endWalkthrough:(BOOL)wasCompleted
{
    [NSNotificationCenter.defaultCenter postNotificationName:NTDDidEndWalkthroughNotification
                                                      object:self
                                                    userInfo:@{NTDDidCompleteWalkthroughUserInfoKey : @(wasCompleted)}];
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:DidCompleteWalkthroughKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self.viewController.view removeFromSuperview];
    self.viewController = nil;
}

@end
