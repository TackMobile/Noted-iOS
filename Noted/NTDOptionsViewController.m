//
//  NTDOptionsViewController.m
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDOptionsViewController.h"
#import "NTDTheme.h"

@implementation NTDColorPicker

- (void) layoutSubviews {
    [super layoutSubviews];
    
    NSInteger subViewCount = [[self subviews] count];
    CGSize mySize = self.frame.size;
    CGSize colorSize = {
        .width = mySize.width,
        .height = (mySize.height - (subViewCount -1)) / subViewCount
    };
    
    [[self subviews] enumerateObjectsUsingBlock:^(UIView *color, NSUInteger idx, BOOL *stop) {
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
typedef NS_ENUM(NSInteger, NTDColorsSubviewTags) {
    NTDColorsSubviewWhiteTag = 0,
    NTDColorsSubviewSkyTag,
    NTDColorsSubviewLimeTag,
    NTDColorsSubviewKernalTag,
    NTDColorsSubviewShadowTag,
    NTDColorsSubviewTackTag
};

typedef NS_ENUM(NSInteger, NTDOptionsSubviewTags) {
    NTDOptionsSubviewShareTag = 0,
    NTDOptionsSubviewSettingsTag,
    NTDOptionsSubviewAboutTag
};

typedef NS_ENUM(NSInteger, NTDShareOptionsSubviewTags) {
    NTDShareOptionsSubviewEmailTag = 0,
    NTDShareOptionsSubviewMessageTag,
    NTDShareOptionsSubviewTweetTag,
    NTDShareOptionsSubviewFacebookTag
};

typedef NS_ENUM(NSInteger, NTDAboutOptionsSubviewTags) {
    NTDAboutOptionsSubviewVisitTag = 0,
    NTDAboutOptionsSubviewFollowTag
};

@interface NTDOptionsViewController ()

@property (nonatomic) CGFloat compressedOptionSubviewHeight;
@property (nonatomic) CGFloat compressedOptionHeight;
@property (nonatomic) CGFloat initialSidebarWidth;

@property (nonatomic) BOOL optionIsExpanded;
@property (nonatomic) BOOL hasSetUpView;

@end

const CGFloat CompressedColorHeight = 12.0f;
const CGFloat OptionTopInsetWhenExpanded = 15.0f;
const float AnimationDuration = .3;

@implementation NTDOptionsViewController
@synthesize colorsSubview;
@synthesize optionsSubview, doneButton, toggleStatusBarButton;
@synthesize shareOptionsView, settingsOptionsView, aboutOptionsView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hasSetUpView = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add subviews and make sure bounds are kept intact
    [self.view addSubview:self.optionsSubview];
    [self.view addSubview:self.colorsSubview];
    [self.view addSubview:self.doneButton];
    
}

- (void)viewWillAppear:(BOOL)animated   {
    [super viewWillAppear:animated];
    
    if (!self.hasSetUpView) {
        // layout colors and options
        // options stay a static height, colors are variable
        self.compressedOptionSubviewHeight = self.optionsSubview.frame.size.height;
        self.compressedOptionHeight = [(UIView *)[[self.optionsSubview subviews] objectAtIndex:0] frame].size.height;
        
        [self reset];
        
        self.optionsSubview.clipsToBounds = YES;
        
        // set up inner options
        [[self.optionsSubview subviews] enumerateObjectsUsingBlock:^(UIView *option, NSUInteger idx, BOOL *stop) {
            
            option.clipsToBounds = YES;
            
            UITapGestureRecognizer *optionTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                        action:@selector(optionTapped:)];
            [option addGestureRecognizer:optionTapGestureRecognizer];
            
            switch (option.tag) {
                case NTDOptionsSubviewShareTag:
                {
                    CGRect shareFrame = self.shareOptionsView.frame;
                    shareFrame.origin.y = option.frame.size.height-1;
                    
                    [option addSubview:self.shareOptionsView];
                    self.shareOptionsView.frame = shareFrame;
                    
                    break;
                }
                    
                case NTDOptionsSubviewSettingsTag:
                {
                    CGRect settingsFrame = self.settingsOptionsView.frame;
                    settingsFrame.origin.y = option.frame.size.height-1;
                    
                    [option addSubview:self.settingsOptionsView];
                    self.settingsOptionsView.frame = settingsFrame;
                    
                    break;
                }
                    
                case NTDOptionsSubviewAboutTag:
                {
                    CGRect aboutFrame = self.aboutOptionsView.frame;
                    aboutFrame.origin.y = option.frame.size.height-1;
                    
                    [option addSubview:self.aboutOptionsView];
                    self.aboutOptionsView.frame = aboutFrame;
                    
                    break;
                }
                    
                default:
                    break;
            }
            
        }];
        
        // initialize correct colors and add gestures
        [[self.colorsSubview subviews] enumerateObjectsUsingBlock:^(UIView *color, NSUInteger idx, BOOL *stop) {
            
           UITapGestureRecognizer *colorTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(colorTapped:)];

            [color addGestureRecognizer:colorTapGestureRecognizer];
            
            color.backgroundColor = [[NTDTheme themeForColorScheme:color.tag] backgroundColor];
        }];
        
        // options
        [[self.aboutOptionsView subviews] enumerateObjectsUsingBlock:^(UIView *choice, NSUInteger idx, BOOL *stop) {
            
            UITapGestureRecognizer *aboutTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                        action:@selector(aboutTapped:)];
            [choice addGestureRecognizer:aboutTapGestureRecognizer];
            
        }];
        
        // share
        [[self.shareOptionsView subviews] enumerateObjectsUsingBlock:^(UIView *choice, NSUInteger idx, BOOL *stop) {
            
            UITapGestureRecognizer *shareTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                        action:@selector(shareTapped:)];
            [choice addGestureRecognizer:shareTapGestureRecognizer];
        }];
        
        // buttons
        [self.doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.toggleStatusBarButton addTarget:self action:@selector(toggleStatusBar:) forControlEvents:UIControlEventTouchUpInside];
        
        self.hasSetUpView = YES;
        
        // check the status bar
        BOOL show = ![[UIApplication sharedApplication] isStatusBarHidden];
        [self.toggleStatusBarButton setTitle:!show?@"OFF":@"ON" forState:UIControlStateNormal];

    }
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
        case NTDOptionsSubviewShareTag:
        case NTDOptionsSubviewSettingsTag:
        case NTDOptionsSubviewAboutTag:
            [UIView animateWithDuration:AnimationDuration
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
        
        [UIView animateWithDuration:AnimationDuration
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
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didToggleStatusBar" object:nil userInfo:nil];
    
    [self expandOptionWithTag:NTDOptionsSubviewSettingsTag];
}

- (void) shareTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDShareOptionsSubviewEmailTag:
            [self.delegate sendEmail];
            break;
            
        case NTDShareOptionsSubviewMessageTag:
            [self.delegate sendSMS];
            break;
            
        case NTDShareOptionsSubviewTweetTag:
            [self.delegate sendTweet];
            break;
            
        case NTDShareOptionsSubviewFacebookTag:
            // [self.delegate shareFacebook];
            break;
            
        default:
            break;
    }
}

- (void) aboutTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDAboutOptionsSubviewVisitTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://tackmobile.com"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
            
        case NTDAboutOptionsSubviewFollowTag:
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
    CGRect colorsFrame = self.colorsSubview.frame;
    colorsFrame.size.height = CompressedColorHeight;
    
    CGRect optionsFrame = self.optionsSubview.frame;
    optionsFrame.origin.y = CompressedColorHeight - OptionTopInsetWhenExpanded;
    optionsFrame.size.height = self.view.frame.size.height - optionsFrame.origin.y;
    
    CGRect doneFrame = self.doneButton.frame;
    doneFrame.origin.y = self.view.frame.size.height - doneFrame.size.height;
    
    self.colorsSubview.frame = colorsFrame;
    self.optionsSubview.frame = optionsFrame;
    self.doneButton.frame = doneFrame;
    
    [[optionsSubview subviews] enumerateObjectsUsingBlock:^(UIView *option, NSUInteger idx, BOOL *stop) {
        CGRect optionFrame = option.frame;
        
        if (option.tag < tag) {
            // shift the option up and out of view. accounting for 1px spacer
            //optionFrame = CGRectOffset(optionFrame, 0, (option.tag - tag) * (self.compressedOptionHeight + 1));
            option.alpha = 0;
        } else if (option.tag == tag) {
            optionFrame.origin.y = 0;
            optionFrame.size.height = optionsFrame.size.height;
            
            NSArray *optionSubviews = [option subviews];
            // fade the option group title
            [[optionSubviews objectAtIndex:0] setAlpha:.7];
            
            // expand necessary space
            [self.delegate changeOptionsViewWidth:[(UIView *)[optionSubviews objectAtIndex:1] frame].size.width];
        } else {
            option.alpha =0;
            //optionFrame.origin.y = optionsFrame.size.height + (option.tag - tag - 1) * (self.compressedOptionHeight + 1);
        }
        
        option.frame = optionFrame;
    }];
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
    
    self.colorsSubview.frame = colorsFrame;
    self.optionsSubview.frame = optionsFrame;
    self.doneButton.frame = doneFrame;
    
    [[optionsSubview subviews] enumerateObjectsUsingBlock:^(UIView *option, NSUInteger idx, BOOL *stop) {
        // make sure title labels are at full alpha
        NSArray *optionChoices = [option subviews];
        [[optionChoices objectAtIndex:0] setAlpha:1];
        option.alpha =1;
        
        // evenly space option choices
        CGRect optionFrame = option.frame;
        optionFrame.origin.y = idx * self.compressedOptionHeight;
        
        option.frame = optionFrame;
    }];
        
    self.optionIsExpanded = NO;
}

@end
