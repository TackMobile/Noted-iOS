//
//  NTDOptionsViewController.h
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDTheme.h"
#import "NoteCollectionViewCell.h"
#import <MessageUI/MessageUI.h>

FOUNDATION_EXPORT NSString *const NTDDidToggleStatusBarNotification;

@interface NTDColorPicker : UIView

@end

@protocol NTDOptionsViewDelegate <NSObject>

@required

-(void)changeOptionsViewWidth:(CGFloat)width;
-(CGFloat)initialOptionsViewWidth;

@end

@interface NTDOptionsViewController : UIViewController <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (strong, nonatomic) id<NTDOptionsViewDelegate> delegate;
@property (strong, nonatomic) NoteCollectionViewCell *visibleCell;

// colors
@property (weak, nonatomic) IBOutlet NTDColorPicker *colors;

// options
@property (weak, nonatomic) IBOutlet UIView *options;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleStatusBarButton;

@property (weak, nonatomic) IBOutlet UIView *shareOptionsView;
@property (weak, nonatomic) IBOutlet UIView *settingsOptionsView;
@property (weak, nonatomic) IBOutlet UIView *aboutOptionsView;

- (void) reset;

@end
