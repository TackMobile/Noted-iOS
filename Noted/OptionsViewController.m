//
//  OptionsViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "OptionsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import "UIColor+HexColor.h"
#import "FileStorageState.h"
#import "ApplicationModel.h"
#import "NoteEntry.h"

#define KEYBOARD_SETTINGS_SWITCH 88
#define STATUS_BAR_TOGGLE_SWITCH 89
#define ICLOUD_TOGGLE_SWITCH     90

@implementation OptionsViewController

@synthesize scrollView;

@synthesize colorSubView;
@synthesize white;
@synthesize sky;
@synthesize lime;
@synthesize kernal;
@synthesize shadow;
@synthesize tack,optionsSubview,shareText,settingsText,aboutText,versionText,cancelX,shareSubview,emailText,messageText,tweetText,aboutSubview,builtText,websiteText,tackTwitterText;
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadOptionColors];
    [self addAllGestures];
    
    [self setInitialPositionForColors];
    self.shareSubview.hidden = YES;
    self.aboutSubview.hidden = YES;
    self.settingsSubview.hidden = YES;
    [self.view addSubview:self.shareSubview];
    [self.view addSubview:self.aboutSubview];
    [self.view addSubview:self.settingsSubview];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    //add version number 
    self.versionText.text = [NSString stringWithFormat:@"v.%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    self.scrollView.scrollEnabled = YES;
    self.scrollView.bounces = YES;
    
    //make the corners
    self.scrollView.layer.bounds = CGRectMake(0, 0, 320, 480);

    
    CGRect newFrame = [[UIScreen mainScreen] applicationFrame];
    self.view.frame = newFrame;
}

- (void)setInitialPositionForColors
{
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect frame = CGRectMake(0, 74+appFrame.origin.y, 320, 163);
    self.shareSubview.frame = frame;
    self.aboutSubview.frame = frame;
    self.settingsSubview.frame = CGRectMake(0, 74, self.settingsSubview.frame.size.width, self.settingsSubview.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UISwitch *keyboardSwitch = (UISwitch *)[self.settingsSubview viewWithTag:KEYBOARD_SETTINGS_SWITCH];
    BOOL isOn = [[NSUserDefaults standardUserDefaults] boolForKey:USE_STANDARD_SYSTEM_KEYBOARD];
    [keyboardSwitch setOn:NO];
    
    UIButton *statusBarSwitch = (UIButton *)[self.settingsSubview viewWithTag:STATUS_BAR_TOGGLE_SWITCH];
    BOOL hide = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_STATUS_BAR];
    [self setButtonOn:statusBarSwitch on:!hide];
    
    UIButton *cloudStorageSwitch = (UIButton *)[self.settingsSubview viewWithTag:ICLOUD_TOGGLE_SWITCH];
    isOn = [FileStorageState preferredStorage] == kTKiCloud ? YES : NO;
    [self setButtonOn:cloudStorageSwitch on:isOn];
    // http://osiris.laya.com/projects/rcswitch/
}

- (void)setButtonOn:(UIButton *)button on:(BOOL)on
{
    if (on) {
        [button setTitle:@"ON" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.tag = 1;
    } else {
        [button setTitle:@"OFF" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
        button.tag = 0;
    }
}

-(void)loadOptionColors {
    self.white.backgroundColor = [UIColor colorWithHexString:@"FFFFFF"];
    self.sky.backgroundColor = [UIColor colorWithHexString:@"C4D5DD"];
    self.lime.backgroundColor = [UIColor colorWithHexString:@"C1D184"];
    self.kernal.backgroundColor = [UIColor colorWithHexString:@"DAC361"];
    self.shadow.backgroundColor = [UIColor colorWithHexString:@"333333"];
    self.tack.backgroundColor = [UIColor colorWithHexString:@"1A9FEB"];
    
    self.shareText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.settingsText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.aboutText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.versionText.textColor  = [UIColor colorWithHexString:@"CCCCCC"];
    self.optionsSubview.backgroundColor = [UIColor colorWithHexString:@"292929"];
    self.shareSubview.backgroundColor = [UIColor colorWithHexString:@"292929"];
    self.aboutSubview.backgroundColor = [UIColor colorWithHexString:@"292929"];
    self.settingsSubview.backgroundColor = [UIColor colorWithHexString:@"292929"];
    self.emailText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.messageText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.tweetText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.builtText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.websiteText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    self.tackTwitterText.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    
    self.cancelX.textColor = [UIColor colorWithHexString:@"CCCCCC"];
    
}


-(void)addAllGestures {
    UITapGestureRecognizer *whiteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    UITapGestureRecognizer *skyTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    UITapGestureRecognizer *limeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    UITapGestureRecognizer *kernalTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    UITapGestureRecognizer *shadowTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    UITapGestureRecognizer *tackTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeColor:)];
    [self.white addGestureRecognizer:whiteTap];
    [self.sky addGestureRecognizer:skyTap];
    [self.lime addGestureRecognizer:limeTap];
    [self.kernal addGestureRecognizer:kernalTap];
    [self.shadow addGestureRecognizer:shadowTap];
    [self.tack addGestureRecognizer:tackTap];
    
    UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(returnToOptions)];
    [self.cancelX addGestureRecognizer:closeTap];
    
}

-(void)returnToOptions {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0) completion:nil];
    
    [self reset];
    
}

- (void)reset
{
    [self.cancelX removeFromSuperview];
    
    [self reenableMenu];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.white.frame = CGRectMake(0, 0, 320, 43);
                         self.sky.frame = CGRectMake(0, 44, 320, 43);
                         self.lime.frame = CGRectMake(0,88, 320, 43);
                         self.kernal.frame = CGRectMake(0, 132, 320, 43);
                         self.shadow.frame = CGRectMake(0, 176, 320, 43);
                         self.tack.frame = CGRectMake(0, 220, 320, 43);
                         self.shareText.frame = CGRectMake(0, 1, 320, 53);
                         self.settingsText.frame = CGRectMake(0, 54, 320, 53);
                         self.aboutText.frame = CGRectMake(0, 108, 320, 53);
                         self.versionText.frame = CGRectMake(0, 162, 320, 53);
                     } completion:^(BOOL success){
                         [self reenableMenu];
                     }];

}

-(void)openShare:(id)sender {
    NSLog(@"%@",NSStringFromCGRect(self.shareText.frame));
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(120, 0) completion:nil];
    [self setColorsToCollapsedStateWithDuration:0.3];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.shareText.frame = CGRectMake(0, -244, 320, 480);
                         self.settingsText.frame = CGRectMake(0, 216, 320, 53);
                         self.aboutText.frame = CGRectMake(0, 269, 320, 53);
                         self.versionText.frame = CGRectMake(0, 322, 320, 53);
                     } completion:^(BOOL success){
                         self.cancelX.frame = [self frameForCancelButtonWithXOffset:120.0];
                         [self.view addSubview:self.cancelX];
                         [self setSubviewVisible:self.shareSubview button:self.shareText];
                     }];
    
}

- (CGRect)frameForCancelButtonWithXOffset:(CGFloat)xPos
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    return CGRectMake(10.0, frame.size.height-35.0, 67.0, 35.0);
}

- (void)setColorsToCollapsedStateWithDuration:(float)duration
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    float baselineY = frame.origin.y;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.white.frame = CGRectMake(0, baselineY+0, 320, 1);
                         self.sky.frame = CGRectMake(0, baselineY+2, 320, 1);
                         self.lime.frame = CGRectMake(0, baselineY+4, 320, 1);
                         self.kernal.frame = CGRectMake(0, baselineY+6, 320, 1);
                         self.shadow.frame = CGRectMake(0, baselineY+8, 320, 1);
                         self.tack.frame = CGRectMake(0, baselineY+10, 320, 1);
                     } completion:^(BOOL success){
                         
                     }];
}

-(void)openAbout:(id)sender {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(200, 0) completion:nil];
    [self setColorsToCollapsedStateWithDuration:0.3];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.shareText.frame = CGRectMake(0, -244, 320, 1);
                         self.settingsText.frame = CGRectMake(0, -244, 320, 1);
                         self.aboutText.frame = CGRectMake(0, -244, 320, 480);
                         self.versionText.frame = CGRectMake(0, 322, 320, 53);
                     } completion:^(BOOL success){
                         self.cancelX.frame = [self frameForCancelButtonWithXOffset:200.0];
                         [self.view addSubview:self.cancelX];
                         [self setSubviewVisible:self.aboutSubview button:self.aboutText];
                     }];
}

-(void)openSettings:(id)sender {
    
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(200, 0) completion:nil];
    [self setColorsToCollapsedStateWithDuration:0.3];
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.shareText.frame = CGRectMake(0, -244, 320, 1);
                         self.settingsText.frame = CGRectMake(0, -244, 320, 1);
                         self.aboutText.frame = CGRectMake(0, -244, 320, 480);
                         self.versionText.frame = CGRectMake(0, 322, 320, 53);
                     } completion:^(BOOL success){
                         self.cancelX.frame = [self frameForCancelButtonWithXOffset:200.0];
                         [self.view addSubview:self.cancelX];
                         [self setSubviewVisible:self.settingsSubview button:self.settingsText];
                     }];

}

- (void)setSubviewVisible:(UIView *)subview button:(UITextView *)textView
{
    [self disableMenu];
    
    subview.hidden = NO;
    textView.userInteractionEnabled = NO;
    [self.view addSubview:subview];
}

- (void)disableMenu
{
    self.shareSubview.hidden = YES;
    self.aboutSubview.hidden = YES;
    self.settingsSubview.hidden = YES;
    
    self.shareText.userInteractionEnabled = NO;
    self.aboutText.userInteractionEnabled = NO;
    self.settingsText.userInteractionEnabled = NO;
}

- (void)reenableMenu
{
    self.shareText.userInteractionEnabled = YES;
    self.aboutText.userInteractionEnabled = YES;
    self.settingsText.userInteractionEnabled = YES;
    
    self.shareSubview.hidden = YES;
    self.aboutSubview.hidden = YES;
    self.settingsSubview.hidden = YES;
}

- (IBAction)handleKeyboardToggle:(id)sender {
    UISwitch *switchControl = (UISwitch *)sender;
    BOOL isOn = switchControl.isOn;
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:USE_STANDARD_SYSTEM_KEYBOARD];
    [[NSUserDefaults standardUserDefaults] synchronize];
     
    NSLog(@"standard keyboard turned %s",isOn ? "on":"off");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"keyboardSettingChanged" object:nil userInfo:nil];
}

- (IBAction)handleStatusBarToggle:(id)sender {
    UIButton *btn = (UIButton *)sender;

    BOOL show = btn.tag == 1 ? NO : YES;
    [self setButtonOn:btn on:show];
    [[UIApplication sharedApplication] setStatusBarHidden:!show withAnimation:YES];
    
    [[NSUserDefaults standardUserDefaults] setBool:!show forKey:HIDE_STATUS_BAR];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setColorsToCollapsedStateWithDuration:0.5];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"didToggleStatusBar" object:nil userInfo:nil];
}

- (IBAction)toggleCloudStorage:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    
    BOOL useICloud = btn.tag == 1 ? NO : YES;
    [self setButtonOn:btn on:useICloud];
    
    [FileStorageState setPreferredStorage:useICloud ? kTKiCloud : kTKlocal];
    
    [[ApplicationModel sharedInstance] refreshNotes];
}

- (IBAction)sendEmail:(id)sender {
    if ([delegate respondsToSelector:@selector(sendEmail)]) {
        [delegate sendEmail];
    }
}

- (IBAction)sendSMS:(id)sender {
    if ([delegate respondsToSelector:@selector(sendSMS)]) {
        [delegate sendSMS];
    }
}

- (IBAction)sendTweet:(id)sender {
    if ([delegate respondsToSelector:@selector(sendTweet)]) {
        [delegate sendTweet];
    }
}

- (IBAction)visitSite:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://tackmobile.com"]; 
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)followTack:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://twitter.com/tackmobile"]; 
    [[UIApplication sharedApplication] openURL:url];
}

-(IBAction)changeColor:(UITapGestureRecognizer*)tap {
    
    UIColor *noteColor = [[UIColor getNoteColorSchemes] objectAtIndex:[[UIColor getOptionsColorSchemes] indexOfObject:tap.view.backgroundColor]];
    // if it's dark grey, use white text
    if ([[UIColor getOptionsColorSchemes] indexOfObject:tap.view.backgroundColor] >= 4) {
        [self.delegate setNoteColor:noteColor textColor:[UIColor whiteColor]];
    }else {
        [self.delegate setNoteColor:noteColor textColor:nil];
    }    
}

- (void)viewDidUnload
{
    [self setWhite:nil];
    [self setSky:nil];
    [self setLime:nil];
    [self setKernal:nil];
    [self setShadow:nil];
    [self setTack:nil];
    [self setScrollView:nil];
    
    [super viewDidUnload];
}

@end