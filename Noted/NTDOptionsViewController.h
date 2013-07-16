//
//  NTDOptionsViewController.h
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTDColorPicker : UIView

@end

@protocol NTDOptionsViewDelegate <NSObject>

@required

-(void)setNoteColor:(UIColor*)color textColor:(UIColor*)textColor;
-(void)sendEmail;
-(void)sendTweet;
-(void)sendSMS;
-(void)changeOptionsViewWidth:(CGFloat)width;

-(CGFloat)initialOptionsViewWidth;

@end

@interface NTDOptionsViewController : UIViewController

@property (strong, nonatomic) id<NTDOptionsViewDelegate> delegate;

// colors
@property (weak, nonatomic) IBOutlet NTDColorPicker *colorsSubview;

// options
@property (weak, nonatomic) IBOutlet UIView *optionsSubview;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleStatusBarButton;

@property (weak, nonatomic) IBOutlet UIView *shareOptionsView;
@property (weak, nonatomic) IBOutlet UIView *settingsOptionsView;
@property (weak, nonatomic) IBOutlet UIView *aboutOptionsView;

- (void) reset;

@end
