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

@interface NoteCollectionViewCell () <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) UIView *pullToCreateContainerView;

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
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.contentView.frame];
    self.scrollView.contentSize = self.contentView.frame.size;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.delegate = self;
    
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    self.backgroundColor = nil;
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.relativeTimeLabel];
    [self.contentView addSubview:self.actionButton];
    [self.contentView addSubview:self.separatorView];
    [self.contentView addSubview:self.textView];
    [self setupPullToCreate];
    [self.contentView addSubview:self.pullToCreateContainerView];
    
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
        self.actionButton.hidden = YES ;
        self.crossDetectorView.hidden = NO;
        self.textView.editable = YES;
    }
}

- (void)prepareForReuse
{
    self.textView.contentOffset = CGPointZero;
}

- (void)setDelegate:(id<NoteCollectionViewCellDelegate>)delegate
{
    if (delegate == nil) {
        delegate = (id<NoteCollectionViewCellDelegate>)[NSNull null];
    }
    _delegate = delegate;
}

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

static CGFloat PullToCreateLabelXOffset = 20.0, PullToCreateLabelYOffset = 6.0;
- (void)setupPullToCreate
{
    self.pullToCreateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pullToCreateLabel.text = @"Pull to return to cards.";
    self.pullToCreateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    self.pullToCreateLabel.backgroundColor = [UIColor blackColor];
    self.pullToCreateLabel.textColor = [UIColor whiteColor];
    [self.pullToCreateLabel sizeToFit];
    
    CGRect containerViewFrame = CGRectMake(0.0,
                                           -(self.pullToCreateLabel.$height + PullToCreateLabelYOffset),
                                           self.bounds.size.width,
                                           self.pullToCreateLabel.$height + PullToCreateLabelYOffset);
    self.pullToCreateContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    self.pullToCreateContainerView.layer.zPosition = -10000;
    
    self.pullToCreateLabel.$x = PullToCreateLabelXOffset;
    self.pullToCreateLabel.$y = PullToCreateLabelYOffset;
    [self.pullToCreateContainerView addSubview:self.pullToCreateLabel];
}

-(void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    self.scrollView.scrollEnabled = self.textView.scrollEnabled = scrollEnabled;
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.scrollView)
        return;
    
    CGFloat y = scrollView.bounds.origin.y;
    if (y < -self.pullToCreateContainerView.$height) {
        self.pullToCreateContainerView.$y = y;
    } else {
        self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView != self.scrollView)
        return;

    [self.delegate shouldEnableScrolling:NO forContainerViewOfCell:self];
}

static BOOL shouldReturnToListLayout = NO;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView != self.scrollView)
        return;
    
    shouldReturnToListLayout = (scrollView.contentOffset.y <= -100);
    if (shouldReturnToListLayout && !decelerate) {
        [self.delegate didTriggerPullToReturn:self];
        shouldReturnToListLayout = NO;
    }
    
    if (!decelerate) {
        [self.delegate shouldEnableScrolling:YES forContainerViewOfCell:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView != self.scrollView)
        return;
    
    if (shouldReturnToListLayout) {
        [self.delegate didTriggerPullToReturn:self];
        shouldReturnToListLayout = NO;
    }
    [self.delegate shouldEnableScrolling:YES forContainerViewOfCell:self];
}
@end
