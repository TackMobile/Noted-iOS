//
//  NTDModalView.m
//  
//
//  Created by Vladimir Fleurima on 12/18/13.
//
//

#import "NTDModalView.h"
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>

const CGFloat NTDWalkthroughModalEdgeMargin = 30;
const CGFloat NTDWalkthroughModalPadding = 15;
const CGFloat NTDWalkthroughModalButtonHeight = 40;

@interface NTDModalView ()
@property (nonatomic, strong) NSArray *buttonTitles;
@property (nonatomic, copy) NTDModalDismissalHandler dismissalHandler;
@end

@implementation NTDModalView

-(instancetype)initwithMessage:(NSString *)message handler:(NTDWalkthroughPromptHandler)handler;
{
    if (self == [super init]) {
        self.message = message;
        self.position = NTDWalkthroughModalPositionCenter;
        self.type = NTDWalkthroughModalTypeBoolean;
        self.promptHandler = handler;
    }
    return self;
}

-(instancetype)initwithMessage:(NSString *)message buttons:(NSArray *)buttonTitles dismissalHandler:(NTDModalDismissalHandler)handler
{
    if (self == [super init]) {
        self.message = message;
        self.position = NTDWalkthroughModalPositionCenter;
        self.type = NTDWalkthroughModalTypeMultipleButtons;
        if (!handler) handler = ^(NSUInteger i) {};
        self.dismissalHandler = handler;
        self.buttonTitles = buttonTitles;
    }
    return self;
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    self.superviewFrame = newSuperview.frame;
    
    switch (self.type) {
        case NTDWalkthroughModalTypeBoolean:
            [self drawBooleanModalWithHandlersForYes:@selector(yesButtonTapped:) no:@selector(noButtonTapped:)];
            break;
        case NTDWalkthroughModalTypeDismiss:
            [self drawDismissModalWithHandlerForDismiss:@selector(dismissButtonTapped:)];
            break;
        case NTDWalkthroughModalTypeMultipleButtons:
            [self drawMultipleButtonsModal];
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
        [self applyParallax];
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
    [self drawPromptOptionWithAction:dismiss ofWidth:1 index:0 title:@"Start Writing"];
}

-(void)drawMultipleButtonsModal
{
    [self drawModalMessage];
    NSInteger index = 0, count = self.buttonTitles.count;
    for (NSString *title in self.buttonTitles) {
        [self drawPromptOptionWithAction:@selector(buttonTapped:) ofWidth:1.0/count index:index title:title];
        index++;
    }
}

-(void)drawPromptOptionWithAction:(SEL)action ofWidth:(float)percent index:(NSInteger)index title:(NSString *)title {
    // ensure the background is off-white for the dividers
    //    self.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];
    CGFloat buttonMargin = 1/[UIScreen mainScreen].scale;
    CGFloat buttonMarginTop = buttonMargin;
    CGFloat buttonMarginSides = (percent == 1) ? 0 : buttonMargin;
    
    // add the yes/no buttons
    CGRect buttonFrame = {
        .origin.x = (self.modalBackground.$width + buttonMarginSides) * percent * index,
        .origin.y = self.modalBackground.$height + buttonMarginTop,
        .size.height = NTDWalkthroughModalButtonHeight,
        .size.width =self.modalBackground.$width * percent - buttonMarginSides * percent
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
    button.tag = index;
    
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
        case NTDWalkthroughModalTypeMessage:
            break;
            
        default:
            modalFrame.size.height += buttonMargin + NTDWalkthroughModalButtonHeight;
            break;
    }
    
    // calculate the modal's position within its allowable bounds
    switch (self.position) {
        case NTDWalkthroughModalPositionTop:
            modalFrame.origin.y = modalBounds.origin.y - screenFrame.origin.y + 30;
            break;
            
        case NTDWalkthroughModalPositionCenter:
            modalFrame.origin.y = (screenFrame.size.height - screenFrame.origin.y - modalFrame.size.height)/2;
            break;
            
        case NTDWalkthroughModalPositionBottom:
            modalFrame.origin.y = screenFrame.size.height - screenFrame.origin.y - NTDWalkthroughModalEdgeMargin - modalFrame.size.height - 20;
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
    self.modalBackground.backgroundColor = ModalBackgroundColor;
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

- (void)applyParallax
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIInterpolatingMotionEffect *verticalTilt = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        UIInterpolatingMotionEffect *horizTilt = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                 type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        static CGFloat Offset = 10;
        verticalTilt.minimumRelativeValue = horizTilt.minimumRelativeValue = @(-Offset);
        verticalTilt.maximumRelativeValue = horizTilt.maximumRelativeValue = @(Offset);
        
        UIMotionEffectGroup *effectGroup = [[UIMotionEffectGroup alloc] init];
        effectGroup.motionEffects = @[verticalTilt, horizTilt];
        [self addMotionEffect:effectGroup];
    }
}

#pragma mark - Button Action Handling
- (void)buttonTouchedDown:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:0 alpha:.85];
}
- (void)buttonTouchEnded:(UIButton *)button {
    button.backgroundColor = ModalBackgroundColor;
}

- (void)yesButtonTapped:(UIButton *)button {
    __strong id foo = self;
    self.promptHandler(YES);
    [self buttonTouchEnded:button];
    foo = nil;
}
- (void)noButtonTapped:(UIButton *)button {
    __strong id foo = self;
    self.promptHandler(NO);
    [self buttonTouchEnded:button];
    foo = nil;
}
- (void)dismissButtonTapped:(UIButton *)button {
    __strong id foo = self;
    self.promptHandler(YES);
    [self buttonTouchEnded:button];
    foo = nil;
}
- (void)buttonTapped:(UIButton *)button {
    __strong id foo = self;
    self.dismissalHandler(button.tag);
    [self buttonTouchEnded:button];
    [self dismiss];
    foo = nil;
}


static BOOL isShowing;
-(void)show
{
    UIView *view = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    UIView *touchBlockingView = [[UIView alloc] initWithFrame:view.frame];
    [touchBlockingView addSubview:self];
    [view addSubview:touchBlockingView];
    isShowing = YES;
}

-(void)dismiss
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.alpha = 0;
                         self.transform = CGAffineTransformMakeScale(1.3, 1.3);
                     } completion:^(BOOL finished) {
                         [self.superview removeFromSuperview];
                         isShowing = NO;
                     }];
}

+ (BOOL)isShowing
{
    return isShowing;
}
@end
