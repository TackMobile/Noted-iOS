//
//  WaitingAnimationLayer.m
//  Noted
//
//  Created by Colin T.A. Gray on 9/8/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "WaitingAnimationLayer.h"

CGFloat waitingDuration = 0.25;
CGFloat transitionDuration = 0.25;

@implementation WaitingAnimationLayer

- (id) init {
    if ( self = [super init] ) {
        startTime = -1;
        state = WaitingAnimationStateWaiting;

        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

        circle1 = [CAShapeLayer layer];
        circle1.frame = (CGRect){{0, 0}, {10.5, 10.5}};
        circle2 = [CAShapeLayer layer];
        circle2.frame = (CGRect){{0, 0}, {10.5, 10.5}};
        circle3 = [CAShapeLayer layer];
        circle3.frame = (CGRect){{0, 0}, {10.5, 10.5}};
        CGPathRef circle_path = CGPathCreateWithEllipseInRect((CGRect){{0,0}, {10.5, 10.5}}, NULL);
        circle1.path = circle_path;
        circle2.path = circle_path;
        circle3.path = circle_path;
        CGPathRelease(circle_path);

        for ( CAShapeLayer *circle in @[circle1, circle2, circle3]) {
            circle.fillColor = UIColor.whiteColor.CGColor;
            circle.strokeColor = nil;
            circle.anchorPoint = (CGPoint){0.5, 0.5};
            [self addSublayer:circle];
        }
    }
    return self;
}

- (void) dealloc {
    [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    displayLink = nil;
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updatePositions];
}

- (void) updatePositions { 
    CGFloat center_x = self.frame.size.width / 2,
            center_y = self.frame.size.height / 2,
            margin = 27;
    circle1.position = (CGPoint){center_x - margin, center_y};
    circle2.position = (CGPoint){center_x, center_y};
    circle3.position = (CGPoint){center_x + margin, center_y};
}

- (void) update {
    CGFloat currentTime = [displayLink timestamp];
    if ( startTime == -1 ) {
        startTime = currentTime;
    }
    CGFloat time = currentTime - startTime;

    switch ( state ) {
    case WaitingAnimationStateWaiting:
        if ( time >= waitingDuration ) {
            state = WaitingAnimationStateExpand1;
            startTime = currentTime;
            time = 0;
        }
        break;
    case WaitingAnimationStateExpand1:
        if ( time >= transitionDuration ) {
            state = WaitingAnimationStateTransition2;
            startTime = currentTime;
            time = 0;
        }
        break;
    case WaitingAnimationStateTransition2:
        if ( time >= transitionDuration ) {
            state = WaitingAnimationStateTransition3;
            startTime = currentTime;
            time = 0;
        }
        break;
    case WaitingAnimationStateTransition3:
        if ( time >= transitionDuration ) {
            state = WaitingAnimationStateShrink3;
            startTime = currentTime;
            time = 0;
        }
        break;
    case WaitingAnimationStateShrink3:
        if ( time >= transitionDuration ) {
            state = WaitingAnimationStateWaiting;
            startTime = currentTime;
            time = 0;
        }
        break;
    }

    CGFloat scaleUp, scaleDown;
    CGFloat scaleAmt = 1.5;
    scaleUp = 1 + scaleAmt * time / transitionDuration;
    scaleDown = (1 + scaleAmt) - scaleAmt * time / transitionDuration;
    switch ( state ) {
    case WaitingAnimationStateWaiting:
        [circle1 setValue:@1 forKeyPath:@"transform.scale"];
        [circle2 setValue:@1 forKeyPath:@"transform.scale"];
        [circle3 setValue:@1 forKeyPath:@"transform.scale"];
        break;
    case WaitingAnimationStateExpand1:
        [circle1 setValue:@(scaleUp) forKeyPath:@"transform.scale"];
        [circle2 setValue:@1 forKeyPath:@"transform.scale"];
        [circle3 setValue:@1 forKeyPath:@"transform.scale"];
        break;
    case WaitingAnimationStateTransition2:
        [circle1 setValue:@(scaleDown) forKeyPath:@"transform.scale"];
        [circle2 setValue:@(scaleUp) forKeyPath:@"transform.scale"];
        [circle3 setValue:@1 forKeyPath:@"transform.scale"];
        break;
    case WaitingAnimationStateTransition3:
        [circle1 setValue:@1 forKeyPath:@"transform.scale"];
        [circle2 setValue:@(scaleDown) forKeyPath:@"transform.scale"];
        [circle3 setValue:@(scaleUp) forKeyPath:@"transform.scale"];
        break;
    case WaitingAnimationStateShrink3:
        [circle1 setValue:@1 forKeyPath:@"transform.scale"];
        [circle2 setValue:@1 forKeyPath:@"transform.scale"];
        [circle3 setValue:@(scaleDown) forKeyPath:@"transform.scale"];
        break;
    } 
}

@end
