//
//  NoteEntryCell.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteEntry.h"

@protocol NoteEntryCellDelegate;

@interface NoteEntryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *relativeTimeText;

@property (nonatomic, strong) UIView *leftCornerView;
@property (nonatomic, strong) UIView *rightCornerView;

@property (nonatomic, weak) id <NoteEntryCellDelegate> delegate;

- (void)setTimeLabelsForNew;
- (void)setSubviewsBgColor:(UIColor *)color;
- (void)setCornerColorsWithPrevNoteEntry:(UIColor *)noteColor;
- (void)roundCorners;
- (CGRect)frameForText:(NSString *)text;

@end

@protocol NoteEntryCellDelegate <NSObject>

- (void)didDeleteCellWithIndexPath:(NoteEntryCell *)cell;

@end
