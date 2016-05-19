//
//  NoteListCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>
#import "NTDListCollectionViewLayout.h"
#import "NTDCollectionViewLayoutAttributes.h"

NSString * const NTDCollectionElementKindPullToCreateCard = @"NTDCollectionElementKindPullToCreateCard";
static const CGFloat NTDMaxNoteTiltAngle = M_PI/4;
static const NSTimeInterval NTDDeleteAnimationDuration = 0.25f;

@interface NTDListCollectionViewLayout ()
@property (nonatomic, strong) NSMutableArray *layoutAttributesArray;
@property (nonatomic, strong) NSIndexPath *pullToCreateCardIndexPath;
@property (nonatomic, assign) CGFloat originalPinchRatio;
@end

@implementation NTDListCollectionViewLayout

- (id)init
{
    if (self = [super init]) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        self.contentInset = UIEdgeInsetsZero;
        self.cardOffset = 65.0;
        self.cardSize = applicationFrame.size;
        self.pullToCreateCreateCardOffset = -NTDPullToCreateScrollCardOffset * 2;
        self.pullToCreateCardIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        self.pullToCreateEnabled = YES;
    }
    return self;
}

+ (Class)layoutAttributesClass
{
    return [NTDCollectionViewLayoutAttributes class];
}

- (void)prepareLayout
{
    [self cacheCellLayoutAttributes];
}

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.pinchedCardIndexPath)
        return [self pinchingLayoutAttributesForItemAtIndexPath:indexPath];
    
    NTDCollectionViewLayoutAttributes *layoutAttributes = [self cellLayoutAttributesForItem:indexPath.item];
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
    } else if (self.swipedCardIndexPath && [indexPath isEqual:self.swipedCardIndexPath]) {
        CGFloat offset = self.swipedCardOffset;
        CGFloat angle = NTDMaxNoteTiltAngle * (offset/self.collectionView.frame.size.width/2);
        
        static CGFloat MIN_ALPHA = .3;
        
        layoutAttributes.alpha = fmaxf(MIN_ALPHA, (self.collectionView.frame.size.width/2 - ABS(offset))/(self.collectionView.frame.size.width/2));
        layoutAttributes.transform2D = CGAffineTransformMakeRotation(angle);
        layoutAttributes.center = CGPointMake(layoutAttributes.center.x + offset, layoutAttributes.center.y);
        
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

-(UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:NTDCollectionElementKindPullToCreateCard] && [indexPath isEqual:self.pullToCreateCardIndexPath]) {
        NTDCollectionViewLayoutAttributes *layoutAttributes;        
        layoutAttributes = [NTDCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
        
        CGRect frame = CGRectMake(self.contentInset.left,
                                  0.0,
                                  self.cardSize.width - self.contentInset.right,
                                  self.cardSize.height);
        layoutAttributes.frame = frame;
        layoutAttributes.zIndex = -1;
        layoutAttributes.transform3D = CATransform3DMakeTranslation(0, 0, layoutAttributes.indexPath.item);
        
        CGFloat y = self.collectionView.contentOffset.y;
        if (y > NTDPullToCreateShowCardOffset) {
            layoutAttributes.hidden = YES;
            NSLog(@"gone rogue");
        } else if (y <= -NTDPullToCreateShowCardOffset && y > -NTDPullToCreateScrollCardOffset) {
            frame.origin.y = y + NTDPullToCreateShowCardOffset;
        } else if (y <= -NTDPullToCreateScrollCardOffset && y > self.pullToCreateCreateCardOffset) {
            frame.origin.y =  NTDPullToCreateShowCardOffset + NTDPullToCreateScrollCardOffset + 2*y;
            frame.origin.y = MAX(frame.origin.y, y);
        } else if (y <= self.pullToCreateCreateCardOffset) {
            frame.origin.y = y;
        }
        layoutAttributes.frame = frame;

        if (layoutAttributes.hidden)  NSLog(@"pull card is hidden");
        return layoutAttributes;
    } else {
        return nil;
    }
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
    
    [self extendCacheIfNecessary];
    NSArray *attributesArray = [self.layoutAttributesArray filteredArrayUsingPredicate:inRectPredicate];
    
    NSMutableArray *attributesArrayMutable = [NSMutableArray arrayWithArray:attributesArray];
    if ([self shouldRecalcuateLayoutAttributes]) {
        for (NSInteger i = 0, n = [attributesArray count]; i < n; i++) {
            UICollectionViewLayoutAttributes *layoutAttributes = attributesArray[i];
            attributesArrayMutable[i] = [self layoutAttributesForItemAtIndexPath:layoutAttributes.indexPath];
        }
    }
    
    if ([self shouldShowCreateableCard]) {
        [attributesArrayMutable addObject:[self layoutAttributesForSupplementaryViewOfKind:NTDCollectionElementKindPullToCreateCard
                                                                               atIndexPath:self.pullToCreateCardIndexPath]];
    }
    return attributesArrayMutable;
}

- (CGSize)collectionViewContentSize
{
    CGSize size;
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    if (cardCount == 0) {
        size = self.cardSize;
    } else {
        CGFloat contentWidth = self.cardSize.width + self.contentInset.left + self.contentInset.right;

        CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
        CGFloat contentHeight = cardCount * self.cardOffset + self.contentInset.top + self.contentInset.bottom;
        contentHeight = MAX(contentHeight, screenHeight);
        
        size = CGSizeMake(contentWidth, contentHeight);
    }
    
    return size;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
   return (newBounds.origin.y < -NTDPullToCreateShowCardOffset);
}

- (void)setSwipedCardOffset:(CGFloat)swipedCardOffset
{
    _swipedCardOffset = swipedCardOffset;
    [self invalidateLayout];
}

#pragma mark - Caching
- (NTDCollectionViewLayoutAttributes *)generateCellLayoutAttributesForItem:(NSInteger)i
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
    NTDCollectionViewLayoutAttributes *layoutAttributes = [NTDCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGFloat height = i * self.cardOffset + self.contentInset.top;
    CGRect frame = CGRectMake(self.contentInset.left,
                              height,
                              self.cardSize.width - self.contentInset.right,
                              self.cardSize.height);
    layoutAttributes.frame = frame;
    layoutAttributes.zIndex = i;
    layoutAttributes.transform3D = CATransform3DMakeTranslation(0, 0, layoutAttributes.indexPath.item);
    layoutAttributes.hidden = NO;
    
    return layoutAttributes;
}

- (void)cacheCellLayoutAttributes
{
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    self.layoutAttributesArray = [NSMutableArray arrayWithCapacity:cardCount];
    
    for (NSUInteger i = 0; i < cardCount; i++) {
        NTDCollectionViewLayoutAttributes *layoutAttributes = [self generateCellLayoutAttributesForItem:i];
        [self.layoutAttributesArray addObject:layoutAttributes];
    }
}

- (NTDCollectionViewLayoutAttributes *)cellLayoutAttributesForItem:(NSInteger)i
{
    if (i >= 0 && i < [self.layoutAttributesArray count]) {
        return self.layoutAttributesArray[i];
    } else {
        return [self generateCellLayoutAttributesForItem:i];
    }
}

- (void)extendCacheIfNecessary
{
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    NSUInteger arrayCount = [self.layoutAttributesArray count];
    if (arrayCount < cardCount) {
//        for (int i = arrayCount; i < cardCount; i++) {
//            [self.layoutAttributesArray addObject:[self cellLayoutAttributesForItem:i]];
//        }
        [self cacheCellLayoutAttributes];
    }
}

#pragma mark - Helpers
- (BOOL)shouldRecalcuateLayoutAttributes
{
    return self.selectedCardIndexPath || [self shouldShowCreateableCard] || self.swipedCardIndexPath;
}

- (BOOL)shouldShowCreateableCard
{
    return (self.collectionView.contentOffset.y < -NTDPullToCreateShowCardOffset) &&
            self.pullToCreateEnabled;
}

#pragma mark - Properties
- (void)setPinchedCardIndexPath:(NSIndexPath *)pinchedCardIndexPath
{
    _pinchedCardIndexPath = pinchedCardIndexPath;
    if (pinchedCardIndexPath) {
        [self invalidateLayout];
    } else {
        void (^animationBlock)() = ^{
            NSInteger minIndexPath = NSIntegerMax, maxIndexPath = NSIntegerMin, count = 0;
            for (UIView *view in self.collectionView.subviews) {
                if (![view isKindOfClass:[UICollectionViewCell class]]) continue;
                UICollectionViewCell *cell = (UICollectionViewCell *)view;
                NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                if (!indexPath) continue;
                UICollectionViewLayoutAttributes *attributes = [self generateCellLayoutAttributesForItem:indexPath.item];
                cell.center = attributes.center;
                minIndexPath = MIN(minIndexPath, indexPath.item);
                maxIndexPath = MAX(maxIndexPath, indexPath.item);
                count ++;
            }
//            NSLog(@"%@", NSDictionaryOfVariableBindings(@(minIndexPath), @(maxIndexPath), @(count)));
        };
        void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
            self.pinchStartedInListLayout = NO;
            [self invalidateLayout];
        };
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
        [UIView animateWithDuration:.3
                              delay:0
             usingSpringWithDamping:.4
              initialSpringVelocity:-1
                            options:options
                         animations:animationBlock
                         completion:completionBlock];
    }
}

- (void)setPinchRatio:(CGFloat)pinchRatio
{
    _originalPinchRatio = pinchRatio;
    pinchRatio = MIN(MAX(0.0, pinchRatio), 1.0);
    _pinchRatio = pinchRatio;
    [self invalidateLayout];
}

- (void) completeDeletion:(NSIndexPath *)cardIndexPath completion:(void (^)(void))completionBlock {
    
    NTDCollectionViewLayoutAttributes *attr = (NTDCollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:cardIndexPath];
    UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:cardIndexPath];
    /* Fixes bug in iOS 7 where deleting a cell w/ motion effects will prevent that cell from having motion effects upon reuse. */
    for (UIMotionEffect *effect in theCell.motionEffects)
        [theCell removeMotionEffect:effect];

    if (self.swipedCardOffset < 0) {
        attr.transform2D = CGAffineTransformMakeRotation(-NTDMaxNoteTiltAngle);
        attr.center = CGPointMake(attr.center.x- 2*self.collectionView.frame.size.width, attr.center.y);
    } else {
        attr.transform2D = CGAffineTransformMakeRotation(NTDMaxNoteTiltAngle);
        attr.center = CGPointMake(attr.center.x+ 2*self.collectionView.frame.size.width, attr.center.y);
    }
    
    [UIView animateWithDuration:NTDDeleteAnimationDuration animations:^{
        theCell.center = attr.center;
        theCell.transform = attr.transform2D;
        theCell.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (completionBlock)
            completionBlock();
    }];
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
    NTDCollectionViewLayoutAttributes *layoutAttributes = [self cellLayoutAttributesForItem:indexPath.item];
    NTDCollectionViewLayoutAttributes *pinchedCardLayoutAttributes = [self cellLayoutAttributesForItem:self.pinchedCardIndexPath.item];
    
    CGFloat pinchGap = self.pinchRatio * self.cardSize.height;
    CGFloat pinchOffset = self.pinchRatio * (-pinchedCardLayoutAttributes.frame.origin.y + self.collectionView.contentOffset.y);
    
    if (self.pinchStartedInListLayout) pinchGap = 0;

    
    if (_originalPinchRatio < 0) {
        NSInteger itemOffset = self.pinchedCardIndexPath.item - indexPath.item;
        CGFloat offset = _originalPinchRatio * 100;
        offset *= ABS(itemOffset);
        pinchGap += offset;
        pinchOffset -= offset;
        // dampen the pinch
        pinchGap *= .4;
        pinchOffset *= .4;
    }
    
//    NSLog(@"(%d) gap: %.2f, offset: %.2f, ratio: %.2f, offset.y: %.2f", indexPath.item, pinchGap, pinchOffset, self.pinchRatio, self.collectionView.contentOffset.y);
    
    if (indexPath.item > self.pinchedCardIndexPath.item) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, 0.0, pinchGap);
    } else if (indexPath.item <= self.pinchedCardIndexPath.item) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, 0.0, pinchOffset);
    }
    
    return layoutAttributes;
}
@end
