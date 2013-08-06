//
//  NTDWalkthroughModalView.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughModalView.h"

typedef void(^PromptHandler)(BOOL userClickedYes);

typedef NS_ENUM(NSInteger, NTDWalkthroughModalPosition)
{
    NTDWalkthroughModalPositionTop = 0,
    NTDWalkthroughModalPositionCenter,
    NTDWalkthroughModalPositionBottom
};

typedef NS_ENUM(NSInteger, NTDWalkthroughModalType)
{
    NTDWalkthroughModalTypeMessage = 0,
    NTDWalkthroughModalTypeBoolean
};

const CGFloat NTDWalkthroughModalEdgeMargin = 30;
const CGFloat NTDWalkthroughModalPadding = 15;
const CGFloat NTDWalkthroughModalButtonsHeight = 40;

static NSDictionary *messages;

@interface NTDWalkthroughModalView ()
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NTDWalkthroughModalPosition position;
@property (nonatomic, assign) NTDWalkthroughModalType type;
@property (nonatomic, copy) PromptHandler promptHandler;
@end

@implementation NTDWalkthroughModalView

+ (void)initialize
{
    messages = @{@(NTDWalkthroughShouldBeginWalkthroughStep) : @"Would you like to begin the walkthrough?",
                 @(NTDWalkthroughMakeANoteStep) : @"Pull to create a new note.",
                 @(NTDWalkthroughSwipeToCloseKeyboardStep) : @"Type something, then swipe the keyboard down to finish.",
                 @(NTDWalkthroughTapOptionsStep) : @"Tap the menu button.",
                 @(NTDWalkthroughChangeColorsStep) : @"Pick a new color for your note.",
                 @(NTDWalkthroughCloseOptionsStep) : @"Swipe left to close the menu.",
                 @(NTDWalkthroughSwipeToLastNoteStep) : @"Swipe left to the last note.",
                 @(NTDWalkthroughTwoFingerDeleteStep) : @"Drag slowly with two fingers to delete a note.",
                 @(NTDWalkthroughPinchToListStep) : @"Pinch to see all of your notes.",
                 @(NTDWalkthroughOneFingerDeleteStep) : @"Swipe with one finger to delete when viewing all of your notes.",
    };
}
- (id)initWithStep:(NTDWalkthroughStep)step
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self configureForStep:step];
    }
    return self;
}

- (id)initWithStep:(NTDWalkthroughStep)step handler:(PromptHandler)handler
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self configureForStep:step];
        [self setPromptHandler:handler];
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
            
        default:
            modalType = NTDWalkthroughModalTypeMessage;
            break;
    }
    
    self.message = messages[@(step)];
    self.position = modalPosition;
    self.type = modalType;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect screenFrame = newSuperview.frame;
    CGFloat buttonMargin = 1/[UIScreen mainScreen].scale;
    UIFont *modalFont = [UIFont fontWithName:@"Avenir-Light"
                                        size:20];
    CGRect modalBounds = CGRectInset(screenFrame,
                                     NTDWalkthroughModalEdgeMargin,
                                     NTDWalkthroughModalEdgeMargin);
    CGSize modalSize = [self.message sizeWithFont:modalFont
                                constrainedToSize:CGRectInset(modalBounds,
                                                              NTDWalkthroughModalPadding,
                                                              NTDWalkthroughModalPadding).size];
    
    CGRect modalFrame = {
        .origin.x = modalBounds.origin.x,
        .size.width = modalBounds.size.width,
        .size.height = modalSize.height + (2 * NTDWalkthroughModalPadding)
    };
    CGRect modalBackgroundFrame = modalFrame;
    modalBackgroundFrame.origin = CGPointZero;
    
    switch (self.type) {
        case NTDWalkthroughModalTypeBoolean:
            modalFrame.size.height += buttonMargin + NTDWalkthroughModalButtonsHeight;
            break;
            
        default:
            break;
    }
    
    switch (self.position) {
        case NTDWalkthroughModalPositionTop:
            modalFrame.origin.y = modalBounds.origin.y - screenFrame.origin.y;
            break;
            
        case NTDWalkthroughModalPositionCenter:
            modalFrame.origin.y = (screenFrame.size.height - screenFrame.origin.y - modalFrame.size.height)/2;
            break;
            
        case NTDWalkthroughModalPositionBottom:
            modalFrame.origin.y = screenFrame.size.height - screenFrame.origin.y - NTDWalkthroughModalEdgeMargin - modalFrame.size.height;
            break;
            
        default:
            break;
    }
    
    CGRect modalLabelFrame = {
        .origin.x = NTDWalkthroughModalPadding,
        .origin.y = NTDWalkthroughModalPadding,
        .size.width = modalBounds.size.width - (2*NTDWalkthroughModalPadding),
        .size.height = modalSize.height
    };
    
    // style the modal
    self.frame = modalFrame;
    
    UIView *modalBackground = [UIView new];
    modalBackground.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
    modalBackground.frame = modalBackgroundFrame;
    
    UILabel *modalLabel = [[UILabel alloc] initWithFrame:modalLabelFrame];
    modalLabel.text = self.message;
    modalLabel.font = modalFont;
    modalLabel.backgroundColor = [UIColor clearColor];
    modalLabel.textColor = [UIColor whiteColor];
    modalLabel.textAlignment = NSTextAlignmentCenter;
    modalLabel.numberOfLines = 0;
    
    if (self.type == NTDWalkthroughModalTypeBoolean) {
        self.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];

        // add the yes/no buttons
        CGRect yesButtonFrame = {
            .origin.x = 0,
            .origin.y = modalBackgroundFrame.size.height + buttonMargin,
            .size.height = NTDWalkthroughModalButtonsHeight,
            .size.width = modalBackgroundFrame.size.width / 2 - buttonMargin / 2
        };
        CGRect noButtonFrame = {
            .origin.x = yesButtonFrame.size.width + buttonMargin,
            .origin.y = modalBackgroundFrame.size.height + buttonMargin,
            .size.height = NTDWalkthroughModalButtonsHeight,
            .size.width = modalBackgroundFrame.size.width / 2 - buttonMargin / 2
        };
            
        UIButton *yesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [yesButton setTitle:@"Yes" forState:UIControlStateNormal];
        yesButton.titleLabel.font = modalLabel.font;
        yesButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [yesButton addTarget:self
                      action:@selector(buttonTouchedDown:)
            forControlEvents:UIControlEventTouchDown];
        [yesButton addTarget:self
                      action:@selector(buttonTouchEnded:)
            forControlEvents:UIControlEventTouchUpOutside];
        [yesButton addTarget:self
                      action:@selector(yesButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        yesButton.backgroundColor = modalBackground.backgroundColor;
        yesButton.frame = yesButtonFrame;
        
        
        UIButton *noButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [noButton setTitle:@"No" forState:UIControlStateNormal];
        noButton.titleLabel.font = modalLabel.font;
        noButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [noButton addTarget:self
                      action:@selector(buttonTouchedDown:)
            forControlEvents:UIControlEventTouchDown];
        [noButton addTarget:self
                      action:@selector(buttonTouchEnded:)
            forControlEvents:UIControlEventTouchUpOutside];
        [noButton addTarget:self
                      action:@selector(noButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        noButton.backgroundColor = modalBackground.backgroundColor;
        noButton.frame = noButtonFrame;
        
        [self addSubview:yesButton];
        [self addSubview:noButton];
    }
    
    [modalBackground addSubview:modalLabel];
    [self addSubview:modalBackground];
    
    // animate the Modal in
    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(1.3, 1.3);
}

- (void)didMoveToSuperview
{
    [UIView animateWithDuration:.1 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Button Action Handling
- (void)buttonTouchedDown:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:.27 alpha:1];
}
- (void)buttonTouchEnded:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
}

- (void)yesButtonTapped:(UIButton *)button {
    if (self.promptHandler)
        self.promptHandler(YES);
    [self buttonTouchEnded:button];
}
- (void)noButtonTapped:(UIButton *)button {
    if (self.promptHandler)
        self.promptHandler(NO);
    [self buttonTouchEnded:button];
}

@end

