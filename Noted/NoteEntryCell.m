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
 
 
 }
 */



@end
