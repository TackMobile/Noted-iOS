//
//  OptionsViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "OptionsViewController.h"
#import <QuartzCore/QuartzCore.h>

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
    self.noteColorSchemes= [[NSMutableArray alloc] initWithObjects:[self colorWithHexString:@"FFFFFF"], [self colorWithHexString:@"E9F2F6"],[self colorWithHexString:@"F3F6E9"],[self colorWithHexString:@"FBF6EA"], [self colorWithHexString:@"333333"], [self colorWithHexString:@"1A9FEB"], nil];
    self.optionColorSchemes = [[NSMutableArray alloc] initWithObjects:[self colorWithHexString:@"FFFFFF"], [self colorWithHexString:@"C4D5DD"],[self colorWithHexString:@"C1D184"],[self colorWithHexString:@"DAC361"],[self colorWithHexString:@"333333"], [self colorWithHexString:@"1A9FEB"], nil];
    
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
    self.white.backgroundColor = [self colorWithHexString:@"FFFFFF"];
    self.sky.backgroundColor = [self colorWithHexString:@"C4D5DD"];
    self.lime.backgroundColor = [self colorWithHexString:@"C1D184"];
    self.kernal.backgroundColor = [self colorWithHexString:@"DAC361"];
    self.shadow.backgroundColor = [self colorWithHexString:@"333333"];
    self.tack.backgroundColor = [self colorWithHexString:@"1A9FEB"];
    
    self.shareText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.settingsText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.aboutText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.versionText.textColor  = [self colorWithHexString:@"CCCCCC"];
    self.optionsSubview.backgroundColor = [self colorWithHexString:@"292929"];
    self.shareSubview.backgroundColor = [self colorWithHexString:@"292929"];
    self.aboutSubview.backgroundColor = [self colorWithHexString:@"292929"];
    self.emailText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.messageText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.tweetText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.builtText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.websiteText.textColor = [self colorWithHexString:@"CCCCCC"];
    self.tackTwitterText.textColor = [self colorWithHexString:@"CCCCCC"];
    
    self.cancelX.textColor = [self colorWithHexString:@"CCCCCC"];
    
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

-(UIColor *) colorWithHexString: (NSString *) hex  
{  
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];  
    
    // String should be 6 or 8 characters  
    if ([cString length] < 6) return [UIColor grayColor];  
    
    // strip 0X if it appears  
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];  
    
    if ([cString length] != 6) return  [UIColor grayColor];  
    
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2;  
    NSString *rString = [cString substringWithRange:range];  
    
    range.location = 2;  
    NSString *gString = [cString substringWithRange:range];  
    
    range.location = 4;  
    NSString *bString = [cString substringWithRange:range];  
    
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  
    
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
} 


-(void)returnToOptions {
    [self.cancelX removeFromSuperview];
    [self.delegate returnToOptions];
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
    [self.delegate openShare];
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
    [self.delegate openAbout];
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
    [self.delegate sendEmail];
}

- (IBAction)sendSMS:(id)sender {
    [self.delegate sendSMS];
}

- (IBAction)sendTweet:(id)sender {
    [self.delegate sendTweet];
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end