//
//  OptionsViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol OptionsViewDelegate <NSObject>
-(void)setNoteColor:(UIColor*)color textColor:(UIColor*)textColor;
-(void)openShare;
-(void)openAbout;
-(void)sendEmail;
-(void)sendTweet;
-(void)sendSMS;
-(void)returnToOptions;

@end

@interface OptionsViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIView *colorSubView;
@property (weak, nonatomic) IBOutlet UIView *white;
@property (weak, nonatomic) IBOutlet UIView *sky;
@property (weak, nonatomic) IBOutlet UIView *lime;
@property (weak, nonatomic) IBOutlet UIView *kernal;
@property (weak, nonatomic) IBOutlet UIView *shadow;
@property (weak, nonatomic) IBOutlet UIView *tack;
@property (weak, nonatomic) IBOutlet UIView *optionsSubview;
@property (weak, nonatomic) IBOutlet UITextView *shareText;
@property (weak, nonatomic) IBOutlet UITextView *settingsText;
@property (weak, nonatomic) IBOutlet UITextView *aboutText;
@property (weak, nonatomic) IBOutlet UITextView *versionText;
@property (strong, nonatomic) IBOutlet UITextView *cancelX;
@property (strong, nonatomic) IBOutlet UIView *shareSubview;
@property (weak, nonatomic) IBOutlet UITextView *emailText;
@property (weak, nonatomic) IBOutlet UITextView *messageText;
@property (weak, nonatomic) IBOutlet UITextView *tweetText;
@property (strong, nonatomic) IBOutlet UIView *aboutSubview;
@property (weak, nonatomic) IBOutlet UITextView *builtText;
@property (weak, nonatomic) IBOutlet UITextView *websiteText;
@property (weak, nonatomic) IBOutlet UITextView *tackTwitterText;
@property (strong) NSMutableArray *noteColorSchemes;
@property (strong) NSMutableArray *optionColorSchemes;
@property (nonatomic, retain) id delegate;


- (IBAction)openAbout:(id)sender;
- (IBAction)openShare:(id)sender;
- (IBAction)openSettings:(id)sender;
- (IBAction)sendEmail:(id)sender;
- (IBAction)sendSMS:(id)sender;
- (IBAction)sendTweet:(id)sender;
- (IBAction)visitSite:(id)sender;
- (IBAction)followTack:(id)sender;
-(void)returnToOptions;


@end