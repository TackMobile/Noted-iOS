//
//  NTDPagingCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDPagingCollectionViewLayout.h"
#import "NSIndexPath+NTDManipulation.h"
#import "NTDCollectionViewLayoutAttributes.h"
#import "NTDWalkthrough.h"
#import "NTDListCollectionViewLayout.h"

static const NSTimeInterval RevealOptionsAnimationDuration = 0.2f;

@interface NTDPagingCollectionViewLayout ()

@property (nonatomic) BOOL isViewingOptions;

@end

@implementation NTDPagingCollectionViewLayout
@synthesize activeCardIndex, pannedCardXTranslation, pannedCardYTranslation, currentOptionsOffset, isViewingOptions;

-(id)init
{
    if (self = [super init]) {
        isViewingOptions = NO;
    }
    return self;
}

+(Class)layoutAttributesClass
{
    return [NTDCollectionViewLayoutAttributes class];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    // show the current card, the card on bottom, the card on top
    for (int i = activeCardIndex+1; i > activeCardIndex-2; i--) {
        if (i < 0 || i+1 > [self.collectionView numberOfItemsInSection:0])
            continue;
        else {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [attributesArray addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
//            NSLog(@"active: %i, this:%i",self.activeCardIndex, indexPath.row );
        }
    }
    
    // add the creatable card behind everything
    if (self.pannedCardYTranslation != 0) {
        UICollectionViewLayoutAttributes *pullToCreateCardAttributes = [self layoutAttributesForSupplementaryViewOfKind:NTDCollectionElementKindPullToCreateCard atIndexPath: [NSIndexPath indexPathForItem:0 inSection:0] ];
        
        [attributesArray addObject:pullToCreateCardAttributes];
    }

    return attributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NTDCollectionViewLayoutAttributes *attr = [NTDCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    [self customizeLayoutAttributes:attr];
    return attr;
}


-(UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
    
    if (kind == NTDCollectionElementKindPullToCreateCard) {
        attr.transform3D = CATransform3DMakeTranslation(0, 0, -1);
        attr.zIndex = -1;

        if (self.pannedCardXTranslation == 0 && self.pannedCardYTranslation != 0) {
            attr.zIndex = self.activeCardIndex-.5;
            attr.transform3D = CATransform3DMakeTranslation(0, 0, self.activeCardIndex-.5);
            attr.hidden = NO;
        } else {
            attr.hidden = YES;
        }
        attr.size = self.collectionView.frame.size;
        
        CGFloat pullToCreateCardOffset = 0;
        if (self.pannedCardYTranslation > NTDPullToCreateScrollCardOffset)
            pullToCreateCardOffset = CLAMP(NTDPullToCreateScrollCardOffset*2 - self.pannedCardYTranslation, 0, NTDPullToCreateShowCardOffset);
        else
            pullToCreateCardOffset = NTDPullToCreateShowCardOffset;
        
        CGPoint center = CGPointMake(attr.size.width/2, attr.size.height/2 + pullToCreateCardOffset);
        attr.center = center;
    }
    
    return attr;
    
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.frame.size;
}

- (void)customizeLayoutAttributes:(NTDCollectionViewLayoutAttributes *)attr {
    attr.zIndex = attr.indexPath.row; // stack the cards
    attr.transform3D = CATransform3DMakeTranslation(0, 0, attr.indexPath.item);
    attr.size = self.collectionView.frame.size;
        
    self.pannedCardYTranslation = MAX(0, self.pannedCardYTranslation);
    
    CGPoint center = CGPointMake(attr.size.width/2, attr.size.height/2 + self.pannedCardYTranslation);
    CGPoint right = CGPointMake(center.x + self.collectionView.frame.size.width, center.y);
    
    // keep the panned translation smaller than screenwidth
    pannedCardXTranslation = MAX(-self.collectionView.frame.size.width, fminf(self.collectionView.frame.size.width, pannedCardXTranslation));
    
    // if we're viewing options, offset center
    if (isViewingOptions && attr.indexPath.row == activeCardIndex) {
        center = (CGPoint){center.x+currentOptionsOffset, center.y};
    }
    
    // if were panning right, slide active card off of stack
    if (pannedCardXTranslation > 0 &&
        attr.indexPath.row == activeCardIndex &&
        activeCardIndex > 0) {
        attr.center = (CGPoint){center.x+pannedCardXTranslation, center.y};
        
    // if panning left and in options, push it back
    } else if (pannedCardXTranslation < 0 && isViewingOptions &&
               attr.indexPath.row == activeCardIndex) {
        attr.center = (CGPoint){center.x+pannedCardXTranslation, center.y};
    
    } else if (pannedCardXTranslation < 0 && !isViewingOptions &&
               attr.indexPath.row == activeCardIndex+1) {
        attr.center = (CGPoint){right.x+pannedCardXTranslation, right.y};
        
    // if not panning and greater than active, stack outside
    } else if (attr.indexPath.row > activeCardIndex) {
        
        attr.center = right;
        
    // if not panning and less than or equal to active, stack in center
    } else {
        attr.center = center;
    }
}
#pragma mark - customAnimation
- (void)finishAnimationWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock {
    // xTranslation, yTranslation will not be zeroed out yet
    // activeCardIndex will be current
    self.pannedCardYTranslation = 0;
    self.pannedCardXTranslation = 0;
    
    // calculate animation duration (velocity=points/seconds so seconds=points/velocity)
    NSTimeInterval dur;
    if (isViewingOptions)
        dur = self.currentOptionsOffset / fabsf(velocity);
    else
        dur = (self.collectionView.frame.size.width-pannedCardXTranslation) / fabsf(velocity);
    
    // keep dur between .05 and .2. feels comfortable
//    float position = dur * fabsf(velocity);
    dur = CLAMP(dur, .05, .2);
    
    BOOL shouldAdvanceToNextWalkthroughStep = (self.activeCardIndex+1 == [self.collectionView numberOfItemsInSection:0]);
    if (shouldAdvanceToNextWalkthroughStep) [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughSwipeToLastNoteStep];
    
    //  animate
    [UIView animateWithDuration:dur
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                        for (int i = activeCardIndex+1; i > activeCardIndex-2; i--) {
                            if (i < 0 || i+1 > [self.collectionView numberOfItemsInSection:0])
                                continue;
                            else {
                                NSIndexPath *theIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
                                UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:theIndexPath];
                                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                                
                                UICollectionViewLayoutAttributes *theAttr;
                                theAttr = [self layoutAttributesForItemAtIndexPath:indexPath];
                                
                                [theCell setFrame:theAttr.frame];
                            }
                        }
                    }
                     completion:^(BOOL finished) {
                         if (completionBlock)
                             completionBlock();
                         if (shouldAdvanceToNextWalkthroughStep)
                             [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughSwipeToLastNoteStep];
    }];
}

- (void) completePullAnimationWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock {
    [self finishAnimationWithVelocity:velocity completion:completionBlock];

}

- (void)revealOptionsViewWithOffset:(CGFloat)offset
{
    [self revealOptionsViewWithOffset:offset completion:nil];
}

- (void)revealOptionsViewWithOffset:(CGFloat)offset completion:(NTDVoidBlock)completionBlock
{
    isViewingOptions = YES;
    currentOptionsOffset = offset;
    
    [self finishAnimationWithVelocity:RevealOptionsAnimationDuration completion:completionBlock];

}

- (void) hideOptionsWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock {
    isViewingOptions = NO;
    currentOptionsOffset = 0.0;
    
    [self finishAnimationWithVelocity:velocity completion:completionBlock];
}

@end
