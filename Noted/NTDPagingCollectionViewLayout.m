//
//  NTDPagingCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDPagingCollectionViewLayout.h"
#import "NoteCollectionViewLayoutAttributes.h"

NSString * const NTDCollectionElementKindDuplicateCard = @"NTDCollectionElementKindDuplicateCard";

@interface NTDPagingCollectionViewLayout ()
@property (nonatomic, assign) BOOL shouldReplaceStationaryCard;
@end

@implementation NTDPagingCollectionViewLayout

-(id)init
{
    if (self = [super init]) {
        self.minimumLineSpacing = 20.0;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, self.minimumLineSpacing);
    }
    return self;
}

+ (Class)layoutAttributesClass
{
    return [NoteCollectionViewLayoutAttributes class];
}

//- (CGSize)collectionViewContentSize
//{
//    return [[[UIApplication sharedApplication] keyWindow] bounds].size;
//}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
    BOOL containsAttributesForPannedCard = NO, containsAttributesForStationaryCard = NO;
    for (NoteCollectionViewLayoutAttributes *layoutAttributes in attributesArray) {
        if ([layoutAttributes.indexPath isEqual:self.pannedCardIndexPath]) {
            containsAttributesForPannedCard = YES;
        } else if ([layoutAttributes.indexPath isEqual:self.stationaryCardIndexPath]) {
            containsAttributesForStationaryCard = YES;
        }
    }
    
    NSMutableArray *mutableAttributesArray = [NSMutableArray arrayWithArray:attributesArray];
    if (self.pannedCardIndexPath != nil && !containsAttributesForPannedCard) {
        [mutableAttributesArray addObject:[super layoutAttributesForItemAtIndexPath:self.pannedCardIndexPath]];
    } else if (self.stationaryCardIndexPath != nil && !containsAttributesForStationaryCard) {
        NSLog(@"add stat?");
        [mutableAttributesArray addObject:[super layoutAttributesForItemAtIndexPath:self.stationaryCardIndexPath]];
    } else if (self.stationaryCardIndexPath != nil && self.pagingDirection == NTDPagingDirectionRightToLeft) {
        NSLog(@"add supp");
        [mutableAttributesArray addObject:[self layoutAttributesForSupplementaryViewOfKind:NTDCollectionElementKindDuplicateCard atIndexPath:self.stationaryCardIndexPath]];
    }
    
    for (NoteCollectionViewLayoutAttributes *layoutAttributes in mutableAttributesArray) {
        [self customizeLayoutAttributes:layoutAttributes];
    };
    
    return mutableAttributesArray;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewLayoutAttributes *layoutAttributes = (NoteCollectionViewLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    [self customizeLayoutAttributes:layoutAttributes];
    return layoutAttributes;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:NTDCollectionElementKindDuplicateCard] && [indexPath isEqual:self.stationaryCardIndexPath]) {
        NoteCollectionViewLayoutAttributes *layoutAttributes = (NoteCollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:indexPath];
        if (self.pagingDirection == NTDPagingDirectionRightToLeft) {
            CGRect frame = CGRectOffset(layoutAttributes.frame, -340.0, 0.0);
            layoutAttributes.frame = frame;
            layoutAttributes.zIndex = -1;
        }
        return layoutAttributes;
    } else {
        return nil;
    }
}

- (void)customizeLayoutAttributes:(NoteCollectionViewLayoutAttributes *)layoutAttributes
{
    layoutAttributes.shouldApplyCornerMask = YES;
    [self applyPanToLayoutAttributes:layoutAttributes];
}

-(void)applyPanToLayoutAttributes:(NoteCollectionViewLayoutAttributes *)layoutAttributes
{
    CGRect frame;
    if ([layoutAttributes.indexPath isEqual:self.pannedCardIndexPath]) {
        NSLog(@"apply pan");
        if (self.shouldReplaceStationaryCard) {
            NSLog(@"resetting");
            frame = [[super layoutAttributesForItemAtIndexPath:self.stationaryCardIndexPath] frame];
            [self resetPanningProperties];
        } else {
            frame = CGRectOffset(layoutAttributes.frame, self.pannedCardXTranslation, 0.0);
        }
        layoutAttributes.frame = frame;
    } else if ([layoutAttributes.indexPath isEqual:self.stationaryCardIndexPath]) {
//        if (self.pagingDirection == NTDPagingDirectionRightToLeft) {
//            frame = CGRectOffset(layoutAttributes.frame, -340.0, 0.0);
//            layoutAttributes.frame = frame;
//            layoutAttributes.zIndex = -1;
//        }
    }
}


-(void)setPannedCardIndexPath:(NSIndexPath *)pannedCardIndexPath
{
    _pannedCardIndexPath = pannedCardIndexPath;
    [self invalidateLayout];
}

-(void)setPannedCardXTranslation:(CGFloat)pannedCardXTranslation
{
    _pannedCardXTranslation = pannedCardXTranslation;
    [self invalidateLayout];
}

-(void)setStationaryCardIndexPath:(NSIndexPath *)stationaryCardIndexPath
{
    _stationaryCardIndexPath = stationaryCardIndexPath;
    [self invalidateLayout];
}

-(void)completePanGesture:(BOOL)shouldReplaceStationaryCard
{
    self.shouldReplaceStationaryCard = shouldReplaceStationaryCard;
    if (!shouldReplaceStationaryCard) {
        [self resetPanningProperties];
    }
    [self invalidateLayout];
}

- (void)resetPanningProperties
{
    _pannedCardIndexPath = nil;
    _pannedCardXTranslation = 0.0;
    _shouldReplaceStationaryCard = NO;
    _stationaryCardIndexPath = nil;
    _pagingDirection = NTDPagingDirectionInvalidDirection;
}
@end
