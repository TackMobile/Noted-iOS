//
//  NTDWalkthroughGestureIndicator.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <objc/runtime.h>
#import "NTDWalkthroughGestureIndicatorView.h"

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
    Class klass = [self subclassForStep:step];
    NTDWalkthroughGestureIndicatorView *view = [[klass alloc] init];
    
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

+ (Class)subclassForStep:(NTDWalkthroughStep)step
{
    Class klass = NULL;
    switch (step) {
        case NTDWalkthroughMakeANoteStep:
            break;
            
        default:
            break;
    }
    return klass;
}

@end
