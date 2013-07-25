//
//  NTDWalkthroughViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthroughViewController.h"
#import "NTDWalkthroughGestureIndicatorView.h"

@interface NTDWalkthroughViewController ()

@property (nonatomic, strong) NTDWalkthroughGestureIndicatorView *currentIndicatorView;
@property (nonatomic, strong) UIView *currentModal;

@end

typedef NS_ENUM(NSInteger, NTDWalkthroughModalPosition)
{
    NTDWalkthroughModalPositionTop = 0,
    NTDWalkthroughModalPositionCenter,
    NTDWalkthroughModalPositionBottom
};

const CGFloat ModalEdgeMargin = 30;
const CGFloat ModalPadding = 15;

@implementation NTDWalkthroughViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.userInteractionEnabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)beginDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    //    self.currentIndicatorView = [NTDWalkthroughGestureIndicatorView gestureIndicatorViewForStep:step];
    //    [self.view addSubview:self.currentIndicatorView];
    
    [self displayModalForStep:step];
}

- (void)endDisplayingViewsForStep:(NTDWalkthroughStep)step
{
    NSLog(@"hiding step %i", step);
    [self hideModal];
}

#pragma mark - modals
- (void) displayModalForStep:(NTDWalkthroughStep)step {
    NSString *modalMessage;
    NTDWalkthroughModalPosition modalPosition;
    
    NSString *stringKey = [NSString stringWithFormat:@"NTDWalkthroughStep%iModal", step];
    modalMessage = NSLocalizedString(stringKey, @"");
    
    switch (step) {
        case NTDWalkthroughShouldBeginWalkthroughStep:
        case NTDWalkthroughMakeANoteStep:
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
    
    
    [self displayModalWithMessage: [NSString stringWithFormat:@"[%i] %@", step, modalMessage] position:modalPosition];
    
}

- (void) displayModalWithMessage:(NSString *)message position:(NTDWalkthroughModalPosition)pos {
    UIFont *modalFont = [UIFont fontWithName:@"Avenir-Light"
                                        size:20];
    CGRect modalBounds = CGRectInset(self.view.bounds, ModalEdgeMargin, ModalEdgeMargin);
    CGSize modalSize = [message sizeWithFont:modalFont
                           constrainedToSize:CGRectInset(modalBounds, ModalPadding, ModalPadding).size];
    
    CGRect modalFrame = {
        .origin.x = modalBounds.origin.x,
        .size.width = modalBounds.size.width,
        .size.height = modalSize.height + (2*ModalPadding)
    };
    
    switch (pos) {
        case NTDWalkthroughModalPositionTop:
            modalFrame.origin.y = modalBounds.origin.y - self.view.frame.origin.y;
            break;
            
        case NTDWalkthroughModalPositionCenter:
            modalFrame.origin.y = (self.view.frame.size.height - self.view.frame.origin.y - modalFrame.size.height)/2;
            break;
            
        case NTDWalkthroughModalPositionBottom:
            modalFrame.origin.y = self.view.frame.size.height - self.view.frame.origin.y - ModalEdgeMargin - modalFrame.size.height;
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
    UIView *modalContainer = [[UIView alloc] initWithFrame:modalFrame];
    modalContainer.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
    
    UILabel *modalLabel = [[UILabel alloc] initWithFrame:modalLabelFrame];
    modalLabel.text = message;
    modalLabel.font = modalFont;
    modalLabel.backgroundColor = [UIColor clearColor];
    modalLabel.textColor = [UIColor whiteColor];
    modalLabel.textAlignment = NSTextAlignmentCenter;
    modalLabel.numberOfLines = 0;
    
    [modalContainer addSubview:modalLabel];
    
    self.currentModal = modalContainer;
    
    if (!self.currentModal.superview)
        [self.view addSubview:self.currentModal];
    
    // animate the Modal in
    self.currentModal.alpha = 0;
    self.currentModal.transform = CGAffineTransformMakeScale(1.3, 1.3);
    
    [UIView animateWithDuration:.1 animations:^{
        self.currentModal.alpha = 1;
        self.currentModal.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void) hideModal {
    // animate the modal out
    [UIView animateWithDuration:.1 animations:^{
        for (UIView *view in self.view.subviews) {
            view.alpha = 0;
            view.transform = CGAffineTransformMakeScale(1.3, 1.3);
        }
    } completion:^(BOOL finished) {
        //[self.currentmodal removeFromSuperview];
    }];
}


@end
