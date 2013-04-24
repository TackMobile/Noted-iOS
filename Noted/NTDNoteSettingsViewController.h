//
//  NTDNoteSettingsViewController.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const NTDDidChangeStatusBarHiddenPropertyNotification;

@class NTDTheme;
@protocol NTDNoteSettingsViewControllerDelegate;

@interface NTDNoteSettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *themeContainerView;
@property (weak, nonatomic) IBOutlet UIButton *saveToCloudButton;
@property (weak, nonatomic) IBOutlet UIButton *showStatusBarButton;
@property (weak, nonatomic) id<NTDNoteSettingsViewControllerDelegate> delegate;

- (IBAction)selectTheme:(UITapGestureRecognizer *)sender;
- (IBAction)toggleSetting:(UIButton *)sender;
@end

@protocol NTDNoteSettingsViewControllerDelegate <NSObject>
-(void)changeNoteTheme:(NTDTheme *)newTheme;
-(void)dismiss:(NTDNoteSettingsViewController *)controller;
@end