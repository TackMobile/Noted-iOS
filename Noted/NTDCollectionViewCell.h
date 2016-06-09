//
//  NoteCollectionViewCell.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDTheme.h"

@interface NTDCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *relativeTimeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (strong, nonatomic) NSDate *dateCreated;

- (void)applyTheme:(NTDTheme *)theme;
- (void)applyShadow:(bool)useFullShadow;

- (void)applyMaskWithScrolledOffset:(CGFloat)scrolledOffset;
- (void)doNotHideSettingsForNextLayoutChange;

@end
