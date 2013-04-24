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

@protocol NoteCollectionViewCellDelegate;
@interface NoteCollectionViewCell : UICollectionViewCell <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *relativeTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *shadowForNextCardImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shadowImageView;
@property (weak, nonatomic) NTDCrossDetectorView *crossDetectorView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet id<NoteCollectionViewCellDelegate> delegate;
@property (assign, nonatomic) BOOL scrollEnabled;

- (void)applyTheme:(NTDTheme *)theme;
@end

@protocol NoteCollectionViewCellDelegate <NSObject>
- (void)didTriggerPullToReturn:(NoteCollectionViewCell *)cell;
- (void)shouldEnableScrolling:(BOOL)shouldEnable forContainerViewOfCell:(NoteCollectionViewCell *)cell;
@end