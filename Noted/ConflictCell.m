//
//  ConflictCell.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "ConflictCell.h"

@implementation ConflictCell
@synthesize titleLabel;
@synthesize subtitleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
