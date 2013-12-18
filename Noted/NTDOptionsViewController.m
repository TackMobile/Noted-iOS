//
//  NTDOptionsViewController.m
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>
#import <FlurrySDK/Flurry.h>
#import <BlocksKit/BlocksKit.h>
#import "NTDOptionsViewController.h"
#import "UIViewController+NTDToast.h"
#import "NTDWalkthrough.h"
#import "NTDModalView.h"
#import "NTDDropboxManager.h"

NSString *const NTDDidToggleStatusBarNotification = @"didToggleStatusBar";

@interface NTDOptionsViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

// colors
@property (weak, nonatomic) IBOutlet NTDColorPicker *colors;

// options
@property (weak, nonatomic) IBOutlet UIView *options;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleStatusBarButton;

@property (weak, nonatomic) IBOutlet UIView *shareOptionsView;
@property (weak, nonatomic) IBOutlet UIView *settingsOptionsView;
@property (weak, nonatomic) IBOutlet UIView *aboutOptionsView;
@property (weak, nonatomic) IBOutlet UILabel *toggleDropboxLabel;

@end

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

typedef NS_ENUM(NSInteger, NTDOptionsTags) {
    NTDOptionsShareTag = 0,
    NTDOptionsSettingsTag,
    NTDOptionsAboutTag,
    NTDOptionsVersionTag
};

typedef NS_ENUM(NSInteger, NTDAboutOptionsTags) {
    NTDAboutOptionsTackTag = 0,
    NTDAboutOptionsVisitTag,
    NTDAboutOptionsFollowTag,
    NTDAboutOptionsFeedbackTag,
    NTDAboutOptionsSupportTag,
    NTDAboutOptionsWalkthroughTag
};

@interface NTDOptionsViewController ()

@property (nonatomic) CGFloat compressedOptionSubviewHeight;
@property (nonatomic) CGFloat compressedOptionHeight;
@property (nonatomic) CGFloat initialSidebarWidth;

@property (nonatomic) BOOL optionIsExpanded;

@property (nonatomic, strong) MFMailComposeViewController *mailViewController;
@property (nonatomic, strong) MFMessageComposeViewController *messageViewController;
@property (nonatomic, strong) SLComposeViewController *composeViewController;

@end

static CGFloat CompressedColorHeight = 12.0f;
static CGFloat OptionTopInsetWhenExpanded = 15.0f;
static NSTimeInterval ExpandMenuAnimationDuration = 0.3;

@implementation NTDOptionsViewController
@synthesize colors;
@synthesize options, doneButton, toggleStatusBarButton;
@synthesize shareOptionsView, settingsOptionsView, aboutOptionsView;

- (id)init
{
    if (self = [super initWithNibName:nil bundle:nil]) {
    }
    return self;
}

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
        
    self.options.clipsToBounds = YES;
    
    // set up inner options
    for (UIView *optionView in self.options.subviews) {
        
        optionView.clipsToBounds = YES;
        
        UITapGestureRecognizer *optionTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(optionTapped:)];        
        UIView *choicesView;
        
        switch (optionView.tag) {
            case NTDOptionsShareTag:
            {
                choicesView = self.shareOptionsView;                
                break;
            }
                
            case NTDOptionsSettingsTag:
            {
                choicesView = self.settingsOptionsView;                
                break;
            }
                
            case NTDOptionsAboutTag:
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
    [self createShareOptions];
    for (UIView *choice in self.shareOptionsView.subviews) {
        
        UITapGestureRecognizer *shareTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(shareTapped:)];
        [choice addGestureRecognizer:shareTapGestureRecognizer];
    }
    
    // buttons
    [self.doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.toggleStatusBarButton addTarget:self action:@selector(toggleStatusBar:) forControlEvents:UIControlEventTouchUpInside];
    
    // check the status bar
    BOOL show = ![[UIApplication sharedApplication] isStatusBarHidden];
    [self.toggleStatusBarButton setTitle:!show?@"OFF":@"ON" forState:UIControlStateNormal];
    
    // set version number
    /* I have to do this the weird way because the main view has multiple child views with the same tag
     * and the simple way didn't work. */
    UIView *versionContainerView = [self.options.subviews bk_match:^BOOL(UIView *view) {
        return view.tag == NTDOptionsVersionTag;
    }];
//    UILabel *versionLabel = [[self.options viewWithTag:NTDOptionsVersionTag] subviews][0]; /* "simple" way */
    UILabel *versionLabel = [versionContainerView subviews][0];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text = version;

    // Dropbox
    self.toggleDropboxLabel.userInteractionEnabled = YES;
    self.toggleDropboxLabel.onTouchDownBlock = ^(NSSet *touches, UIEvent *event) {
        NSString *msg = @"Would you like to enable Dropbox?";
        __block NTDModalView *modalView = [[NTDModalView alloc] initwithMessage:msg handler:^(BOOL userClickedYes) {
            if (userClickedYes) {
                [self.delegate dismissOptions];
                [NTDDropboxManager linkAccountFromViewController:self];
            }
            [modalView dismiss];
        }];
        [modalView show];
    };
    [self reset];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)createShareOptions
{
    for (UIView *subview in self.shareOptionsView.subviews)
        [subview removeFromSuperview];
    
    NSMutableArray *optionsTitles = [@[@"Email", @"Message", @"Copy", @"Twitter", @"Facebook", @"Sina Weibo"]
                                     mutableCopy];
    if (![MFMailComposeViewController canSendMail])
        [optionsTitles removeObject:@"Email"];
    if (![MFMessageComposeViewController canSendText])
        [optionsTitles removeObject:@"Message"];
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
        [optionsTitles removeObject:@"Facebook"];
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        [optionsTitles removeObject:@"Twitter"];
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo])
        [optionsTitles removeObject:@"Sina Weibo"];
    
    CGRect InitialOptionFrame = CGRectMake(0, 1, 221, 53);
    CGRect InitialShareLabelFrame = CGRectMake(14, 24, 149, 22);
    UIFont *labelFont = [UIFont fontWithName:@"Avenir-Light" size:16];
    
    int i = 0; CGFloat shareOptionsHeight = 0;
    for (NSString *title in optionsTitles) {
        CGRect optionFrame = CGRectOffset(InitialOptionFrame, 0, i*(1+CGRectGetHeight(InitialOptionFrame)));
        UIView *optionView = [[UIView alloc] initWithFrame:optionFrame];
        UILabel *shareLabel = [[UILabel alloc] initWithFrame:InitialShareLabelFrame];
        shareLabel.text = title;
        shareLabel.font = labelFont;
        shareLabel.textColor = [UIColor whiteColor];
        shareLabel.backgroundColor = [UIColor blackColor];
        optionView.backgroundColor = [UIColor blackColor];
        [optionView addSubview:shareLabel];
        [self.shareOptionsView addSubview:optionView];
        i++;
        shareOptionsHeight = CGRectGetMaxY(optionFrame);
    }
    self.shareOptionsView.$height = shareOptionsHeight+1;
}

#pragma mark -  Gesture Recognition

- (void) colorTapped:(UITapGestureRecognizer *)sender
{    
    NTDTheme *noteTheme = [NTDTheme themeForColorScheme:sender.view.tag];
    self.note.theme = noteTheme;
    [self.delegate didChangeNoteTheme];
}

- (void) optionTapped:(UITapGestureRecognizer *)sender
{
    if (self.optionIsExpanded)
        return;
    
    // expand the option
    switch (sender.view.tag) {
        case NTDOptionsShareTag:
        case NTDOptionsSettingsTag:
        case NTDOptionsAboutTag:
            [UIView animateWithDuration:ExpandMenuAnimationDuration
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
        
        [UIView animateWithDuration:ExpandMenuAnimationDuration
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
        
    [[NSNotificationCenter defaultCenter] postNotificationName:NTDDidToggleStatusBarNotification object:nil userInfo:nil];
    
    [self expandOptionWithTag:NTDOptionsSettingsTag];
}

- (void) shareTapped:(UITapGestureRecognizer *)sender
{
    NSString *title = [(UILabel *)sender.view.subviews[0] text];
    if ([title isEqualToString:@"Email"])
        [self sendEmail];
    else if ([title isEqualToString:@"Message"])
        [self sendSMS];
    else if ([title isEqualToString:@"Copy"])
        [self copyToPasteboard];
    else if ([title isEqualToString:@"Facebook"])
        [self createSocialPostForServiceType:SLServiceTypeFacebook];
    else if ([title isEqualToString:@"Twitter"])
        [self createSocialPostForServiceType:SLServiceTypeTwitter];
    else if ([title isEqualToString:@"Sina Weibo"])
        [self createSocialPostForServiceType:SLServiceTypeSinaWeibo];
    else
        NSLog(@"ERROR: Unknown option tapped: %@", title);
}

- (void) aboutTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDAboutOptionsTackTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://tackmobile.com"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }

        case NTDAboutOptionsVisitTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://takenoted.com"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
            
        case NTDAboutOptionsFollowTag:
        {
//            NSURL *tweetbotAppURL = [NSURL URLWithString:@"tweetbot://TakeNoted/timeline"];
            NSURL *twitterAppURL = [NSURL URLWithString:@"twitter://user?screen_name=TakeNoted"];
            NSURL *webURL = [NSURL URLWithString:@"http://twitter.com/TakeNoted"];
            NSArray *urls = @[/*tweetbotAppURL,*/ twitterAppURL, webURL];
            for (NSURL *url in urls) {
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                    break;
                }
            }
            break;
        }
            
        case NTDAboutOptionsFeedbackTag:
        {
            NSURL *url = [NSURL URLWithString:@"mailto:noted@tackmobile.com?subject=Noted%20Feedback"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
        
        case NTDAboutOptionsSupportTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://takenoted.com/support.html"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
            
        case NTDAboutOptionsWalkthroughTag:
            [NTDWalkthrough.sharedWalkthrough promptUserToStartWalkthrough];
            [self.delegate dismissOptions];
        default:
            break;
    }
}

#pragma mark - Sharing Actions
- (NSString *)sharingText
{
    return (self.selectedText) ?: self.note.text;
}

- (void)sendSMS
{
    if (![MFMessageComposeViewController canSendText])
        return;

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    self.messageViewController = controller;
    controller.body = self.sharingText;
    controller.messageComposeDelegate = self;
    [self.delegate presentViewController:controller
                                animated:YES
                              completion:nil];
}

- (void)sendEmail
{
    if (![MFMailComposeViewController canSendMail])
        return;
    
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    self.mailViewController = controller;
    
    NSString *noteText = self.sharingText;
    __block NSString *noteTitle;
    [noteText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        noteTitle = line;
        *stop = TRUE;
    }];
    if (noteTitle.length > 24)
        noteTitle = [NSString stringWithFormat:@"%@...", [noteTitle substringToIndex:24]];
    
	[controller setSubject:noteTitle];
	[controller setMessageBody:noteText isHTML:NO];
    [self.delegate presentViewController:controller
                                animated:YES
                              completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.delegate dismissViewControllerAnimated:YES completion:^{
        self.mailViewController = nil;
    }];
    if (result == MFMailComposeResultSent) [Flurry logEvent:@"Note Shared" withParameters:@{@"type" : @"mail"}];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self.delegate dismissViewControllerAnimated:YES completion:^{
        self.messageViewController = nil;
    }];
    if (result == MessageComposeResultSent) [Flurry logEvent:@"Note Shared" withParameters:@{@"type" : @"sms"}];
}

- (void)createSocialPostForServiceType:(NSString *)serviceType
{
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    self.composeViewController = controller;
    BOOL didTextFit = [controller setInitialText:self.sharingText];
    if (!didTextFit) [controller setInitialText:[self.sharingText substringToIndex:140]];
    [controller setCompletionHandler:^(SLComposeViewControllerResult result) {
        self.composeViewController = nil;
        if (result == SLComposeViewControllerResultDone) [Flurry logEvent:@"Note Shared" withParameters:@{@"type" : serviceType}];
    }];
    [self.delegate presentViewController:controller
                                animated:YES
                              completion:nil];
}

- (void)copyToPasteboard
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setValue:self.sharingText forPasteboardType:(NSString *)kUTTypeText];
    
    [self.delegate showToastWithMessage:@"Text copied to clipboard"];
    [Flurry logEvent:@"Note Shared" withParameters:@{@"type" : @"copied"}];
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
