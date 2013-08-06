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
//TODO add KVO for self.visibleCell.textView.keyboardPanRecognizer

static NSMutableDictionary *gestureRecognizerMap, *controlMap;
static void *ControlEventsArrayKey;

@interface NTDWalkthroughGestureIndicatorView ()
@property (nonatomic, assign) CGPoint startPoint, endPoint;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) UIGestureRecognizer *recognizer;
@property (nonatomic, strong) UIControl *control;
@end

@implementation NTDWalkthroughGestureIndicatorView

+ (void)initialize
{
    gestureRecognizerMap = [NSMutableDictionary dictionaryWithCapacity:NTDWalkthroughNumberOfSteps];
    controlMap = [NSMutableDictionary dictionaryWithCapacity:NTDWalkthroughNumberOfSteps];
}

+ (void)bindGestureRecognizer:(UIGestureRecognizer *)recognizer forStep:(NTDWalkthroughStep)step
{
    gestureRecognizerMap[@(step)] = recognizer;
}

+ (void)bindControl:(UIControl *)control events:(UIControlEvents)controlEvents forStep:(NTDWalkthroughStep)step
{
    controlMap[@(step)] = control;
    objc_setAssociatedObject(control, &ControlEventsArrayKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(control, &ControlEventsArrayKey, @(controlEvents), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)gestureIndicatorViewForStep:(NTDWalkthroughStep)step
{
    NTDWalkthroughGestureIndicatorView *view = [self instanceForStep:step];
    
    UIGestureRecognizer *recognizer = gestureRecognizerMap[@(step)];
    if (recognizer) {
        [recognizer addTarget:view action:@selector(handleGestureRecognizer:)];
        view.recognizer = recognizer;
    }
    UIControl *control = controlMap[@(step)];
    if (control) {
        UIControlEvents controlEvents = [objc_getAssociatedObject(control, &ControlEventsArrayKey) integerValue];
        [control addTarget:view action:@selector(handleAction:) forControlEvents:controlEvents];
        view.control = control;
    }
    
    return view;
}

+ (instancetype)instanceForStep:(NTDWalkthroughStep)step
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat CenterX = CGRectGetMidX(screenBounds);
    CGFloat CenterY = CGRectGetMidY(screenBounds);
    CGFloat YOffset = CGRectGetMaxY(screenBounds) - 480.0;
    
    NTDWalkthroughGestureIndicatorView *view = nil;
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
        {
            CGPoint start = {.x = CenterX, .y = 30};
            CGPoint end = {.x = CenterX, .y = 270 + YOffset};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughSwipeToCloseKeyboardStep:
        {
            CGPoint start = {.x = CenterX, .y = 180};
            CGPoint end = {.x = CenterX, .y = 260 + YOffset};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughCloseOptionsStep:
        {
            CGPoint start = {.x = CenterX + 50, .y = CenterY - 55};
            CGPoint end = {.x = 50, .y = CenterY - 55};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughSwipeToLastNoteStep:
        {
            CGPoint start = {.x = 320-70, .y = CenterY - 55};
            CGPoint end = {.x = 70, .y = CenterY - 55};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughOneFingerDeleteStep:
        {
            CGPoint start = {.x = 70, .y = 76};
            CGPoint end = {.x = 320-70, .y = 76};
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
    view.layer.shouldRasterize = YES;

    view.center = start;
    view.alpha = 0.0;
    
    view.startPoint = start;
    view.endPoint = end;
    view.duration = duration;
    
    [view addDragAnimation];
    return view;
    
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
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        static CGPoint touchPosition, originalPosition;
        static CAAnimation *dragAnimation;
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
            {
                touchPosition = [panGestureRecognizer locationInView:self.superview];
                originalPosition = self.layer.position;
                dragAnimation = [self.layer animationForKey:@"dragAnimation"];
                [self.layer removeAnimationForKey:@"dragAnimation"];
                self.layer.position = [[self.layer presentationLayer] position];
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     self.center = touchPosition;
                                 }];
                [UIView animateWithDuration:0.25
                                      delay:0.0
                                    options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                                 animations:^{
                                     CGAffineTransform t = CGAffineTransformMakeScale(1.5, 1.5);
                                     self.transform = t;
                                     self.layer.opacity = .8;
                                 }
                                 completion:^(BOOL finished) {
                                 }];
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
                CGPoint translation = [panGestureRecognizer translationInView:self.superview];
                self.layer.position = CGPointMake(touchPosition.x + translation.x, touchPosition.y + translation.y);
                break;
            }
            case UIGestureRecognizerStateEnded:
            {
                if (self.shouldCancelAnimations) break;
                
                [UIView animateWithDuration:0.25
                                      delay:0.25
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.center = originalPosition;
                                     self.transform = CGAffineTransformIdentity;
                                     self.layer.opacity = 1.0;
                                 }
                                 completion:^(BOOL finished) {
//                                     [self.layer addAnimation:dragAnimation forKey:@"dragAnimation"];
                                     [self addDragAnimation];
                }];
                break;
            }
            default:
                break;        
        }
    }
}

-(void)handleAction:(UIControl *)control
{
    
}

- (void)addDragAnimation
{
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    fadeInAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    fadeInAnimation.duration = .2;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    fadeInAnimation.fillMode = kCAFillModeForwards;
    
    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithCGPoint:self.startPoint];
    positionAnimation.toValue = [NSValue valueWithCGPoint:self.endPoint];
    positionAnimation.duration = self.duration;
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
    [self.layer addAnimation:animationGroup forKey:@"dragAnimation"];
}

- (void)setShouldCancelAnimations:(BOOL)shouldCancelAnimations
{
    _shouldCancelAnimations = shouldCancelAnimations;
    if (shouldCancelAnimations) [self.layer removeAllAnimations];
}

-(void)dealloc
{
    if (self.recognizer) [self.recognizer removeTarget:self action:NULL];
    if (self.control) [self.control removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];    
}
@end
