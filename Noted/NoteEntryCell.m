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

@implementation NoteEntryCell

@synthesize titleTextField;
@synthesize subtitleLabel;
@synthesize warningImageView;
@synthesize relativeTimeText;
@synthesize absoluteTimeText;
@synthesize deleteButton;
@synthesize delegate;

- (void)awakeFromNib
{
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRightInCell:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self addGestureRecognizer:swipeRight];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.absoluteTimeText.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self setTimeLabelsForNew];
}

- (void)setTimeLabelsForNew
{
    // immediately set time fields
    NSDate *now = [NSDate date];
    self.relativeTimeText.text = [Utilities formatRelativeDate:now];
    self.absoluteTimeText.text = [Utilities formatDate:now];
    
}
- (void)didSwipeRightInCell:(id)sender
{
    [delegate didSwipeToDeleteCellWithIndexPath:self];
    
    /*
     [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
     [UIView animateWithDuration:0.5
     animations:^{
     NSLog(@"%@ [%d]",NSStringFromCGRect(self.contentView.frame),__LINE__);
     [self.contentView setFrame:CGRectMake(320.0, 0.0, 320.0, 66.0)];
     }
     completion:^(BOOL finished){
     NSLog(@"finished animating, now delete for reals");
     }];
     */
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [UIView animateWithDuration:0.1 animations:^{
        if(editing){
            titleTextField.enabled = YES;
            titleTextField.borderStyle = UITextBorderStyleRoundedRect;
        }else{
            titleTextField.enabled = NO;
            titleTextField.borderStyle = UITextBorderStyleNone;
        }
    }];
    
}



@end
