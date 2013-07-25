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

//FOUNDATION_EXTERN NSString *const NTDNotification;
FOUNDATION_EXTERN NSString *const NTDUserWillBeginWalkthroughNotification;
FOUNDATION_EXTERN NSString *const NTDUserDidDeclineWalkthroughNotification;
FOUNDATION_EXTERN NSString *const NTDUserDidCompleteWalkthroughNotification;

@interface NTDWalkthrough : NSObject

+ (instancetype)sharedWalkthrough;
+ (void)initializeWalkthroughIfNecessary;
- (void)promptUserToStartWalkthrough;
- (void)stepShouldEnd:(NTDWalkthroughStep)step;
- (void)shouldAdvanceFromStep:(NTDWalkthroughStep)step;
@end
