//
//  NTDOptionsViewController.m
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDOptionsViewController.h"
#import "NTDTheme.h"
#import "UIView+FrameAdditions.h"

NSString *const ToggleStatusBarNotification = @"didToggleStatusBar";

@implementation NTDColorPicker

- (void) layoutSubviews {
    [super layoutSubviews];
    
    NSInteger subViewCount = [self.subviews count];
    CGSize mySize = self.frame.size;
    CGSize colorSize = {
        .width = mySize.width,
        .height = (mySize.height - (subViewCount -1)) / subViewCount
    };
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *color, NSUInteger idx, BOOL *stop) {
        CGRect colorRect = {
            .origin.x = 0,
            .origin.y = idx * (colorSize.height + 1),
            .size = colorSize
        };
        
        color.frame = colorRect;
    }];
}

@end

// view tags

typedef NS_ENUM(NSInteger, NTDoptionsTags) {
    NTDoptionsShareTag = 0,
    NTDoptionsSettingsTag,
    NTDoptionsAboutTag
};

typedef NS_ENUM(NSInteger, NTDShareoptionsTags) {
    NTDShareoptionsEmailTag = 0,
    NTDShareoptionsMessageTag,
    NTDShareoptionsTweetTag,
    NTDShareoptionsFacebookTag
};

typedef NS_ENUM(NSInteger, NTDAboutoptionsTags) {
    NTDAboutoptionsVisitTag = 0,
    NTDAboutoptionsFollowTag
};

@interface NTDOptionsViewController ()

@property (nonatomic) CGFloat compressedOptionSubviewHeight;
@property (nonatomic) CGFloat compressedOptionHeight;
@property (nonatomic) CGFloat initialSidebarWidth;

@property (nonatomic) BOOL optionIsExpanded;

@end

static CGFloat CompressedColorHeight = 12.0f;
static CGFloat OptionTopInsetWhenExpanded = 15.0f;
static NSTimeInterval ExpandMenuAnimation = 0.3;

@implementation NTDOptionsViewController
@synthesize colors;
@synthesize options, doneButton, toggleStatusBarButton;
@synthesize shareOptionsView, settingsOptionsView, aboutOptionsView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add subviews and make sure bounds are kept intact
    [self.view addSubview:self.options];
    [self.view addSubview:self.colors];
    [self.view addSubview:self.doneButton];
    
    // layout colors and options
    // options stay a static height, colors are variable
    self.compressedOptionSubviewHeight = self.options.frame.size.height;
    self.compressedOptionHeight = ((UIView *)self.options.subviews[0]).$height;
    
    [self reset];
    
    self.options.clipsToBounds = YES;
    
    // set up inner options
    for (UIView *optionView in self.options.subviews) {
        
        optionView.clipsToBounds = YES;
        
        UITapGestureRecognizer *optionTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(optionTapped:)];        
        UIView *choicesView;
        
        switch (optionView.tag) {
            case NTDoptionsShareTag:
            {
                choicesView = self.shareOptionsView;                
                break;
            }
                
            case NTDoptionsSettingsTag:
            {
                choicesView = self.settingsOptionsView;                
                break;
            }
                
            case NTDoptionsAboutTag:
            {
                choicesView = self.aboutOptionsView;                
                break;
            }
                
            default:
                break;
        }
        
        choicesView.$y = optionView.frame.size.height-1;
        [optionView addSubview:choicesView];
        [optionView addGestureRecognizer:optionTapGestureRecognizer];
        
    }
    
    // initialize correct colors and add gestures
    for (UIView *color in self.colors.subviews) {
        
        UITapGestureRecognizer *colorTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(colorTapped:)];
        
        [color addGestureRecognizer:colorTapGestureRecognizer];
        
        color.backgroundColor = [[NTDTheme themeForColorScheme:color.tag] backgroundColor];
    }
    
    // options
    for (UIView *choice in self.aboutOptionsView.subviews) {
        
        UITapGestureRecognizer *aboutTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(aboutTapped:)];
        [choice addGestureRecognizer:aboutTapGestureRecognizer];
        
    }
    
    // share
    for (UIView *choice in self.shareOptionsView.subviews) {
        
        UITapGestureRecognizer *shareTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(shareTapped:)];
        [choice addGestureRecognizer:shareTapGestureRecognizer];
    }
    
    // buttons
    [self.doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.toggleStatusBarButton addTarget:self action:@selector(toggleStatusBar:) forControlEvents:UIControlEventTouchUpInside];
    
//    self.hasSetUpView = YES;
    
    // check the status bar
    BOOL show = ![[UIApplication sharedApplication] isStatusBarHidden];
    [self.toggleStatusBarButton setTitle:!show?@"OFF":@"ON" forState:UIControlStateNormal];
    
}

- (void)viewWillAppear:(BOOL)animated   {
    [super viewWillAppear:animated];
}

#pragma mark -  Gesture Recognition

- (void) colorTapped:(UITapGestureRecognizer *)sender
{
    UIColor *noteColor = [[NTDTheme themeForColorScheme:sender.view.tag] backgroundColor];
    [self.delegate setNoteColor:noteColor textColor:nil];
}

- (void) optionTapped:(UITapGestureRecognizer *)sender
{
    if (self.optionIsExpanded)
        return;
    
    // epand the option
    switch (sender.view.tag) {
        case NTDoptionsShareTag:
        case NTDoptionsSettingsTag:
        case NTDoptionsAboutTag:
            [UIView animateWithDuration:ExpandMenuAnimation
                             animations:^{
                                 [self expandOptionWithTag:sender.view.tag];
                             } completion:^(BOOL finished) {
                                 self.optionIsExpanded = YES;
                             }];
            break;
    }
}

- (void) doneTapped:(UIButton *)sender
{
    if (self.optionIsExpanded) {
        [self.delegate changeOptionsViewWidth:[self.delegate initialOptionsViewWidth]];
        
        [UIView animateWithDuration:ExpandMenuAnimation
                         animations:^{
                             [self reset];
                             
                         }];
    }
}

- (void) toggleStatusBar:(UIButton *)sender {
    
    BOOL show = ![[UIApplication sharedApplication] isStatusBarHidden];
    [self.toggleStatusBarButton setTitle:show?@"OFF":@"ON" forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication] setStatusBarHidden:show withAnimation:YES];
    
    [[NSUserDefaults standardUserDefaults] setBool:show forKey:HIDE_STATUS_BAR];
    [[NSUserDefaults standardUserDefaults] synchronize];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:ToggleStatusBarNotification object:nil userInfo:nil];
    
    [self expandOptionWithTag:NTDoptionsSettingsTag];
}

- (void) shareTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDShareoptionsEmailTag:
            [self.delegate sendEmail];
            break;
            
        case NTDShareoptionsMessageTag:
            [self.delegate sendSMS];
            break;
            
        case NTDShareoptionsTweetTag:
            [self.delegate sendTweet];
            break;
            
        case NTDShareoptionsFacebookTag:
            // [self.delegate shareFacebook];
            break;
            
        default:
            break;
    }
}

- (void) aboutTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDAboutoptionsVisitTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://tackmobile.com"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
            
        case NTDAboutoptionsFollowTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://twitter.com/tackmobile"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Positioning
- (void) expandOptionWithTag:(NSInteger)tag
{
    // compress colors and expand options
    CGRect colorsFrame = self.colors.frame;
    colorsFrame.size.height = CompressedColorHeight;
    
    CGRect optionsFrame = self.options.frame;
    optionsFrame.origin.y = CompressedColorHeight - OptionTopInsetWhenExpanded;
    optionsFrame.size.height = self.view.frame.size.height - optionsFrame.origin.y;
    
    CGRect doneFrame = self.doneButton.frame;
    doneFrame.origin.y = self.view.frame.size.height - doneFrame.size.height;
    
    self.colors.frame = colorsFrame;
    self.options.frame = optionsFrame;
    self.doneButton.frame = doneFrame;
    
    for (UIView *optionView in options.subviews) {
        
        CGRect optionFrame = optionView.frame;
        
        if (optionView.tag < tag) {
            // shift the option up and out of view. accounting for 1px spacer
            //optionFrame = CGRectOffset(optionFrame, 0, (option.tag - tag) * (self.compressedOptionHeight + 1));
            optionView.alpha = 0;
        } else if (optionView.tag == tag) {
            optionFrame.origin.y = 0;
            optionFrame.size.height = optionsFrame.size.height;
            
            NSArray *optionSubviews = [optionView subviews];
            // fade the option group title
            [[optionSubviews objectAtIndex:0] setAlpha:.7];
            
            // expand necessary space
            [self.delegate changeOptionsViewWidth:((UIView *)optionSubviews[1]).$width];
        } else {
            optionView.alpha =0;
        }
        
        optionView.frame = optionFrame;
    }
}

- (void) reset {
    CGSize mySize = self.view.bounds.size;
    CGRect colorsFrame = {
        .origin = CGPointZero,
        .size.width = mySize.width,
        .size.height = mySize.height - self.compressedOptionSubviewHeight
    };
    CGRect optionsFrame = {
        .origin.x = 0,
        .origin.y = mySize.height - self.compressedOptionSubviewHeight,
        .size.width = mySize.width,
        .size.height = self.compressedOptionSubviewHeight
    };
    
    CGRect doneFrame = {
        .origin.x = 0,
        .origin.y = mySize.height,
        .size = self.doneButton.frame.size
    };
    
    self.colors.frame = colorsFrame;
    self.options.frame = optionsFrame;
    self.doneButton.frame = doneFrame;
    
    [self.options.subviews enumerateObjectsUsingBlock:^(UIView *optionView, NSUInteger idx, BOOL *stop) {
        // make sure title labels are at full alpha
        NSArray *optionChoices = optionView.subviews;
        [[optionChoices objectAtIndex:0] setAlpha:1];
        optionView.alpha =1;
        
        // evenly space option choices
        CGRect optionFrame = optionView.frame;
        optionFrame.origin.y = idx * self.compressedOptionHeight;
        
        optionView.frame = optionFrame;
    }];
        
    self.optionIsExpanded = NO;
}

@end
