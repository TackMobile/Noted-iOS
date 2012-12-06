//
//  NoteEntryCell.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteEntryCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteEntry.h"
#import "Utilities.h"
#import "UIView+position.h"

@interface NoteEntryCell()
{
    UIImageView *_cornerLeft;
    UIImageView *_cornerRight;
    UIView *_bgView;
}

@end

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
    
    float width = 6.0;
    _leftCornerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, width)];
    _rightCornerView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width-width, 0.0, width, width)];
  
    _bgView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    
    [self.contentView insertSubview:_bgView atIndex:0];
    
    [self.contentView insertSubview:_leftCornerView belowSubview:_bgView];
    [self.contentView insertSubview:_rightCornerView belowSubview:_bgView];
    
    UIImage *cornerImg = [UIImage imageNamed:@"corner"];
    CGSize size = cornerImg.size;
    _cornerLeft = [[UIImageView alloc] initWithImage:cornerImg];
    _cornerRight = [[UIImageView alloc] initWithImage:cornerImg]; // CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
    _cornerRight.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _cornerLeft.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    _cornerRight.frame = CGRectMake(self.bounds.size.width-size.width, 0.0, size.width, size.height);
    [self.contentView addSubview:_cornerLeft];
    [self.contentView addSubview:_cornerRight];
    
    [self roundCornersForView:_bgView];
}

- (void)setSubviewsBgColor:(UIColor *)color {
    self.contentView.backgroundColor = color;
    [self setBackgroundColor:color];
    [_bgView setBackgroundColor:color];
}

- (void)roundCorners
{
    [self roundCornersForView:self];
}

- (void)roundCornersForView:(UIView *)view
{
    // round the top corners
    CGRect frame = self.bounds;
    frame.size.height = 66.0;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame
                                                   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(6.0, 6.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    [maskLayer setFrame:self.bounds];
    [maskLayer setPath:maskPath.CGPath];
    
    view.layer.mask = maskLayer;
}

- (void)setCornerColorsWithPrevNoteEntry:(UIColor *)noteColor
{
    [_leftCornerView setBackgroundColor:noteColor];
    [_rightCornerView setBackgroundColor:noteColor];
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
