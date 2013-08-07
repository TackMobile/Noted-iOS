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
NSString *const NTDDidDeclineWalkthroughNotification = @"NTDUserDidDeclineWalkthroughNotification";
NSString *const NTDDidCompleteWalkthroughNotification = @"NTDUserDidCompleteWalkthroughNotification";
NSString *const NTDDidAdvanceWalkthroughToStepNotification = @"NTDDidAdvanceWalkthroughToStepNotification";
NSString *const NTDWillEndWalkthroughStepNotification = @"NTDWillEndWalkthroughStepNotification";

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
    UICollectionViewController *rootController = (UICollectionViewController *)window.rootViewController;
    [rootController.view addSubview:self.viewController.view];
//    self.viewController.view.layer.transform = CATransform3DMakeTranslation(0, 0, CGFLOAT_MAX);
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
}

- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step
{
    if (self.currentStep != step)
        return;
    self.currentStep++;
    if (self.currentStep == self.numberOfSteps) {
        [NSNotificationCenter.defaultCenter postNotificationName:NTDDidCompleteWalkthroughNotification object:self];
        [self completeWalkthrough];
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
    [NSNotificationCenter.defaultCenter postNotificationName:NTDWillEndWalkthroughStepNotification object:self];
    NSLog(@"stepShouldEnd: %d", self.currentStep);
}

- (void)completeWalkthrough {
    [NSNotificationCenter.defaultCenter postNotificationName:NTDDidCompleteWalkthroughNotification object:self];
    //        [NSUserDefaults.standardUserDefaults setBool:YES forKey:DidCompleteWalkthroughKey];
    //        [NSUserDefaults.standardUserDefaults synchronize];
    [self.viewController.view removeFromSuperview];
    self.viewController = nil;
}

@end
