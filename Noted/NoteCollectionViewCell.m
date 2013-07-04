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
#import "DAKeyboardControl.h"

@interface NoteCollectionViewCell ()
@end

@implementation NoteCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib
{    
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.fadeView];
    [self.contentView addSubview:self.relativeTimeLabel];
    [self.contentView addSubview:self.settingsButton];
    
    // apply the fade for the contentView
    if (!self.fadeView.layer.mask) {
        //[self.fadeView setBackgroundColor:[UIColor whiteColor]];
        
        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.colors = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor,
                            (id)[UIColor clearColor].CGColor, nil];
        
        maskLayer.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:.5],
                               [NSNumber numberWithFloat:1.0], nil];
        
        maskLayer.bounds = self.fadeView.bounds;
        maskLayer.anchorPoint = CGPointZero;
        
        self.fadeView.layer.mask = maskLayer;
    }
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    [self.textView removeKeyboardControl];
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
    
//    NSLog(@"applyLayoutAttributes (%d, %d) - frame: %@,", layoutAttributes.indexPath.item, layoutAttributes.zIndex, NSStringFromCGRect(layoutAttributes.frame));
}

- (void)willTransitionFromLayout:(UICollectionViewLayout *)oldLayout toLayout:(UICollectionViewLayout *)newLayout
{
    if ([newLayout isKindOfClass:[NoteListCollectionViewLayout class]]) {
        self.settingsButton.hidden = YES;
        self.crossDetectorView.hidden = YES;
        self.textView.editable = NO;
        self.textView.scrollEnabled = NO;
        [self applyShadow:NO];
    } else if ([newLayout isKindOfClass:[NTDPagingCollectionViewLayout class]]) {
        self.settingsButton.hidden = NO;
        self.crossDetectorView.hidden = NO;
        self.textView.editable = YES;
        self.textView.scrollEnabled = YES;
        [self applyShadow:YES];
    }
    
}

- (void)prepareForReuse
{
    self.textView.contentOffset = CGPointZero;
}

#pragma mark - Helpers


// apply a full shadow if we are paging. in list, we only need a small shadow. (performance+)
- (void)applyShadow:(bool)useFullShadow 
{
    CGRect shadowBounds = self.bounds;
    if (!useFullShadow)
        shadowBounds.size.height = 70; // list item is 44, but we want shadow for deleting too
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(-1.0,0);
    self.layer.shadowOpacity = .70;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
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
    self.contentView.backgroundColor = theme.backgroundColor;
    self.fadeView.backgroundColor = theme.backgroundColor;
    self.relativeTimeLabel.textColor = theme.subheaderColor;
    //self.textView.backgroundColor = theme.backgroundColor;
    self.textView.textColor = theme.textColor;
    [self.settingsButton setImage:theme.optionsButtonImage forState:UIControlStateNormal];
}
@end
