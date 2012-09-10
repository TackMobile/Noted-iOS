//
//  NoteEntryCell.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoteEntryCellDelegate;

@interface NoteEntryCell : UITableViewCell

@property (weak,nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *warningImageView;
@property (weak, nonatomic) IBOutlet UITextView *relativeTimeText;
@property (weak, nonatomic) IBOutlet UITextView *absoluteTimeText;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) id <NoteEntryCellDelegate> delegate;

@end

@protocol NoteEntryCellDelegate <NSObject>

- (void)didSwipeToDeleteCellWithIndexPath:(NoteEntryCell *)cell;

@end
