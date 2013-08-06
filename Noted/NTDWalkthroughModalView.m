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

const CGFloat ModalEdgeMargin = 30;
const CGFloat ModalPadding = 15;
static NSDictionary *messages;

@interface NTDWalkthroughModalView ()
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NTDWalkthroughModalPosition position;
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
                 @(NTDWalkthroughTwoFingerDeleteStep) : @"Drag left slowly with two fingers to delete a note.",
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

- (void)configureForStep:(NTDWalkthroughStep)step {
    NTDWalkthroughModalPosition modalPosition;    

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
    
    self.message = messages[@(step)];
    self.position = modalPosition;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect screenFrame = newSuperview.frame;
    UIFont *modalFont = [UIFont fontWithName:@"Avenir-Light"
                                        size:20];
    CGRect modalBounds = CGRectInset(screenFrame, ModalEdgeMargin, ModalEdgeMargin);
    CGSize modalSize = [self.message sizeWithFont:modalFont
                                constrainedToSize:CGRectInset(modalBounds, ModalPadding, ModalPadding).size];
    
    CGRect modalFrame = {
        .origin.x = modalBounds.origin.x,
        .size.width = modalBounds.size.width,
        .size.height = modalSize.height + (2*ModalPadding)
    };
    
    switch (self.position) {
        case NTDWalkthroughModalPositionTop:
            modalFrame.origin.y = modalBounds.origin.y - screenFrame.origin.y;
            break;
            
        case NTDWalkthroughModalPositionCenter:
            modalFrame.origin.y = (screenFrame.size.height - screenFrame.origin.y - modalFrame.size.height)/2;
            break;
            
        case NTDWalkthroughModalPositionBottom:
            modalFrame.origin.y = screenFrame.size.height - screenFrame.origin.y - ModalEdgeMargin - modalFrame.size.height;
            break;
            
        default:
            break;
    }
    
    CGRect modalLabelFrame = {
        .origin.x = ModalPadding,
        .origin.y = ModalPadding,
        .size.width = modalBounds.size.width - (2*ModalPadding),
        .size.height = modalSize.height
    };
    
    // style the modal
    self.frame = modalFrame;
    self.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
    
    UILabel *modalLabel = [[UILabel alloc] initWithFrame:modalLabelFrame];
    modalLabel.text = self.message;
    modalLabel.font = modalFont;
    modalLabel.backgroundColor = [UIColor clearColor];
    modalLabel.textColor = [UIColor whiteColor];
    modalLabel.textAlignment = NSTextAlignmentCenter;
    modalLabel.numberOfLines = 0;
    
    [self addSubview:modalLabel];
    
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

@end

