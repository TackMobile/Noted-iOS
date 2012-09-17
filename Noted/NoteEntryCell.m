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
    /*
     UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRightInCell:)];
     [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
     [self addGestureRecognizer:swipeRight];
     */
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanRightInCell:)];
    [self addGestureRecognizer:panGesture];
    
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
- (void)didPanRightInCell:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer translationInView:self.contentView];
    CGPoint velocity = [recognizer velocityInView:self.contentView];
    CGRect viewFrame = self.contentView.frame;
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        point = [recognizer translationInView:self.contentView];
        CGRect newFrame;
        newFrame = CGRectMake(0 + point.x, 0, viewFrame.size.width, viewFrame.size.height);
        self.contentView.frame = newFrame;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (point.x > CGRectGetMidX(self.bounds) && velocity.x > 200.0) {
            [delegate didSwipeToDeleteCellWithIndexPath:self];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.contentView setFrame:CGRectMake(viewFrame.size.width, 0.0, viewFrame.size.width, viewFrame.size.height)];
                             }
                             completion:^(BOOL finished){
                                 
                             }];
            
            
        } else {
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.contentView setFrame:CGRectMake(0.0, 0.0, viewFrame.size.width, viewFrame.size.height)];
                             }
                             completion:^(BOOL finished){

                             }];
        }
    }
    
    
    

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
