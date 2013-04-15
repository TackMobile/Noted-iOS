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

NSUInteger kCornerRadius = 6.0;

@interface NoteCollectionViewCell ()
@end

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
    
    [self applyCornerImages];
}

- (void)applyCornerImages
{
    UIImage *cornerImg = [UIImage imageNamed:@"corner"];
    CGSize size = cornerImg.size;

    UIImageView *topLeftImageView, *topRightImageView, *bottomLeftImageView, *bottomRightImageView;
    topLeftImageView = [[UIImageView alloc] initWithImage:cornerImg];
    topRightImageView = [[UIImageView alloc] initWithImage:cornerImg];
    bottomLeftImageView = [[UIImageView alloc] initWithImage:cornerImg];
    bottomRightImageView = [[UIImageView alloc] initWithImage:cornerImg];
    
    topRightImageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    bottomLeftImageView.transform = CGAffineTransformMakeScale(1.0, -1.0);
    bottomRightImageView.transform = CGAffineTransformMakeScale(-1.0, -1.0);
    
    topLeftImageView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    topRightImageView.frame = CGRectMake(self.bounds.size.width-size.width, 0.0, size.width, size.height);
    bottomLeftImageView.frame = CGRectMake(0.0, self.bounds.size.height - size.height, size.width, size.height);
    bottomRightImageView.frame = CGRectMake(self.bounds.size.width-size.width, self.bounds.size.height - size.height, size.width, size.height);
    
    [self.contentView addSubview:topLeftImageView];
    [self.contentView addSubview:topRightImageView];
    [self.contentView addSubview:bottomLeftImageView];
    [self.contentView addSubview:bottomRightImageView];
}

- (void)applyCornerMask
{
    return; // This code isn't really doing what I want it to yet.
    
    CGRect frame = self.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame
                                                   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(kCornerRadius, kCornerRadius)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    [maskLayer setFrame:CGRectOffset(self.bounds, 0, self.shadowImageView.frame.origin.y)];
    [maskLayer setPath:maskPath.CGPath];
    
    self.layer.mask = maskLayer;
}

- (void)removeCornerMask
{
    self.layer.mask = nil;
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
