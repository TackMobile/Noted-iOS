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
#import "UIView+FrameAdditions.h"

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
    [self.contentView addSubview:self.separatorView];
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.settingsButton];
    
    [self applyShadowFull:NO];
}

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
        //[self applyCornerMask];
        //[self applyShadow];
    } else {
        //[self removeCornerMask];
        //[self removeShadow];
    }
    
//    NSLog(@"applyLayoutAttributes (%d, %d) - frame: %@,", layoutAttributes.indexPath.item, layoutAttributes.zIndex, NSStringFromCGRect(layoutAttributes.frame));
}

- (void)willTransitionFromLayout:(UICollectionViewLayout *)oldLayout toLayout:(UICollectionViewLayout *)newLayout
{
    if ([newLayout isKindOfClass:[NoteListCollectionViewLayout class]]) {
        self.settingsButton.hidden = YES;
        self.crossDetectorView.hidden = YES;
        self.textView.editable = NO;
        [self applyShadowFull:NO];
    } else if ([newLayout isKindOfClass:[NTDPagingCollectionViewLayout class]]) {
        self.settingsButton.hidden = NO;
        self.crossDetectorView.hidden = NO;
        self.textView.editable = YES;
        [self applyShadowFull:YES];
    }
    
}

- (void)prepareForReuse
{
    self.textView.contentOffset = CGPointZero;
}

#pragma mark - Helpers

- (void)applyCornerMask
{    
    CGRect frame = self.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame
                                                   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(kCornerRadius, kCornerRadius)];
    [maskPath appendPath:[UIBezierPath bezierPathWithRect:self.shadowImageView.frame]];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    [maskLayer setPath:maskPath.CGPath];
    self.contentView.layer.shouldRasterize = NO;
    self.contentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.contentView.layer.mask = maskLayer;
}

- (void)removeCornerMask
{
    self.layer.mask = nil;
}

// apply a full shadow if we are paging. in list, we only need a small shadow. (performance+)
- (void)applyShadowFull:(bool)fullShadow
{
    CGRect shadowBounds = self.bounds;
    if (!fullShadow)
        shadowBounds.size.height = 70; // list item is 44, but we want shadow for deleting too
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(-1.0,0);
    self.layer.shadowOpacity = .70;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.layer.shouldRasterize = NO;
    [self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:shadowBounds] CGPath]];
    [self setNeedsDisplay];
}

- (void)removeShadow
{
    self.layer.shadowPath = nil;
    [self setNeedsDisplay];
}

#pragma mark - Theming
- (void)applyTheme:(NTDTheme *)theme
{
    self.contentView.layer.backgroundColor = theme.backgroundColor.CGColor;
    self.titleLabel.textColor = theme.headerColor;
    self.relativeTimeLabel.textColor = theme.subheaderColor;
    self.textView.backgroundColor = theme.backgroundColor;
    self.textView.textColor = theme.textColor;
    self.separatorView.backgroundColor = theme.textColor;
    [self.settingsButton setImage:theme.optionsButtonImage forState:UIControlStateNormal];
}
@end
