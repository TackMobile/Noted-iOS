//
//  NTDOptionsViewController.m
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDOptionsViewController.h"
#import "UIView+FrameAdditions.h"
#import <Twitter/Twitter.h>
#import "ApplicationModel.h"

NSString *const NTDDidToggleStatusBarNotification = @"didToggleStatusBar";

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
    NTDOptionsAboutTag
};

typedef NS_ENUM(NSInteger, NTDShareOptionsTags) {
    NTDShareOptionsEmailTag = 0,
    NTDShareOptionsMessageTag,
    NTDShareOptionsTweetTag,
    NTDShareOptionsFacebookTag
};

typedef NS_ENUM(NSInteger, NTDAboutOptionsTags) {
    NTDAboutOptionsVisitTag = 0,
    NTDAboutOptionsFollowTag
};

@interface NTDOptionsViewController ()

@property (nonatomic) CGFloat compressedOptionSubviewHeight;
@property (nonatomic) CGFloat compressedOptionHeight;
@property (nonatomic) CGFloat initialSidebarWidth;

@property (nonatomic) BOOL optionIsExpanded;

@property (nonatomic, strong) MFMailComposeViewController *mailViewController;
@property (nonatomic, strong) MFMessageComposeViewController *messageViewController;


@end

static CGFloat CompressedColorHeight = 12.0f;
static CGFloat OptionTopInsetWhenExpanded = 15.0f;
static NSTimeInterval ExpandMenuAnimationDuration = 0.3;

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
    NTDTheme *noteTheme = [NTDTheme themeForColorScheme:sender.view.tag];
    [self.visibleCell applyTheme:noteTheme];
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

- (void) shareTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDShareOptionsEmailTag:
            [self sendEmail];
            break;
            
        case NTDShareOptionsMessageTag:
            [self sendSMS];
            break;
            
        case NTDShareOptionsTweetTag:
            [self sendTweet];
            break;
            
        case NTDShareOptionsFacebookTag:
            // [self.delegate shareFacebook];
            break;
            
        default:
            break;
    }
}

- (void) aboutTapped:(UITapGestureRecognizer *)sender {
    switch (sender.view.tag) {
        case NTDAboutOptionsVisitTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://tackmobile.com"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
            
        case NTDAboutOptionsFollowTag:
        {
            NSURL *url = [NSURL URLWithString:@"http://twitter.com/tackmobile"];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Sharing Actions
//TODO: Clean this up.
- (void)sendTweet
{
    NSString *noteText = [self getNoteTextAsMessage];
    
    if (SYSTEM_VERSION_LESS_THAN(@"6")){
        if([TWTweetComposeViewController canSendTweet])
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            [tweetViewController setInitialText:noteText];
            
            tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result)
            {
                // Dismiss the controller
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            [(UIViewController *)self.delegate presentViewController:tweetViewController animated:YES completion:nil];
            
        }else {
            NSString * message = [NSString stringWithFormat:@"This device is currently not configured to send tweets."];
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6")) {
        // 3
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            // 4
            //[self.tweetText setAlpha:0.5f];
        } else {
            // 5
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [composeViewController setInitialText:noteText];
            [(UIViewController *)self.delegate presentViewController:composeViewController animated:YES completion:nil];
        }
    }
}

- (void)sendSMS
{
    if([MFMessageComposeViewController canSendText])
    {
        self.messageViewController = [[MFMessageComposeViewController alloc] init];
        self.messageViewController.body = [self getNoteTextAsMessage];
        self.messageViewController.messageComposeDelegate = self;
        self.messageViewController.wantsFullScreenLayout = NO;
        [(UIViewController *)self.delegate presentViewController:self.messageViewController animated:YES completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    else {
        NSString * message = [NSString stringWithFormat:@"This device is currently not configured to send text messages."];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)sendEmail
{
    if (![MFMailComposeViewController canSendMail]) return; //TODO fix
    
    self.mailViewController = [[MFMailComposeViewController alloc] init];
    self.mailViewController.mailComposeDelegate = self;
    
    NSString *noteText = self.visibleCell.textView.text;
    NSString* noteTitle;
    if (noteText.length > 24)
        noteTitle = [NSString stringWithFormat:@"%@...", [noteText substringToIndex:24]];
    else
        noteTitle = noteText;
    
    NSString *body = [[NSString alloc] initWithFormat:@"%@\n\n%@",
                      [self getNoteTextAsMessage],
                      @"Sent from Noted"];
    
	[self.mailViewController setSubject:noteTitle];
	[self.mailViewController setMessageBody:body isHTML:NO];
    [(UIViewController *)self.delegate presentViewController:self.mailViewController animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)getNoteTextAsMessage
{
    NSString *noteText = self.visibleCell.textView.text;
    //noteText = [noteText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if ([noteText length] > 140) {
        noteText = [noteText substringToIndex:140];
    }
    return noteText;
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
