//
//  NoteCollectionViewCell.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDTheme.h"
#import "NTDCrossDetectorView.h"

@interface NoteCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *relativeTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) NTDCrossDetectorView *crossDetectorView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

- (void)applyTheme:(NTDTheme *)theme;

@end
