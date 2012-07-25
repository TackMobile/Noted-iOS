//
//  OptionsViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "OptionsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+HexColor.h"

@interface OptionsViewController ()

@end

@implementation OptionsViewController
@synthesize scrollView;

@synthesize colorSubView,white,sky,lime,kernal,shadow,tack,optionsSubview,shareText,settingsText,aboutText,versionText,cancelX,shareSubview,emailText,messageText,tweetText,aboutSubview,builtText,websiteText,tackTwitterText,noteColorSchemes,optionColorSchemes;
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadOptionColors];
    [self addAllGestures];
    
    self.shareSubview.frame = CGRectMake(0, 74, 320, 163);
    self.aboutSubview.frame = CGRectMake(0, 74, 320, 163);
    self.shareSubview.hidden = YES;
    self.aboutSubview.hidden = YES;
    [self.view addSubview:self.shareSubview];
    [self.view addSubview:self.aboutSubview];
    
    //colorSchemes: white,lime,sky,kernal,shadow,tack
    self.noteColorSchemes= [[NSMutableArray alloc] initWithObjects:[UIColor colorWithHexString:@"FFFFFF"], [UIColor colorWithHexString:@"E9F2F6"],[UIColor colorWithHexString:@"F3F6E9"],[UIColor colorWithHexString:@"FBF6EA"], [UIColor colorWithHexString:@"333333"], [UIColor colorWithHexString:@"1A9FEB"], nil];
    self.optionColorSchemes = [[NSMutableArray alloc] initWithObjects:[UIColor colorWithHexString:@"FFFFFF"], [UIColor colorWithHexString:@"C4D5DD"],[UIColor colorWithHexString:@"C1D184"],[UIColor colorWithHexString:@"DAC361"],[UIColor colorWithHexString:@"333333"], [UIColor colorWithHexString:@"1A9FEB"], nil];
    
    //add version number 
    self.versionText.text = [NSString stringWithFormat:@"v.%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    self.scrollView.scrollEnabled = YES;
    self.scrollView.bounces = YES;
    
    //make the corners
    self.scrollView.layer.bounds = CGRectMake(0, 0, 320, 480);
    self.scrollView.layer.cornerRadius = 6.5;
    self.scrollView.layer.masksToBounds = YES;
    
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
    [self.cancelX removeFromSuperview];
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0)];
    self.shareSubview.hidden = YES;
    self.aboutSubview.hidden = YES;
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
                         self.shareText.frame = CGRectMake(0, 0, 320, 53);
                         self.settingsText.frame = CGRectMake(0, 54, 320, 53);
                         self.aboutText.frame = CGRectMake(0, 108, 320, 53);
                         self.versionText.frame = CGRectMake(0, 162, 320, 53);
                     } completion:^(BOOL success){
                         self.shareSubview.hidden = YES;
                         self.aboutSubview.hidden = YES;
                     }];
}


-(void)openShare:(id)sender {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(120, 0)];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.white.frame = CGRectMake(0, 0, 320, 1);
                         self.sky.frame = CGRectMake(0, 2, 320, 1);
                         self.lime.frame = CGRectMake(0, 4, 320, 1);
                         self.kernal.frame = CGRectMake(0, 6, 320, 1);
                         self.shadow.frame = CGRectMake(0, 8, 320, 1);
                         self.tack.frame = CGRectMake(0, 10, 320, 1);
                         self.shareText.frame = CGRectMake(0, -244, 320, 480);
                         self.settingsText.frame = CGRectMake(0, 216, 320, 53);
                         self.aboutText.frame = CGRectMake(0, 269, 320, 53);
                         self.versionText.frame = CGRectMake(0, 322, 320, 53);
                     } completion:^(BOOL success){
                         self.cancelX.frame = CGRectMake(80, 20, 36, 36);
                         [self.view addSubview:self.cancelX];
                         self.shareSubview.hidden = NO;
                         self.aboutSubview.hidden = YES;
                     }];
    
}

-(void)openAbout:(id)sender {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(200, 0)];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.white.frame = CGRectMake(0, 0, 320, 1);
                         self.sky.frame = CGRectMake(0, 2, 320, 1);
                         self.lime.frame = CGRectMake(0, 4, 320, 1);
                         self.kernal.frame = CGRectMake(0, 6, 320, 1);
                         self.shadow.frame = CGRectMake(0, 8, 320, 1);
                         self.tack.frame = CGRectMake(0, 10, 320, 1);
                         self.shareText.frame = CGRectMake(0, -244, 320, 1);
                         self.settingsText.frame = CGRectMake(0, -244, 320, 1);
                         self.aboutText.frame = CGRectMake(0, -244, 320, 480);
                         self.versionText.frame = CGRectMake(0, 322, 320, 53);
                     } completion:^(BOOL success){
                         self.cancelX.frame = CGRectMake(160, 20, 36, 36);
                         [self.view addSubview:self.cancelX];
                         self.shareSubview.hidden = YES;
                         self.aboutSubview.hidden = NO;
                     }];
}

-(void)openSettings:(id)sender {
    
}

- (IBAction)sendEmail:(id)sender {
//    [self.delegate sendEmail];
}

- (IBAction)sendSMS:(id)sender {
//    [self.delegate sendSMS];
}

- (IBAction)sendTweet:(id)sender {
//    [self.delegate sendTweet];
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
    
    UIColor *noteColor = [noteColorSchemes objectAtIndex:[optionColorSchemes indexOfObject:tap.view.backgroundColor]];
    if ([optionColorSchemes indexOfObject:tap.view.backgroundColor] >= 4) {
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