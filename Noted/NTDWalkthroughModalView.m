//
//  NTDWalkthroughModalView.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughModalView.h"

static NSDictionary *messages;

@implementation NTDWalkthroughModalView

+ (void)initialize
{
    messages = @{@(NTDWalkthroughShouldBeginWalkthroughStep) : @"Would you like to begin the walkthrough?",
                 @(NTDWalkthroughMakeANoteStep) : @"Pull to create a new note.",
                 @(NTDWalkthroughSwipeToCloseKeyboardStep) : @"Type something, then swipe the keyboard down.",
                 @(NTDWalkthroughTapOptionsStep) : @"Tap the options button.",
                 @(NTDWalkthroughChangeColorsStep) : @"Pick a new color for your note.",
                 @(NTDWalkthroughCloseOptionsStep) : @"Swipe left to close the options menu.",
                 @(NTDWalkthroughSwipeToLastNoteStep) : @"Swipe left to the last note.",
                 @(NTDWalkthroughTwoFingerDeleteStep) : @"Drag left slowly with two fingers to delete a note.",
                 @(NTDWalkthroughPinchToListStep) : @"Pinch to see all of your notes.",
                 @(NTDWalkthroughOneFingerDeleteStep) : @"Swipe with one finger to delete when viewing all of your notes.",
                 @(NTDWalkthroughCompletedStep) : @"You've completed the walkthrough!",
    };
}

- (id)initWithStep:(NTDWalkthroughStep)step handler:(NTDWalkthroughPromptHandler)handler
{
    if (self = [super init]) {
        [self configureForStep:step];
        if (handler) self.promptHandler = handler;
    }
    return self;
}

- (void)configureForStep:(NTDWalkthroughStep)step {
    NTDWalkthroughModalPosition modalPosition;
    NTDWalkthroughModalType modalType;

    // decide on the modal's position
    switch (step) {
        case NTDWalkthroughShouldBeginWalkthroughStep:
            modalPosition = NTDWalkthroughModalPositionCenter;
            break;
            
        case NTDWalkthroughMakeANoteStep:
            modalPosition = NTDWalkthroughModalPositionBottom;
            break;
            
        case NTDWalkthroughTapOptionsStep:
        case NTDWalkthroughPinchToListStep:
        case NTDWalkthroughCompletedStep:
            modalPosition = NTDWalkthroughModalPositionCenter;
            break;
            
        case NTDWalkthroughSwipeToCloseKeyboardStep:
            modalPosition = NTDWalkthroughModalPositionTop;
            break;
            
        case NTDWalkthroughChangeColorsStep:
        case NTDWalkthroughCloseOptionsStep:
        case NTDWalkthroughOneFingerDeleteStep:
        case NTDWalkthroughTwoFingerDeleteStep:
        case NTDWalkthroughSwipeToLastNoteStep:
        default:
            modalPosition = NTDWalkthroughModalPositionBottom;            
            break;
    }
    
    // decide on the modal's type
    switch (step) {
        case NTDWalkthroughShouldBeginWalkthroughStep:
            modalType = NTDWalkthroughModalTypeBoolean;
            break;
        case NTDWalkthroughCompletedStep:
            modalType = NTDWalkthroughModalTypeDismiss;
            break;
            
        default:
            modalType = NTDWalkthroughModalTypeMessage;
            break;
    }
    
    self.message = messages[@(step)];
    self.position = modalPosition;
    self.type = modalType;
}

@end

