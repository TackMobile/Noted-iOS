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
#import "NTDCollectionViewController.h"

NSString *NTDMayShowNoteAtIndexPathNotification = @"NTDMayShowNoteAtIndexPathNotification";

@interface NTDPagingCollectionViewLayout ()

@property (nonatomic) BOOL isViewingOptions;
@property (nonatomic) NSUInteger noteCount;

@end

@implementation NTDPagingCollectionViewLayout
@synthesize activeCardIndex, pannedCardXTranslation, pannedCardYTranslation, currentOptionsOffset, isViewingOptions;
@synthesize deletedLastNote;

-(id)init
{
    if (self = [super init]) {
        isViewingOptions = NO;
        self.pinchRatio = 1;
    }
    return self;
}

+(Class)layoutAttributesClass
{
    return [NTDCollectionViewLayoutAttributes class];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    /* So, this is a pretty dirty hack. The reason why it's here is because there was a crash that occured when restarting the
     * walkthrough with only one note. Upon reloading the original notes, [self.collectionView numberOfItemsInSection:0] would
     * return 2 instead of 1, which would cause -[NTDCollectionViewController noteAtIndexPath:] to crash after
     * NTDMayShowNoteAtIndexPathNotification was sent because there was only one note.
     *
     * I suppose [self.collectionView numberOfItemsInSection:0] returns the wrong thing because we haven't called
     * -[collectionView reloadData] by the time we get here. During the crash, we get to this spot when
     * -[collectionView setCollectionViewLayout:animated:] is called within -[NTDCollectionViewController updateLayout:animated:]
     * -reloadData isn't called until the end of that method.
     *
     * There's probably a deeper bug here, but it's Thursday night and we need to ship by Saturday, so....
     */
//  NSUInteger noteCount = [self.collectionView numberOfItemsInSection:0];
    NTDCollectionViewController *controller = (NTDCollectionViewController *)[self.collectionView.window rootViewController];
    NSMutableArray *notes = [controller notes];
    self.noteCount = notes.count;
    
    for (int i = activeCardIndex+1; i > activeCardIndex - [self numberOfCardsToRender];
         i--) {
        if (i < 0 || i > self.noteCount-1)
            continue;
        else {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [attributesArray addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
//            NSLog(@"%s: may show note #%d? [ACI = %d]", __FUNCTION__, indexPath.item, activeCardIndex);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDMayShowNoteAtIndexPathNotification
                                                              object:indexPath];
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

static const int NumberOfCardsToFanOut = 6;
- (int)numberOfCardsToRender {
// render the active card with the cards above and below it unless we are at the top of the stack. In that case, render the top 6 cards
    int numberOfCardsToRender = 2;
    if (self.activeCardIndex == self.noteCount-1)
        numberOfCardsToRender = NumberOfCardsToFanOut;
    return numberOfCardsToRender;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.frame.size;
}

-(void)setActiveCardIndex:(int)newActiveCardIndex
{
    activeCardIndex = newActiveCardIndex;
    for (int i = activeCardIndex+1; i >= activeCardIndex-[self numberOfCardsToRender]; i--) {
        if (i < 0 || i+1 > [self.collectionView numberOfItemsInSection:0])
            continue;
        else {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
//            NSLog(@"%s: may show note #%d? [ACI = %d]", __FUNCTION__, indexPath.item, activeCardIndex);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDMayShowNoteAtIndexPathNotification
                                                              object:indexPath];
        }
    }
}
static const CGFloat EdgeSpaceLimit = 30;
static const CGFloat RatioToScaleEdgeSpaceAfterLimitReached = .07;

static const CGFloat PinchedNoteScaleLimit = .9;
static const CGFloat RatioToScalePinchedNoteAfterLimitReached = .07;

- (void)customizeLayoutAttributes:(NTDCollectionViewLayoutAttributes *)attr {
    attr.zIndex = attr.indexPath.row; // stack the cards
    attr.size = self.collectionView.frame.size;
    
    CGFloat scaleX = 1; CGFloat scaleY = 1; CGFloat translateY = 0; CGFloat rotateAngle = 0;
    if (self.pinchRatio != 1)
        scaleY = self.pinchRatio;
    if (deletedLastNote) {
        scaleY = .1;
        scaleX = .1;
        translateY = 300;
        attr.alpha = 0;
        rotateAngle = 45;
    }
    CATransform3D zTranslation = CATransform3DMakeTranslation(0, translateY, attr.indexPath.item);
    CATransform3D rotation = CATransform3DRotate(zTranslation, rotateAngle, 0, 0, 1);
    attr.transform3D = CATransform3DScale(rotation, scaleX, scaleY, 1);
    
    self.pannedCardYTranslation = MAX(0, self.pannedCardYTranslation);
    
    CGPoint center = CGPointMake(attr.size.width/2, attr.size.height/2 + self.pannedCardYTranslation);
    CGPoint right = CGPointMake(center.x + self.collectionView.frame.size.width, center.y);
    
    // keep the panned translation smaller than screenwidth
    pannedCardXTranslation = MAX(-self.collectionView.frame.size.width, fminf(self.collectionView.frame.size.width, pannedCardXTranslation));
    
    // if we're viewing options, offset center
    if (isViewingOptions && attr.indexPath.row == activeCardIndex) {
        center = (CGPoint){center.x+currentOptionsOffset, center.y};
    }
    
    // if were panning right, slide active card off of stack (unless there are no more card, in which case, show edge)
    if (pannedCardXTranslation > 0 &&
        attr.indexPath.row == activeCardIndex) {
        CGFloat adjustedTranslation = pannedCardXTranslation;
        if (activeCardIndex == 0)
            if (pannedCardXTranslation > EdgeSpaceLimit)
                adjustedTranslation = EdgeSpaceLimit + (pannedCardXTranslation-EdgeSpaceLimit)*RatioToScalePinchedNoteAfterLimitReached;
        attr.center = (CGPoint){center.x+adjustedTranslation, center.y};
        
    // if panning left and in options, push it back
    } else if (pannedCardXTranslation < 0 && isViewingOptions &&
               attr.indexPath.row == activeCardIndex) {
        attr.center = (CGPoint){center.x+pannedCardXTranslation, center.y};
    
    // if panning left and not in options, slide next card towards center
    } else if (pannedCardXTranslation < 0 && !isViewingOptions &&
               attr.indexPath.row == activeCardIndex+1) {
        attr.center = (CGPoint){right.x+pannedCardXTranslation, right.y};
        
    // if panning left and not in options and we're on the last card, show edge
    } else if (pannedCardXTranslation < 0 && !isViewingOptions && activeCardIndex == self.noteCount-1) {
        CGFloat adjustedTranslation = pannedCardXTranslation;
        if (pannedCardXTranslation < -EdgeSpaceLimit)
            adjustedTranslation = -EdgeSpaceLimit + (pannedCardXTranslation + EdgeSpaceLimit)*RatioToScalePinchedNoteAfterLimitReached;
        if (self.noteCount > 1) {
            // fan the cards behind the top card out
            NSUInteger numberOfCardsBeingFanned = MIN(self.noteCount, NumberOfCardsToFanOut) - 1;
            NSUInteger countOffset = self.noteCount - 1 - numberOfCardsBeingFanned;
            adjustedTranslation = adjustedTranslation/numberOfCardsBeingFanned * (attr.indexPath.item - countOffset);
        }
        attr.center = (CGPoint){center.x+adjustedTranslation, center.y};
    
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
    CGFloat translation = self.pannedCardXTranslation + self.pannedCardYTranslation; //only one of these will be non-zero
    BOOL translatingAlongXAxis = self.pannedCardXTranslation != 0;
    
    /* This fix is technically correct and animation speeds on iOS 6 but made iOS 7 feel too fast. This is probably why we had to
     * tweak this method on iOS 7 so much. I'm going to make it iOS 6-only for now because we need to ship and I can't fuck with the curves. */
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
         translatingAlongXAxis |= (self.pannedCardXTranslation == 0 && self.pannedCardYTranslation == 0);
    
    self.pannedCardYTranslation = 0;
    self.pannedCardXTranslation = 0;
    self.deletedLastNote = NO;
    self.pinchRatio = 1;
    
    // calculate animation duration (velocity=points/seconds so seconds=points/velocity)
    NSTimeInterval dur;
    CGFloat length = translatingAlongXAxis ? self.collectionView.frame.size.width : self.collectionView.frame.size.height;
    if (ABS(translation)/length > .5) length = ABS(translation);
    
    if (isViewingOptions)
        dur = self.currentOptionsOffset / ABS(velocity);
    else
        dur = (length) / ABS(velocity);
    
    // keep dur between .05 and .2. feels comfortable
//    float position = dur * fabsf(velocity);
//    dur = CLAMP(dur, .05, .2);
    
    BOOL shouldAdvanceToNextWalkthroughStep = (self.activeCardIndex+1 == [self.collectionView numberOfItemsInSection:0]);
    if (shouldAdvanceToNextWalkthroughStep) [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughSwipeToLastNoteStep];
    
    //  animate
    void (^animationBlock)() = ^{
        for (int i = activeCardIndex+1; i > activeCardIndex-[self numberOfCardsToRender]; i--) {
            if (i < 0 || i+1 > self.noteCount)
                continue;
            else {
                NSIndexPath *theIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
                UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:theIndexPath];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                
                UICollectionViewLayoutAttributes *theAttr;
                theAttr = [self layoutAttributesForItemAtIndexPath:indexPath];
                
                /* Without this, after the one card pinch animation completes, the relative time label will snap back. 
                 * Also, without setitng the cell's opacity back to 1, a new card will not fade back in after thelast card is deleted
                 */
                if (self.noteCount == 1) {
                    theCell.layer.transform = theAttr.transform3D;
                    theCell.layer.opacity = 1;
                }
            }
        }
    };
    void (^animationCompletionBlock)(BOOL finished) = ^(BOOL finished) {
        [self invalidateLayout]; /* This may not be needed. */
        if (completionBlock)
            completionBlock();
        if (shouldAdvanceToNextWalkthroughStep)
            [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughSwipeToLastNoteStep];
    };

    NSTimeInterval animationDuration = CLAMP(dur, .05, .5);
//    CGFloat springVelocity = animationDuration * (ABS(velocity)/320);
    CGFloat damping = (dur < .5) ? .7 : .5;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [UIView animateWithDuration:animationDuration
                              delay:0.0
             usingSpringWithDamping:damping
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationBlock
                         completion:animationCompletionBlock];
    } else {
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationBlock
                         completion:animationCompletionBlock];
    }
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
    
    CGFloat velocity = (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) ? 0.2 : 600;
    [self finishAnimationWithVelocity:velocity completion:completionBlock];

}

- (void) hideOptionsWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock {
    isViewingOptions = NO;
    currentOptionsOffset = 0.0;
    
    [self finishAnimationWithVelocity:velocity completion:completionBlock];
}

@end
