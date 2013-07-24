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
    NTDWalkthroughNumberOfSteps
};

@interface NTDWalkthrough : NSObject

+ (instancetype)sharedWalkthrough;
+ (void)initializeWalkthroughIfNecessary;
- (void)stepShouldEnd:(NTDWalkthroughStep)step;
- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step;
- (void)beginWalkthrough;
@end
