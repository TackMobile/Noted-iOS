//
//  OptionsViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol OptionsViewDelegate <NSObject>

@optional

-(void)setNoteColor:(UIColor*)color textColor:(UIColor*)textColor;
-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point completion:(void(^)())completionBlock;
-(void)sendEmail;
-(void)sendTweet;
-(void)sendSMS;

@end

@interface OptionsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIScrollView *colorSubView;
@property (weak, nonatomic) IBOutlet UIView *white;
@property (weak, nonatomic) IBOutlet UIView *sky;
@property (weak, nonatomic) IBOutlet UIView *lime;
@property (weak, nonatomic) IBOutlet UIView *kernal;
@property (weak, nonatomic) IBOutlet UIView *shadow;
@property (weak, nonatomic) IBOutlet UIView *tack;
@property (weak, nonatomic) IBOutlet UIView *optionsSubview;
@property (weak, nonatomic) IBOutlet UIView *shareView;
@property (weak, nonatomic) IBOutlet UIView *settingsView;
@property (weak, nonatomic) IBOutlet UIView *aboutView;
@property (weak, nonatomic) IBOutlet UIView *versionView;
@property (weak, nonatomic) IBOutlet UILabel *versionText;
@property (strong, nonatomic) IBOutlet UITextView *cancelX;
@property (strong, nonatomic) IBOutlet UIView *shareSubview;

@property (strong, nonatomic) IBOutlet UIView *aboutSubview;
@property (strong, nonatomic) IBOutlet UIView *settingsSubview;

@property (weak, nonatomic) IBOutlet UITextView *builtText;
@property (nonatomic, retain) id delegate;

- (IBAction)handleKeyboardToggle:(id)sender;
- (IBAction)handleStatusBarToggle:(id)sender;
- (IBAction)toggleCloudStorage:(id)sender;

- (IBAction)sendEmail:(id)sender;
- (IBAction)sendSMS:(id)sender;
- (IBAction)sendTweet:(id)sender;
- (IBAction)visitSite:(id)sender;
- (IBAction)followTack:(id)sender;
- (void)returnToOptions;
- (void)reset;

@end