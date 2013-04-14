//
//  NoteCollectionViewCell.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewCell.h"
#import "NoteCollectionViewLayoutAttributes.h"
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

- (void)applyLayoutAttributes:(NoteCollectionViewLayoutAttributes *)layoutAttributes
{
//    if (!CATransform3DIsIdentity(layoutAttributes.transform3D)) {
//        self.layer.anchorPoint = CGPointMake(0.5, 0.75);
//        self.layer.transform = layoutAttributes.transform3D;
//        self.layer.zPosition = MAXFLOAT;
//    } else {
//        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
//    }
    
    if (!CGAffineTransformIsIdentity(layoutAttributes.transform2D)) {
        self.layer.affineTransform = layoutAttributes.transform2D;
    }
}
@end
