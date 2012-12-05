//
//  NoteEntryCell.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteEntryCell.h"
#import "NoteEntry.h"
#import "Utilities.h"
#import "UIView+position.h"

@implementation NoteEntryCell

@synthesize titleTextField;
@synthesize subtitleLabel;
@synthesize warningImageView;
@synthesize relativeTimeText;
@synthesize delegate;

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textLabel.backgroundColor = [UIColor clearColor];
    
    [self setTimeLabelsForNew];
    [self.deleteButton setBackgroundColor:[UIColor whiteColor]];
    [self.deleteButton debugViewWithColor:[UIColor lightGrayColor]];
}

- (void)setTimeLabelsForNew
{
    // immediately set time fields
    NSDate *now = [NSDate date];
    self.relativeTimeText.text = [Utilities formatRelativeDate:now];
    
}

/*
 - (IBAction)deleteTapped:(id)sender {
 [self.delegate didDeleteCellWithIndexPath:self];
 }
 */

/*
 - (void)setSelected:(BOOL)selected animated:(BOOL)animated
 {
 [super setSelected:selected animated:animated];
 
 // Configure the view for the selected state
 }
 */

/*
 - (void)setEditing:(BOOL)editing animated:(BOOL)animated
 {
 [super setEditing:editing animated:animated];
 
 float xLoc = editing ? CGRectGetMaxX(_deleteButton.frame)+8.0 : 8.0;
 
 [_deleteButton setHidden:editing ? NO : YES];
 [_deleteButton setAlpha:0.0];
 [self addSubview:_deleteButton];
 [self.relativeTimeText setAlpha:editing ? 0.0 : 1.0];
 
 [UIView animateWithDuration:0.1 animations:^{
 [self.subtitleLabel setFrameX:xLoc];
 [self.deleteButton setAlpha:editing ? 1.0 : 0.0];
 }];
 
 }
 */


@end
