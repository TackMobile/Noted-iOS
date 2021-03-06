//
//  NoteCollectionViewCell.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>
#import "NTDCollectionViewCell.h"
#import "NTDCollectionViewLayoutAttributes.h"
#import "NTDListCollectionViewLayout.h"
#import "NTDPagingCollectionViewLayout.h"
#import "DAKeyboardControl.h"

@interface NTDCollectionViewCell ()
@property (nonatomic, strong) CAGradientLayer *maskLayer;
@property (nonatomic) BOOL _doNotHideSettingsForNextLayoutChange;
@end

static NSDictionary *bodyFontSizes;

@implementation NTDCollectionViewCell

+(void)initialize
{
    /* The content size category constants obviously only exist on iOS >=7. */
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
        return;
    
    bodyFontSizes = @{
      UIContentSizeCategoryExtraSmall: @(14),
      UIContentSizeCategorySmall: @(15),
      UIContentSizeCategoryMedium: @(16),
      UIContentSizeCategoryLarge: @(17),
      UIContentSizeCategoryExtraLarge: @(18),
      UIContentSizeCategoryExtraExtraLarge: @(19),
      UIContentSizeCategoryExtraExtraExtraLarge: @(20),
      UIContentSizeCategoryAccessibilityMedium: @(24),
      UIContentSizeCategoryAccessibilityLarge: @(28),
      UIContentSizeCategoryAccessibilityExtraLarge: @(34),
      UIContentSizeCategoryAccessibilityExtraExtraLarge: @(40),
      UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @(46)
    };
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)awakeFromNib
{    
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.fadeView];
    [self.contentView addSubview:self.relativeTimeLabel];
    [self.contentView addSubview:self.settingsButton];
    
    [self applyMaskWithScrolledOffset:0];    
    self.settingsButton.alpha = 0;
    self._doNotHideSettingsForNextLayoutChange = NO;
    self.textView.scrollsToTop = NO;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.textView.$x += 3;
        self.fadeView.$width += 3;
        [self adjustTextViewForContentSize:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(adjustTextViewForContentSize:)
                                                   name:UIContentSizeCategoryDidChangeNotification
                                                 object:nil];
    }
}

- (void)applyMaskWithScrolledOffset:(CGFloat)scrolledOffset {
    CGFloat clearLocation = .5 + CLAMP(scrolledOffset/24, 0, .5);
    NSArray *maskLocationsArray = @[@0.5f, @(clearLocation)];
    
    if (!self.maskLayer) {
        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.colors = @[ (id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor];
        
        maskLayer.locations = maskLocationsArray;
        
        maskLayer.bounds = self.fadeView.bounds;
        maskLayer.anchorPoint = CGPointZero;
        
        self.maskLayer = maskLayer;
        
        self.fadeView.layer.mask = self.maskLayer;
    } else {
        self.maskLayer.locations = maskLocationsArray;
    }
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    [self.textView removeKeyboardControl];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if (![layoutAttributes isKindOfClass:[NTDCollectionViewLayoutAttributes class]])
          return;
          
    NTDCollectionViewLayoutAttributes *noteLayoutAttributes = (NTDCollectionViewLayoutAttributes *)layoutAttributes;
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
    if ([newLayout isKindOfClass:[NTDListCollectionViewLayout class]]) {
        self.textView.editable = NO;
        self.textView.userInteractionEnabled = NO;
        [self applyShadow:NO];
        if (!self._doNotHideSettingsForNextLayoutChange) self.settingsButton.alpha = 0;
        self.fadeView.hidden = YES;
        self.maskLayer = nil;
    } else if ([newLayout isKindOfClass:[NTDPagingCollectionViewLayout class]]) {
        self.textView.userInteractionEnabled = YES;
        self.textView.editable = YES;
        self.textView.scrollEnabled = YES;
        [self applyShadow:YES];
        self.settingsButton.alpha = 1;
        self.fadeView.hidden = NO;
    }
    self._doNotHideSettingsForNextLayoutChange = NO;
}

- (void)prepareForReuse
{
//    self.textView.contentOffset = CGPointZero;
    [self applyMaskWithScrolledOffset:0];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
//        NSLog(@"removing motion effects for reused cell: %p", self);
        for (UIMotionEffect *effect in self.motionEffects) [self removeMotionEffect:effect];
    }
}

- (void)doNotHideSettingsForNextLayoutChange {
    self._doNotHideSettingsForNextLayoutChange = YES;
}

#pragma mark - Helpers

// apply a full shadow if we are paging. in list, we only need a small shadow. (performance+)
- (void)applyShadow:(bool)useFullShadow 
{
    CGRect shadowBounds = self.bounds;
    if (!useFullShadow)
        shadowBounds.size.height = 70; // list item is 44, but we want shadow for deleting too
    
    shadowBounds = CGRectInset(shadowBounds, -2, -2);
    
    [self.contentView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:shadowBounds] CGPath]];
    self.contentView.layer.shadowRadius = 1.5f;
    self.contentView.layer.shadowOpacity = 0.35;
    self.contentView.layer.shadowOffset = CGSizeZero;
    
    self.contentView.layer.rasterizationScale = self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    [self setNeedsDisplay];
}

- (void)removeShadow
{
    self.layer.shadowPath = nil;
    [self setNeedsDisplay];
}

- (void)adjustTextViewForContentSize:(NSNotification *)notification
{
    NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
    CGFloat fontSize = [bodyFontSizes[contentSizeCategory] floatValue];
    self.textView.font = [UIFont fontWithName:@"Avenir-Light" size:fontSize];
    [self.textView setNeedsDisplay];
}

#pragma mark - Theming
- (void)applyTheme:(NTDTheme *)theme
{
    self.contentView.backgroundColor = theme.backgroundColor;
    self.fadeView.backgroundColor = theme.backgroundColor;
    self.relativeTimeLabel.textColor = theme.subheaderColor;
    self.textView.textColor = theme.textColor;
    [self.settingsButton setImage:theme.optionsButtonImage forState:UIControlStateNormal];
    self.textView.indicatorStyle = ([theme isDarkColorScheme]) ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleBlack;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.textView.tintColor = theme.caretColor;
    }
}
@end
