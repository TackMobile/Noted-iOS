//
//  NoteCollectionViewCell.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewCell.h"
#import "NoteCollectionViewLayoutAttributes.h"
#import "NoteListCollectionViewLayout.h"
#import "NTDPagingCollectionViewLayout.h"
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
    NTDCrossDetectorView *crossDetectorView = [[NTDCrossDetectorView alloc] initWithFrame:self.bounds];
    crossDetectorView.hidden = YES;
//    [self.contentView addSubview:crossDetectorView];
    self.crossDetectorView = crossDetectorView;
}

//-(void)layoutSubviews
//{
//    [super layoutSubviews];
//    [self applyCornerMask];
//}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if (![layoutAttributes isKindOfClass:[NoteCollectionViewLayoutAttributes class]])
          return;
          
    NoteCollectionViewLayoutAttributes *noteLayoutAttributes = (NoteCollectionViewLayoutAttributes *)layoutAttributes;
    if (!CGAffineTransformIsIdentity(noteLayoutAttributes.transform2D)) {
        if (!CATransform3DIsIdentity(noteLayoutAttributes.transform3D)) {
            CATransform3D transform3D = CATransform3DMakeAffineTransform(noteLayoutAttributes.transform2D);
            CATransform3D zTransform = CATransform3DMakeTranslation(0, 0, layoutAttributes.indexPath.item);
            self.layer.transform = CATransform3DConcat(zTransform, transform3D);
        } else {
            self.layer.affineTransform = noteLayoutAttributes.transform2D;
        }
    }
    
    if (noteLayoutAttributes.shouldApplyCornerMask) {
        [self applyCornerMask];
    } else {
        [self removeCornerMask];
    }
    
//    NSLog(@"applyLayoutAttributes (%d, %d) - frame: %@,", layoutAttributes.indexPath.item, layoutAttributes.zIndex, NSStringFromCGRect(layoutAttributes.frame));
}

- (void)willTransitionFromLayout:(UICollectionViewLayout *)oldLayout toLayout:(UICollectionViewLayout *)newLayout
{
    if ([newLayout isKindOfClass:[NoteListCollectionViewLayout class]]) {
        self.actionButton.hidden = YES;
        self.crossDetectorView.hidden = YES;
        self.textView.editable = NO;
    } else if ([newLayout isKindOfClass:[NTDPagingCollectionViewLayout class]]) {
        self.actionButton.hidden = NO;
        self.crossDetectorView.hidden = NO;
        self.textView.editable = YES;
    }
}

//- (void)prepareForReuse
//{
//    [self removeCornerMask];
//}

#pragma mark - Helpers
- (void)applyCornerImages
{
    UIImage *cornerImg = [UIImage imageNamed:@"corner"];
    CGSize size = cornerImg.size;
    
    UIImageView *topLeftImageView, *topRightImageView, *bottomLeftImageView, *bottomRightImageView;
    topLeftImageView = [[UIImageView alloc] initWithImage:cornerImg];
    topRightImageView = [[UIImageView alloc] initWithImage:cornerImg];
    bottomLeftImageView = [[UIImageView alloc] initWithImage:cornerImg];
    bottomRightImageView = [[UIImageView alloc] initWithImage:cornerImg];
    
    topLeftImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    topRightImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    bottomLeftImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin;
    bottomRightImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
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
    
    CGRect frame = self.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame
                                                   byRoundingCorners:UIRectCornerAllCorners
                                                         cornerRadii:CGSizeMake(kCornerRadius, kCornerRadius)];
    [maskPath appendPath:[UIBezierPath bezierPathWithRect:self.shadowImageView.frame]];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    [maskLayer setPath:maskPath.CGPath];
    
    self.layer.mask = maskLayer;
}

- (void)removeCornerMask
{
    self.layer.mask = nil;
}

#pragma mark - Theming
- (void)applyTheme:(NTDTheme *)theme
{
    self.contentView.backgroundColor = theme.backgroundColor;
    self.titleLabel.textColor = theme.headerColor;
    self.relativeTimeLabel.textColor = theme.subheaderColor;
    self.textView.backgroundColor = theme.backgroundColor;
    self.textView.textColor = theme.textColor;
    self.separatorView.backgroundColor = theme.textColor;
}
@end
