//
//  NTDNoteSettingsViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NTDNoteSettingsViewController.h"
#import "NTDTheme.h"
#import "FileStorageState.h"
#import "ApplicationModel.h"

NSString *const NTDDidChangeStatusBarHiddenPropertyNotification = @"NTDDidChangeStatusBarHiddenPropertyNotification";

@interface NTDNoteSettingsViewController ()

@end

@implementation NTDNoteSettingsViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self renderThemeBars];
    [self syncButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setThemeContainerView:nil];
    [self setSaveToCloudButton:nil];
    [self setShowStatusBarButton:nil];
    [super viewDidUnload];
}

#pragma mark - Helpers
static CGFloat themeBarWidth;
- (void)renderThemeBars
{
    CGSize containerSize = self.themeContainerView.bounds.size;
    themeBarWidth = containerSize.width / NTDNumberOfColorSchemes;
    CGFloat themeBarHeight = containerSize.height;
    for (int i = 0; i < NTDNumberOfColorSchemes; i++) {
        NTDTheme *theme = [NTDTheme themeForColorScheme:i];
        CGRect frame = CGRectMake(i*themeBarWidth, 0.0, themeBarWidth, themeBarHeight);
        UIView *themeView = [[UIView alloc] initWithFrame:frame];
        themeView.tag = i;
        themeView.backgroundColor = [theme backgroundColor];
        themeView.layer.borderWidth = 0.5;
        [self.themeContainerView addSubview:themeView];
    }
}

- (void)syncButtons
{
    NSString *title;
    
    BOOL savesToCloud = [FileStorageState preferredStorage] == kTKiCloud;
    title = (savesToCloud) ? @"OFF" : @"ON";
    [self.saveToCloudButton setTitle:title forState:UIControlStateNormal];
    
    BOOL showsStatusBar = ![[UIApplication sharedApplication] isStatusBarHidden];
    title = (showsStatusBar) ? @"ON" : @"OFF";
    [self.showStatusBarButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - Actions
- (IBAction)selectTheme:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self.themeContainerView];
    int i = floorf(location.x / themeBarWidth);
    NTDTheme *theme = [NTDTheme themeForColorScheme:i];
    [self.delegate changeNoteTheme:theme];
    [self.delegate dismiss:self];
}

- (IBAction)toggleSetting:(UIButton *)sender
{
    [self syncButtons];

    if (sender == self.saveToCloudButton) {
        BOOL shouldSaveToCloud = [sender.currentTitle isEqualToString:@"OFF"];
        [FileStorageState setPreferredStorage:shouldSaveToCloud ? kTKiCloud : kTKlocal];
        [[ApplicationModel sharedInstance] refreshNotes];
    } else if (sender == self.showStatusBarButton) {
        BOOL shouldShowStatusBar = [sender.currentTitle isEqualToString:@"OFF"];
        
        [[UIApplication sharedApplication] setStatusBarHidden:!shouldShowStatusBar withAnimation:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:!shouldShowStatusBar forKey:HIDE_STATUS_BAR];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NTDDidChangeStatusBarHiddenPropertyNotification object:nil];
    }
    
    [self.delegate dismiss:self];
}
@end
