//
//  NTDWalkthroughGestureIndicator.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <objc/runtime.h>
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
            CGPoint start = {.x = 200, .y = 30};
            CGPoint end = {.x = 200, .y = 300};
            view = [self animatedTouchIndicatorViewWithStart:start end:end duration:1.5];
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
    UIGraphicsBeginImageContextWithOptions(indicatorSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorRef fillColor = [NTDTheme themeForColorScheme:NTDColorSchemeTack].backgroundColor.CGColor;
    fillColor = [UIColor colorWithHexString:@"1181c1"].CGColor;
    CGContextSetFillColorWithColor(context, fillColor);
    CGRect bounds = {.size = indicatorSize};
    CGContextFillEllipseInRect(context, bounds);
    UIImage *indicatorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NTDWalkthroughGestureIndicatorView *view = [[NTDWalkthroughGestureIndicatorView alloc] initWithFrame:bounds];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:indicatorImage];
    [view addSubview:imageView];
    view.center = start;
    [UIView animateWithDuration:duration
                          delay:duration
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         view.center = end;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    return view;
}
@end
