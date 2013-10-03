//
//  NTDOptionsViewController.h
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDTheme.h"
#import "NTDNote.h"

FOUNDATION_EXPORT NSString *const NTDDidToggleStatusBarNotification;

@interface NTDColorPicker : UIView
@end

@protocol NTDOptionsViewDelegate <NSObject>
@required
- (void)changeOptionsViewWidth:(CGFloat)width;
- (CGFloat)initialOptionsViewWidth;
- (void)didChangeNoteTheme;
- (void)dismissOptions;
@end

@interface NTDOptionsViewController : UIViewController
@property (strong, nonatomic) UIViewController<NTDOptionsViewDelegate> *delegate;
@property (strong, nonatomic) NTDNote *note;
@property (strong, nonatomic) NSString *selectedText;
- (void) reset;
@end
