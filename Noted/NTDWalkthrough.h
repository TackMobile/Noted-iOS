//
//  NTDWalkthrough.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NTDWalkthroughStep)
{
    NTDWalkthroughShouldBeginWalkthroughStep = 0,
    NTDWalkthroughMakeANoteStep,
    NTDWalkthroughSwipeToCloseKeyboardStep,
    NTDWalkthroughTapOptionsStep,
    NTDWalkthroughChangeColorsStep,
    NTDWalkthroughCloseOptionsStep,
    NTDWalkthroughSwipeToLastNoteStep,
    NTDWalkthroughTwoFingerDeleteStep,
    NTDWalkthroughPinchToListStep,
    NTDWalkthroughOneFingerDeleteStep,
    NTDWalkthroughCompletedStep,
    NTDWalkthroughNumberOfSteps
};

FOUNDATION_EXTERN NSString *const NTDWillBeginWalkthroughNotification;
FOUNDATION_EXTERN NSString *const NTDDidEndWalkthroughNotification;
FOUNDATION_EXTERN NSString *const NTDDidCompleteWalkthroughUserInfoKey;
FOUNDATION_EXTERN NSString *const NTDWillEndWalkthroughStepNotification;
FOUNDATION_EXTERN NSString *const NTDDidAdvanceWalkthroughToStepNotification;

@interface NTDWalkthrough : NSObject

@property (nonatomic, assign) NSInteger numberOfSteps, currentStep;

+ (instancetype)sharedWalkthrough;
+ (BOOL)isCompleted;
+ (BOOL)hasLearnedAboutThemes;
- (void)promptUserToStartWalkthrough;
- (void)promptUserAboutThemes;
- (void)stepShouldEnd:(NTDWalkthroughStep)step;
- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step;
- (void)endWalkthrough:(BOOL)wasCompleted;
- (BOOL)isActive;
@end
