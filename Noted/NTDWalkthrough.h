//
//  NTDWalkthrough.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

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
