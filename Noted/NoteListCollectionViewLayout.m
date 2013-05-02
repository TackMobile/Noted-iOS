//
//  NoteListCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteListCollectionViewLayout.h"
#import "UIView+FrameAdditions.h"
#import "NoteCollectionViewLayoutAttributes.h"
#import <QuartzCore/QuartzCore.h>

@interface NoteListCollectionViewLayout ()
@property (nonatomic, strong) NSMutableArray *layoutAttributesArray;
@end

@implementation NoteListCollectionViewLayout

- (id)init
{
    if (self = [super init]) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        self.contentInset = UIEdgeInsetsZero;
        self.cardOffset = 65.0;
        self.cardSize = applicationFrame.size;
        self.pullToCreateShowCardOffset = -30.0;
        self.pullToCreateScrollCardOffset = -50.0;
        self.pullToCreateCreateCardOffset = -100.0;
    }
    return self;
}

+ (Class)layoutAttributesClass
{
    return [NoteCollectionViewLayoutAttributes class];
}

- (void)prepareLayout
{
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    self.layoutAttributesArray = [NSMutableArray arrayWithCapacity:cardCount];

    for (NSUInteger i = 0; i < cardCount; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        NoteCollectionViewLayoutAttributes *layoutAttributes = [NoteCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        CGFloat height = (i == 0) ? 0.0 : (i-1) * self.cardOffset + self.contentInset.top;
        CGRect frame = CGRectMake(self.contentInset.left,
                                  height,
                                  self.cardSize.width - self.contentInset.right,
                                  self.cardSize.height);
        layoutAttributes.frame = frame;
        layoutAttributes.zIndex = i;
        layoutAttributes.hidden = (i == 0);
        
        if (i == 0 || i == 1 || i == (cardCount-1)) {
            layoutAttributes.shouldApplyCornerMask = YES;
        }
        
        [self.layoutAttributesArray addObject:layoutAttributes];
    }
}

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.pinchedCardIndexPath)
        return [self pinchingLayoutAttributesForItemAtIndexPath:indexPath];
    
    NoteCollectionViewLayoutAttributes *layoutAttributes = self.layoutAttributesArray[indexPath.item];
    layoutAttributes.zIndex = layoutAttributes.indexPath.item;
    layoutAttributes.transform3D = CATransform3DMakeTranslation(0, 0, layoutAttributes.indexPath.item);
    CGRect frame = layoutAttributes.frame;
    
    if (self.selectedCardIndexPath) {
        if ([indexPath isEqual:self.selectedCardIndexPath]) {
            frame.origin.y = self.contentInset.top;
        } else {
            frame.origin.y += [[UIScreen mainScreen] bounds].size.height;
            layoutAttributes.alpha = 0.0;
        }
        layoutAttributes.frame = frame;
    } else if (self.shouldShowCreateableCard && indexPath.item == 0) {
        layoutAttributes.hidden = NO;
        CGFloat y = self.collectionView.contentOffset.y;
        if (y <= self.pullToCreateShowCardOffset && y > self.pullToCreateScrollCardOffset) {
            frame.origin.y = y + ABS(self.pullToCreateShowCardOffset);
        } else if (y <= self.pullToCreateScrollCardOffset && y > self.pullToCreateCreateCardOffset) {
            frame.origin.y =  ABS(self.pullToCreateShowCardOffset) + ABS(self.pullToCreateScrollCardOffset) + 2*y;
            frame.origin.y = MAX(frame.origin.y, y);
        } else if (y <= self.pullToCreateCreateCardOffset) {
            frame.origin.y = y;
        } else {
            layoutAttributes.hidden = YES;
        }
        layoutAttributes.frame = frame;
    } else if (self.swipedCardIndexPath && [indexPath isEqual:self.swipedCardIndexPath]) {
        static CGFloat MAX_OFFSET = 80.0, MIN_ALPHA = 0.4;
        CGFloat offset = MAX(-MAX_OFFSET, MIN(MAX_OFFSET, self.swipedCardOffset));
        CGFloat angle = (M_PI/6) * (offset/MAX_OFFSET);
        
        layoutAttributes.alpha = MAX(MIN_ALPHA, 1 + (MIN_ALPHA - 1.0) * ABS(offset)/MAX_OFFSET);
        layoutAttributes.transform2D = CGAffineTransformMakeRotation(angle);
        
        /* One would think that the code below would work, but I encountered a bug where the hidden
         * property of the CALayer backing the cell was set to YES. I figured this out using KVO, but
         * couldn't find a way around it (although admittedly, I was setting the cell's hidden property instead of the layer's). 
         * Instead, I added a CGAffineTransform property to a custom layout attributes subclass and am 
         * using that instead.
         */
//        CATransform3D transform = CATransform3DIdentity;
//        transform.m34 = 1.0 / 850.0; // feels like a hack, but all the cool kids do it.
//        transform = CATransform3DRotate(transform, angle, 0.0, 0.0, 1.0);
//        layoutAttributes.transform3D = transform;
    }
    
    return layoutAttributes;    
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    if (self.pinchedCardIndexPath)
        return [self pinchingLayoutAttributesForElementsInRect:rect];
    
    NSPredicate *inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        BOOL intersects = CGRectIntersectsRect(layoutAttributes.frame, rect);
        if (intersects) {
            layoutAttributes.zIndex = layoutAttributes.indexPath.item;
            layoutAttributes.transform3D = CATransform3DMakeTranslation(0, 0, layoutAttributes.indexPath.item);
        }
        return intersects;
    }];
    NSArray *attributesArray = [self.layoutAttributesArray filteredArrayUsingPredicate:inRectPredicate];
    if ([self shouldRecalcuateLayoutAttributes]) {
        NSMutableArray *attributesArrayMutable = [NSMutableArray arrayWithArray:attributesArray];
        for (int i = 0, n = [attributesArray count]; i < n; i++) {
            UICollectionViewLayoutAttributes *layoutAttributes = attributesArray[i];
            attributesArrayMutable[i] = [self layoutAttributesForItemAtIndexPath:layoutAttributes.indexPath];
        }
        return attributesArrayMutable;
    } else {
        return attributesArray;
    }
}

- (CGSize)collectionViewContentSize
{
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    if (cardCount == 0) {
        return self.cardSize;
    } else {
        CGFloat contentHeight = (cardCount - 1) * self.cardOffset;
        contentHeight += self.contentInset.top + self.contentInset.bottom;
        CGFloat contentWidth = self.cardSize.width;
        contentWidth += self.contentInset.left + self.contentInset.right;
        return CGSizeMake(contentWidth, contentHeight);
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
   return (newBounds.origin.y < self.pullToCreateShowCardOffset);
}

- (void)setSwipedCardOffset:(CGFloat)swipedCardOffset
{
    _swipedCardOffset = swipedCardOffset;
    [self invalidateLayout];
}

#pragma mark - Helpers
- (BOOL)shouldRecalcuateLayoutAttributes
{
    return self.selectedCardIndexPath || [self shouldShowCreateableCard] || self.swipedCardIndexPath;
}

- (BOOL)shouldShowCreateableCard
{
    return (self.collectionView.contentOffset.y < self.pullToCreateShowCardOffset);
}

#pragma mark - Properties
- (void)setPinchedCardIndexPath:(NSIndexPath *)pinchedCardIndexPath
{
    _pinchedCardIndexPath = pinchedCardIndexPath;
    [self invalidateLayout];
}

- (void)setPinchRatio:(CGFloat)pinchRatio
{
    _pinchRatio = pinchRatio;
    [self invalidateLayout];
}

#pragma mark - Pinching
- (NSArray *)pinchingLayoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *pinchingLayoutAttributesArray = [NSMutableArray array];
    NSInteger cardCount = [self.layoutAttributesArray count], cardBuffer = 10, pinchedCardIndex = self.pinchedCardIndexPath.item;
    NSInteger minIndex = MAX(0, pinchedCardIndex - cardBuffer);
    NSInteger maxIndex = MIN(cardCount - 1, pinchedCardIndex + cardBuffer);
    for (NSInteger i = minIndex; i <= maxIndex; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *layoutAttributes = [self pinchingLayoutAttributesForItemAtIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
            [pinchingLayoutAttributesArray addObject:layoutAttributes];
        }
    }
    return pinchingLayoutAttributesArray;
}

- (UICollectionViewLayoutAttributes *)pinchingLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewLayoutAttributes *layoutAttributes = self.layoutAttributesArray[indexPath.item];
    NoteCollectionViewLayoutAttributes *pinchedCardLayoutAttributes = self.layoutAttributesArray[self.pinchedCardIndexPath.item];
    
    CGFloat pinchGap = MAX(0.0, self.pinchRatio * self.cardSize.height);
    CGFloat pinchOffset = MIN(0.0, self.pinchRatio * -pinchedCardLayoutAttributes.frame.origin.y);
    
//    NSLog(@"(%d) gap: %f, offset: %f", indexPath.item, pinchGap, pinchOffset);
    
    if (indexPath.item > self.pinchedCardIndexPath.item) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, 0.0, pinchGap);
    } else if (indexPath.item <= self.pinchedCardIndexPath.item) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, 0.0, pinchOffset);
    }
    return layoutAttributes;
}
@end
