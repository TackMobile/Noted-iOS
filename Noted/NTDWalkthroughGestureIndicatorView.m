//
//  NTDWalkthroughGestureIndicator.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>
#import "NTDWalkthroughGestureIndicatorView.h"
#import "NTDTheme.h"
#import "UIColor+Utils.h"
#import "NTDReplicatorView.h"
#import "NTDWalkthroughModalView.h"

//TODO when walkthrough advances to a new step, clear the dictionary of old step (including associations)
//TODO add KVO for self.visibleCell.textView.keyboardPanRecognizer

static NSMutableDictionary *gestureRecognizerMap, *controlMap;
static void *ControlEventsArrayKey;
static CGFloat StandardIndicatorWidth = 50.0, TapIndicatorWidth = 40.0;

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
    CGRect containerBounds = [[UIScreen mainScreen] applicationFrame];
    CGFloat CenterX = containerBounds.size.width/2;
    CGFloat CenterY = containerBounds.size.height/2;
    CGFloat ScreenWidth = containerBounds.size.width;
    CGFloat ApplicationScreenHeight = containerBounds.size.height;
  
    CGFloat ScreenHeight = [[UIScreen mainScreen] bounds].size.height;
    BOOL isiPhone4 = (ScreenHeight == 480)? YES : NO; // 3.5" iPhone 4/4s
    BOOL isiPhone5 = (ScreenHeight == 568)? YES : NO; // 4" iPhone 5/5s
    BOOL isiPhone6 = (ScreenHeight == 667)? YES : NO; // 4.7" iPhone 6
    BOOL isiPhone6Plus = (ScreenHeight == 736)? YES : NO; // 5.5" iPhone 6+
    
    NTDWalkthroughGestureIndicatorView *view = nil;
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
        {
            CGPoint start = {.x = CenterX, .y = 65};
            CGPoint end = {.x = CenterX, .y = ApplicationScreenHeight - 210};
            view = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughSwipeToCloseKeyboardStep:
        {
            CGPoint start = {.x = CenterX, .y = 205};
            CGPoint end = {.x = CenterX, .y = ApplicationScreenHeight - 35};
            view = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughTapOptionsStep:
        {
            CGPoint center = {.x = ScreenWidth - 25, .y = 20};
            view = [self animatedTapIndicatorViewAtCenter:center];
            break;
        }
        case NTDWalkthroughChangeColorsStep:
        {
            CGPoint center = {.x = 48, .y = CenterY};
            if (isiPhone4) {
                center.y -= 130;
            } else if (isiPhone5) {
                center.y -= 136;
            } else  if (isiPhone6) {
                center.y -= 144;
            } else if (isiPhone6Plus) {
                center.y -= 151;
            }
          
            view = [self animatedTapIndicatorViewAtCenter:center];
            break;
        }
        case NTDWalkthroughCloseOptionsStep:
        {
            CGPoint start = {.x = CenterX + 50, .y = CenterY};
            CGPoint end = {.x = 50, .y = CenterY};
            view = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughSwipeToLastNoteStep:
        {
            CGPoint start = {.x = ScreenWidth-70, .y = CenterY};
            CGPoint end = {.x = 70, .y = CenterY};
            view = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            break;
        }
        case NTDWalkthroughTwoFingerDeleteStep:
        {
            CGPoint start = {.x = ScreenWidth-60, .y = CenterY + StandardIndicatorWidth/2};
            CGPoint end = {.x = 60, .y = CenterY + StandardIndicatorWidth/2};
            NTDWalkthroughGestureIndicatorView *subview = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            
            view = [[NTDReplicatorView alloc] initWithFrame:subview.frame];
            [view addSubview:subview];
            
            /* We do this translation so animations work the same as before. */
            CGPoint subviewOrigin = subview.frame.origin;
            subview.transform = CGAffineTransformMakeTranslation(-subviewOrigin.x, -subviewOrigin.y);
            
            CAReplicatorLayer *replicatorLayer = [(NTDReplicatorView *)view replicatorLayer];
            replicatorLayer.instanceCount = 2;
            replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, -75, 0);
            break;
        }
        case NTDWalkthroughPinchToListStep:
        {
            CGPoint start = {.x = CenterX, .y = 35};
            CGPoint end = {.x = CenterX, .y = CenterY - 85};
            
            NTDWalkthroughGestureIndicatorView *subview = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            view = [[NTDReplicatorView alloc] initWithFrame:subview.frame];
            [view addSubview:subview];
            
            CGPoint subviewOrigin = subview.frame.origin;
            subview.transform = CGAffineTransformMakeTranslation(-subviewOrigin.x, -subviewOrigin.y);
            
            CAReplicatorLayer *replicatorLayer = [(NTDReplicatorView *)view replicatorLayer];
            replicatorLayer.instanceCount = 2;
            CATransform3D transform = CATransform3DMakeScale(1, -1, 1);
            transform = CATransform3DTranslate(transform, 0, -2*(CenterY-start.y), 0);
            replicatorLayer.instanceTransform = transform;
            break;
        }
        case NTDWalkthroughOneFingerDeleteStep:
        {
            CGPoint start = {.x = 70, .y = 98};
            CGPoint end = {.x = 320-70, .y = 98};
            view = [self animatedSwipeIndicatorViewWithStart:start end:end duration:1];
            break;
        }            

        default:
            break;
    }
    return view;
}

+ (instancetype)newIndicatorView
{
    CGSize indicatorSize = {.width = StandardIndicatorWidth, .height = StandardIndicatorWidth};
    CGRect bounds = {.size = indicatorSize};
    NTDWalkthroughGestureIndicatorView *view = [[NTDWalkthroughGestureIndicatorView alloc] initWithFrame:bounds];
    view.layer.cornerRadius = StandardIndicatorWidth/2;
    view.backgroundColor = ModalBackgroundColor;

    return view;
}

+ (instancetype)animatedSwipeIndicatorViewWithStart:(CGPoint)start end:(CGPoint)end duration:(NSTimeInterval)duration
{
    NTDWalkthroughGestureIndicatorView *view = [self newIndicatorView];
    view.center = start;
    view.alpha = 0.0;
    
    view.startPoint = start;
    view.endPoint = end;
    view.duration = duration;
    
    [view addDragAnimation];
    return view;
}

+ (instancetype)animatedTapIndicatorViewAtCenter:(CGPoint)center
{
    NTDWalkthroughGestureIndicatorView *view = [self newIndicatorView];
    view.$size = CGSizeMake(TapIndicatorWidth, TapIndicatorWidth);
    view.layer.cornerRadius = TapIndicatorWidth/2;
    view.center = center;
        
    NSTimeInterval TotalDuration = 1.6;
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.toValue = @0;
    fadeAnimation.duration = (2/3) * TotalDuration;
    fadeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    fadeAnimation.fillMode = kCAFillModeForwards;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.7, 1.7, 1.7)];
    scaleAnimation.duration = (1/3) * TotalDuration;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    scaleAnimation.fillMode = kCAFillModeForwards;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[fadeAnimation, scaleAnimation];
    animationGroup.repeatCount = HUGE_VALF;
    animationGroup.duration = TotalDuration;
    [view.layer addAnimation:animationGroup forKey:@"pulseAnimation"];
    
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
                self.layer.position = [(CALayer *)[self.layer presentationLayer] position];
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
