//
//  NTDWalkthroughModalView.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughModalView.h"

typedef NS_ENUM(NSInteger, NTDWalkthroughModalPosition)
{
    NTDWalkthroughModalPositionTop = 0,
    NTDWalkthroughModalPositionCenter,
    NTDWalkthroughModalPositionBottom
};

typedef NS_ENUM(NSInteger, NTDWalkthroughModalType)
{
    NTDWalkthroughModalTypeMessage = 0,
    NTDWalkthroughModalTypeBoolean,
    NTDWalkthroughModalTypeDismiss
};

const CGFloat NTDWalkthroughModalEdgeMargin = 30;
const CGFloat NTDWalkthroughModalPadding = 15;
const CGFloat NTDWalkthroughModalButtonsHeight = 40;

static NSDictionary *messages;

@interface NTDWalkthroughModalView () 
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NTDWalkthroughModalPosition position;
@property (nonatomic, assign) NTDWalkthroughModalType type;
@property (nonatomic, copy) NTDWalkthroughPromptHandler promptHandler;

@property (nonatomic, strong) UIView *modalBackground;
@property (nonatomic, readonly) UIFont *modalFont;
@property CGRect superviewFrame;
@end

@implementation NTDWalkthroughModalView

+ (void)initialize
{
    messages = @{@(NTDWalkthroughShouldBeginWalkthroughStep) : @"Would you like to begin the walkthrough?",
                 @(NTDWalkthroughMakeANoteStep) : @"Pull to create a new note.",
                 @(NTDWalkthroughSwipeToCloseKeyboardStep) : @"Type something, then swipe the keyboard down to finish.",
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
- (id)initWithStep:(NTDWalkthroughStep)step
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self configureForStep:step];
        [self setPromptHandler:^(BOOL userClickedYes){}];
    }
    return self;
}

- (id)initWithStep:(NTDWalkthroughStep)step handler:(NTDWalkthroughPromptHandler)handler
{
    if (self = [super initWithFrame:CGRectZero]) {
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

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    self.superviewFrame = newSuperview.frame;
    
    switch (self.type) {
        case NTDWalkthroughModalTypeBoolean:
            [self drawBooleanModalWithHandlersForYes:@selector(yesButtonTapped:) no:@selector(noButtonTapped:)];
            break;
        case NTDWalkthroughModalTypeDismiss:
            [self drawDismissModalWithHandlerForDismiss:@selector(dismissButtonTapped:)];
            break;
        default:
            [self drawModalMessage];
            break;
    }
    
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

#pragma mark - Drawing Methods
-(void)drawBooleanModalWithHandlersForYes:(SEL)yes no:(SEL)no {
    [self drawModalMessage];
    [self drawPromptOptionWithAction:no ofWidth:.5 index:0 title:@"No"];
    [self drawPromptOptionWithAction:yes ofWidth:.5 index:1 title:@"Yes"];
}

-(void)drawDismissModalWithHandlerForDismiss:(SEL)dismiss {
    [self drawModalMessage];
    [self drawPromptOptionWithAction:dismiss ofWidth:1 index:0 title:@"Cool."];
}

-(void)drawPromptOptionWithAction:(SEL)action ofWidth:(float)percent index:(int)index title:(NSString *)title {
    // ensure the background is off-white for the dividers
    self.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];
    CGFloat buttonMargin = 1/[UIScreen mainScreen].scale;
    
    // add the yes/no buttons
    CGRect buttonFrame = {
        .origin.x = (self.modalBackground.frame.size.width + buttonMargin) * percent * index,
        .origin.y = self.modalBackground.frame.size.height + buttonMargin,
        .size.height = NTDWalkthroughModalButtonsHeight,
        .size.width =self.modalBackground.frame.size.width * percent - buttonMargin * percent
    };
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = self.modalFont;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [button addTarget:self
               action:@selector(buttonTouchedDown:)
        forControlEvents:UIControlEventTouchDown];
    [button addTarget:self
               action:@selector(buttonTouchEnded:)
        forControlEvents:UIControlEventTouchUpOutside];
    
    [button addTarget:self
               action:action
     forControlEvents:UIControlEventTouchUpInside];
    
    button.backgroundColor = self.modalBackground.backgroundColor;
    button.frame = buttonFrame;
    
    [self addSubview:button];
}

-(void)drawModalMessage {
    CGRect screenFrame = self.superviewFrame;
    CGFloat buttonMargin = 1/[UIScreen mainScreen].scale; // one pixel
    
    CGRect modalBounds = CGRectInset(screenFrame,
                                     NTDWalkthroughModalEdgeMargin,
                                     NTDWalkthroughModalEdgeMargin);
    CGSize modalSize = [self.message sizeWithFont:self.modalFont
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
    
    // account for the height of option buttons
    switch (self.type) {
        case NTDWalkthroughModalTypeBoolean:
        case NTDWalkthroughModalTypeDismiss:
            modalFrame.size.height += buttonMargin + NTDWalkthroughModalButtonsHeight;
            break;
            
        default:
            break;
    }
    
    // calculate the modal's position within its allowable bounds
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
    
    self.frame = modalFrame;
    
    // add the background for the label
    [self.modalBackground removeFromSuperview];
    self.modalBackground = [UIView new];
    self.modalBackground.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
    self.modalBackground.frame = modalBackgroundFrame;
    
    // add the text
    UILabel *modalLabel = [[UILabel alloc] initWithFrame:modalLabelFrame];
    modalLabel.text = self.message;
    modalLabel.font = self.modalFont;
    modalLabel.backgroundColor = [UIColor clearColor];
    modalLabel.textColor = [UIColor whiteColor];
    modalLabel.textAlignment = NSTextAlignmentCenter;
    modalLabel.numberOfLines = 0;
    
    // arrange the subviews
    [self.modalBackground addSubview:modalLabel];
    [self addSubview:self.modalBackground];

}

-(UIFont *)modalFont {
    return [UIFont fontWithName:@"Avenir-Light" size:20];
}

#pragma mark - Button Action Handling
- (void)buttonTouchedDown:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:.27 alpha:1];
}
- (void)buttonTouchEnded:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
}

- (void)yesButtonTapped:(UIButton *)button {
    __strong id foo = self;
    self.promptHandler(YES);
    [self buttonTouchEnded:button];
}
- (void)noButtonTapped:(UIButton *)button {
        __strong id foo = self;
    self.promptHandler(NO);
    [self buttonTouchEnded:button];
}
- (void)dismissButtonTapped:(UIButton *)button {
        __strong id foo = self;
    self.promptHandler(YES);
    [self buttonTouchEnded:button];
}

@end

