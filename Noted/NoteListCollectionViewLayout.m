//
//  NoteListCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteListCollectionViewLayout.h"

@interface NoteListCollectionViewLayout ()
@property (nonatomic, strong) NSMutableArray *layoutAttributesArray;
@end

@implementation NoteListCollectionViewLayout

- (id)init
{
    if (self = [super init]) {
        self.contentInset = UIEdgeInsetsZero;
        self.cardOffset = 65.0;
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        self.cardSize = applicationFrame.size;
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
        
        CGRect frame = CGRectMake(self.contentInset.left,
                                  i * self.cardOffset + self.contentInset.top,
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
    if (self.selectedCardIndexPath) {
        CGRect frame = layoutAttributes.frame;
        if ([indexPath isEqual:self.selectedCardIndexPath]) {
            frame.origin.y = self.contentInset.top;
        } else {
            frame.origin.y += [[UIScreen mainScreen] bounds].size.height;
            layoutAttributes.alpha = 0.0;
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
    if (self.selectedCardIndexPath) {
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

- (void)setSelectedCardIndexPath:(NSIndexPath *)selectedCardIndexPath
{
    _selectedCardIndexPath = selectedCardIndexPath;
//    [self invalidateLayout];
}

@end
