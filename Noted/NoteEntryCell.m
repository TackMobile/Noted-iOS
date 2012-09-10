//
//  NoteEntryCell.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteEntryCell.h"

@implementation NoteEntryCell

@synthesize titleTextField;
@synthesize subtitleLabel;
@synthesize warningImageView;
@synthesize relativeTimeText;
@synthesize absoluteTimeText;
@synthesize deleteButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

    }
    return self;
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
