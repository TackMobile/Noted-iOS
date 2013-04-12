//
//  NoteCollectionViewCell.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation NoteCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.relativeTimeLabel];
    [self.contentView addSubview:self.actionButton];
    [self.contentView addSubview:self.separatorView];
    [self.contentView addSubview:self.textView];
}

- (IBAction)viewSwiped:(id)sender {
}

- (IBAction)actionButtonPressed:(id)sender {
}
@end
