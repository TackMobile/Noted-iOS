//
//  NTDWalkthroughGestureIndicator.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "NTDWalkthroughGestureIndicatorView.h"
#import "NTDTheme.h"
#import "UIColor+Utils.h"

//TODO when walkthrough advances to a new step, clear the dictionary of old step (including associations)

static NSMutableDictionary *gestureRecognizerMap, *controlMap;
static void *ControlEventsArrayKey;

@implementation NTDWalkthroughGestureIndicatorView

+ (void)initializeStaticVariablesIfNecessary
{
    if (!gestureRecognizerMap) gestureRecognizerMap = [NSMutableDictionary dictionaryWithCapacity:NTDWalkthroughNumberOfSteps];
    if (!controlMap) controlMap = [NSMutableDictionary dictionaryWithCapacity:NTDWalkthroughNumberOfSteps];
}

+ (void)bindGestureRecognizer:(UIGestureRecognizer *)recognizer forStep:(NTDWalkthroughStep)step
{
    [self initializeStaticVariablesIfNecessary];
    gestureRecognizerMap[@(step)] = recognizer;
}

+ (void)bindControl:(UIControl *)control events:(UIControlEvents)controlEvents forStep:(NTDWalkthroughStep)step
{
    [self initializeStaticVariablesIfNecessary];
    controlMap[@(step)] = control;
    objc_setAssociatedObject(control, &ControlEventsArrayKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(control, &ControlEventsArrayKey, @(controlEvents), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)gestureIndicatorViewForStep:(NTDWalkthroughStep)step
{
    NTDWalkthroughGestureIndicatorView *view = [self instanceForStep:step];
    
    UIGestureRecognizer *recognizer = gestureRecognizerMap[@(step)];
    if (recognizer)
        [recognizer addTarget:view action:@selector(handleGestureRecognizer:)];
    UIControl *control = controlMap[@(step)];
    if (control) {
        UIControlEvents controlEvents = [objc_getAssociatedObject(control, &ControlEventsArrayKey) integerValue];
        [control addTarget:view action:@selector(handleAction:) forControlEvents:controlEvents];
    }
    
    return view;
}

+ (instancetype)instanceForStep:(NTDWalkthroughStep)step
{
    NTDWalkthroughGestureIndicatorView *view = nil;
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
        {
            CGPoint start = {.x = 160, .y = 30};
            CGPoint end = {.x = 160, .y = 270};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1];
            break;
        }
            
        default:
            break;
    }
    return view;
}

+ (instancetype)animatedTouchIndicatorViewWithStart:(CGPoint)start end:(CGPoint)end duration:(NSTimeInterval)duration
{
    CGSize indicatorSize = {.width = 50, .height = 50};
    CGRect bounds = {.size = indicatorSize};
    NTDWalkthroughGestureIndicatorView *view = [[NTDWalkthroughGestureIndicatorView alloc] initWithFrame:bounds];
    view.backgroundColor = [NTDTheme themeForColorScheme:NTDColorSchemeTack].backgroundColor;
    view.layer.shadowOpacity = 0.35;
    view.layer.shadowOffset = CGSizeZero;
    view.clipsToBounds = NO;

    view.center = start;
    view.alpha = 0.0;
    
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    fadeInAnimation.duration = .2;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    fadeInAnimation.fillMode = kCAFillModeForwards;

    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:start];
    positionAnimation.toValue = [NSValue valueWithCGPoint:end];
    positionAnimation.duration = duration;
    positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    positionAnimation.fillMode = kCAFillModeForwards;
    positionAnimation.beginTime = fadeInAnimation.duration;
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:0.0];
    fadeOutAnimation.duration = .2;
    fadeOutAnimation.beginTime = positionAnimation.beginTime + positionAnimation.duration + .1;
    fadeOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[fadeInAnimation, positionAnimation, fadeOutAnimation];
    animationGroup.repeatCount = HUGE_VALF;
    animationGroup.duration = fadeOutAnimation.beginTime + fadeOutAnimation.duration + .1;
    [view.layer addAnimation:animationGroup forKey:@"dragAnimation"];
    
    return view;
}

- (void)handleGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    
}
@end
