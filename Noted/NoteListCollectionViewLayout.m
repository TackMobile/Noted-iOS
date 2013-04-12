//
//  NoteListCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteListCollectionViewLayout.h"
#import "NoteCollectionViewController.h"
#import "UIView+FrameAdditions.h"

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
        self.pullToCreateShowCardOffset = -40.0;
        self.pullToCreateScrollCardOffset = -65.0;
        self.pullToCreateCreateCardOffset = -100.0;
    }
    return self;
}

- (void)prepareLayout
{
    NSUInteger cardCount = [self.collectionView numberOfItemsInSection:0];
    self.layoutAttributesArray = [NSMutableArray arrayWithCapacity:cardCount];

    for (NSUInteger i = 0; i < cardCount; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        CGFloat height = (i == 0) ? 0.0 : (i-1) * self.cardOffset + self.contentInset.top;
        CGRect frame = CGRectMake(self.contentInset.left,
                                  height,
                                  self.cardSize.width - self.contentInset.right,
                                  self.cardSize.height);
        layoutAttributes.frame = frame;
        layoutAttributes.zIndex = i;
        
        [self.layoutAttributesArray addObject:layoutAttributes];
    }
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = self.layoutAttributesArray[indexPath.item];
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
        CGFloat y = self.collectionView.contentOffset.y;
        CGFloat pullToCreateLabelHeight = [[self.collectionView viewWithTag:PullToCreateLabelTag] $height];
        if (y <= self.pullToCreateShowCardOffset && y > self.pullToCreateScrollCardOffset) {
            frame.origin.y = y + pullToCreateLabelHeight;
        } else if (y <= self.pullToCreateScrollCardOffset && y > self.pullToCreateCreateCardOffset) {
            
        } else if (y <= self.pullToCreateCreateCardOffset) {
            
        }
        layoutAttributes.frame = frame;
    }
    
    return layoutAttributes;    
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSPredicate *inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        return CGRectIntersectsRect(layoutAttributes.frame, rect);
    }];
    NSArray *attributesArray = [self.layoutAttributesArray filteredArrayUsingPredicate:inRectPredicate];
    if (self.selectedCardIndexPath || [self shouldShowCreateableCard]) {
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
        CGFloat contentHeight = (cardCount - 1) * self.cardOffset + self.cardSize.height
            + self.contentInset.top + self.contentInset.bottom;
        CGFloat contentWidth = self.cardSize.width + self.contentInset.left + self.contentInset.right;
        return CGSizeMake(contentWidth, contentHeight);
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
   return (newBounds.origin.y < self.pullToCreateShowCardOffset);
}

- (void)setSelectedCardIndexPath:(NSIndexPath *)selectedCardIndexPath
{
    _selectedCardIndexPath = selectedCardIndexPath;
//    [self invalidateLayout];
}

- (BOOL)shouldShowCreateableCard
{
    return (self.collectionView.contentOffset.y < self.pullToCreateShowCardOffset);
}

@end
