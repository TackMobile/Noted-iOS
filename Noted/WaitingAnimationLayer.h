//
//  WaitingAnimationLayer.h
//  Noted
//
//  Created by Colin T.A. Gray on 9/8/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, WaitingAnimationState) {
    WaitingAnimationStateWaiting,
    WaitingAnimationStateExpand1,
    WaitingAnimationStateTransition2,
    WaitingAnimationStateTransition3,
    WaitingAnimationStateShrink3
};

@interface WaitingAnimationLayer : CALayer {
    CADisplayLink *displayLink;
    CGFloat startTime;
    CAShapeLayer *circle1;
    CAShapeLayer *circle2;
    CAShapeLayer *circle3;
    WaitingAnimationState state;
}

@end
