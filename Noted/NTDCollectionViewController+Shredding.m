//
//  NoteCollectionViewController+Shredding.m
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NTDCollectionViewController+Shredding.h"
#import "NTDCollectionViewCell.h"
#import "UIDeviceHardware.h"
#import "NTDDeletedNotePlaceholder.h"

@interface ColumnForShredding : NSObject
@property (nonatomic, strong) NSMutableArray *slices;
@property (nonatomic) float percentLeft;
@property (nonatomic) BOOL isDeleted;
@end

@implementation ColumnForShredding
@synthesize slices, percentLeft, isDeleted;
- (id) init {
    self = [super init];
    slices = [NSMutableArray array];
    percentLeft  = 0;
    isDeleted = NO;
    return self;
}
@end


@implementation NTDCollectionViewController (Shredding)

static CGFloat zTranslation;
static CGFloat const DefaultShredAnimationDuration = 0.4, UnshredAnimationDuration = 0.68;
static CGFloat ShredAnimationDuration = DefaultShredAnimationDuration;

- (void) prepareVisibleNoteForShredding {
    self.columnsForDeletion = [NSMutableArray array];
    self.currentDeletionCell = self.visibleCell;
    
    zTranslation = [[self.visibleCell.layer valueForKeyPath:@"transform.translation.z"] floatValue] -1;
    
    CGSize sliceSize = CGSizeMake(self.collectionView.frame.size.width / self.deletedNoteVertSliceCount, self.collectionView.frame.size.height / self.deletedNoteHorizSliceCount);
    CGRect sliceRect = (CGRect){CGPointZero,sliceSize};
    
    UIImage *noteImage = [self imageForView:self.currentDeletionCell];
    
    for (int i = 0; i < self.deletedNoteVertSliceCount; i++) {
        // add a column
        ColumnForShredding *currentColumn = [[ColumnForShredding alloc] init];
        currentColumn.percentLeft = (sliceSize.width*i)/self.collectionView.frame.size.width;
        [self.columnsForDeletion addObject:currentColumn];
        
        // insert the slices
        for (int j=0; j<self.deletedNoteHorizSliceCount; j++) {
            
            CGRect cropRect = CGRectOffset(sliceRect, i*sliceSize.width, j*sliceSize.height);
            
            UIImageView *sliceImageView = [[UIImageView alloc] initWithImage:noteImage];
            sliceImageView.frame = cropRect;
            sliceImageView.layer.shadowOffset = CGSizeZero;
            sliceImageView.layer.allowsGroupOpacity = NO;
            sliceImageView.layer.allowsEdgeAntialiasing = YES;
            
            CGRect cardRect = self.currentDeletionCell.bounds;
            CGRect contentFrame = CGRectMake(cropRect.origin.x / cardRect.size.width,
                                             cropRect.origin.y / cardRect.size.height,
                                             cropRect.size.width / cardRect.size.width,
                                             cropRect.size.height / cardRect.size.height);
            sliceImageView.layer.contentsRect = contentFrame;
            sliceImageView.layer.contentsGravity = kCAGravityCenter;
            
            CGPathRef shadowPathRef = CGPathCreateWithRect(CGRectOffset(sliceImageView.bounds, 0, 0), nil);
            sliceImageView.layer.shadowPath = shadowPathRef;
            CGPathRelease(shadowPathRef);
            sliceImageView.layer.shadowOpacity = .5;
            sliceImageView.layer.shadowRadius = 1.8;
            
            sliceImageView.layer.transform = CATransform3DMakeTranslation(0, 0, zTranslation);
            
            [currentColumn.slices addObject:sliceImageView];
            [self.collectionView insertSubview:sliceImageView belowSubview:self.currentDeletionCell];
        }
    }
    
    // set up a mask for the note. we'll move the mask right as the user swipes right
    
    CAShapeLayer *maskingLayer = [CAShapeLayer layer];
    CGPathRef path = CGPathCreateWithRect(self.visibleCell.bounds, NULL);
    maskingLayer.path = path;
    CGPathRelease(path);
    
    self.currentDeletionCell.layer.mask = maskingLayer;
}

- (void) shredVisibleNoteByPercent:(float)percent completion:(void(^)(void))completionBlock {
    // percent should range between 0.0 and 1.0
    
    float noteWidth = self.currentDeletionCell.frame.size.width;
    float columnWidth = noteWidth/self.deletedNoteVertSliceCount;
    
    NSMutableArray *colsToRemove = [NSMutableArray array];
    __block BOOL useNextPercentForMask = NO;
    __block BOOL shiftMaskAfterAnimation = NO;
    __block ColumnForShredding *columnForUseAsMaskAfterAnimation = nil;
    
    [UIView animateWithDuration:ShredAnimationDuration animations:^{
        // fade out
        // decide which rows will be deleted
        for (ColumnForShredding *column in self.columnsForDeletion) {
            if (column.isDeleted) {
                if ((self.twoFingerDeletionDirection == NTDDeletionDirectionRight && column.percentLeft >= percent)
                    || (self.twoFingerDeletionDirection == NTDDeletionDirectionLeft && column.percentLeft <= percent)) {
                  
                    // animate un-shredding of the column
                    for (UIImageView *slice in column.slices) {
                        slice.alpha = 1;
                        slice.layer.transform = CATransform3DMakeTranslation(0, 0, zTranslation);

                        // For this to animate properly the zTranslation value must be correct. If it is incorrect the shadow
                        // opacity simply snaps into place either when animating a two-finger swipe that wasn't completed
                        // or when restoring a deleted note via the two-finger swipe
                        CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                        shadowAnimation.fromValue = @(0.5);
                        shadowAnimation.toValue = @(0);
                        shadowAnimation.duration = ShredAnimationDuration;
                        [slice.layer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
                        [slice.layer setValue:shadowAnimation.toValue forKeyPath:shadowAnimation.keyPath];
                    }
                    
                    column.isDeleted = NO;
                    
                    useNextPercentForMask = YES; // this is really defining the current column to be used
                    shiftMaskAfterAnimation = YES;  // after the cells animate back to position
                }
            }
            
            if (useNextPercentForMask) {
                if (shiftMaskAfterAnimation) {
                    columnForUseAsMaskAfterAnimation = column;
                    shiftMaskAfterAnimation = NO;
                } else {
                    // shift the mask over
                    CGRect maskFrame = {.origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
                    switch (self.twoFingerDeletionDirection) {
                        case NTDDeletionDirectionRight:
                            maskFrame.origin.x = column.percentLeft * noteWidth;
                            break;
                            
                        case NTDDeletionDirectionLeft:
                            maskFrame.origin.x = -(1-column.percentLeft) * noteWidth - columnWidth;
                            break;
                            
                        default:
                            break;
                    }
                    
                    [CATransaction begin];
                    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                    self.currentDeletionCell.layer.mask.frame = maskFrame;
                    [CATransaction commit];
                }
                useNextPercentForMask = NO;
            }
            
            if ([self column:column shouldBeDeletedAtPercent:percent]) {
                //[colsToRemove addObject:column];
                
                useNextPercentForMask = YES;
                
                int direction = 1;
                if (self.twoFingerDeletionDirection == NTDDeletionDirectionLeft)
                    direction = -1;
                
                // animate shredding of the column
                for (UIImageView *slice in column.slices) {
                    CATransform3D randomRotation = CATransform3DRotate(slice.layer.transform, (float)rand()/RAND_MAX*M_PI_2 - M_PI_4, 0, 0, 1);
                    CATransform3D randomTranslation = CATransform3DTranslate(randomRotation, direction * (float)rand()/RAND_MAX * -100, (float)rand()/RAND_MAX * 100 - 50, 0);
                    slice.layer.transform = randomTranslation;
                    slice.alpha = 0;
                    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                    shadowAnimation.fromValue = @(0.5);
                    shadowAnimation.toValue = @(0);
                    shadowAnimation.duration = ShredAnimationDuration;
                    shadowAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.85 :0.00 :1.00 :1.00];
                    [slice.layer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
                    [slice.layer setValue:shadowAnimation.toValue forKeyPath:shadowAnimation.keyPath];
                }
                
                column.isDeleted = YES;
            }
        }
        
        if ([self shouldCompleteShredForPercent:percent]) { // the last column was deleted
            // remove the mask
            CGRect maskFrame = {.origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
            
            maskFrame.origin.x = (self.twoFingerDeletionDirection == NTDDeletionDirectionRight) ? noteWidth : -noteWidth;
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
            
            useNextPercentForMask = NO;
        }

    } completion:^(BOOL finished) {
        for (ColumnForShredding *column in colsToRemove) {
            for (UIImageView *slice in column.slices)
                [slice removeFromSuperview];
        }
        
        // check if we should change the mask after the animation
        if (columnForUseAsMaskAfterAnimation != nil) {
            CGRect maskFrame = {.origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
            
            if (self.twoFingerDeletionDirection == NTDDeletionDirectionRight) {
                maskFrame.origin.x = columnForUseAsMaskAfterAnimation.percentLeft*noteWidth;
            } else {
                maskFrame.origin.x = (columnForUseAsMaskAfterAnimation.percentLeft-1)*noteWidth + columnWidth;
            }
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
            
            for (UIView *slice in columnForUseAsMaskAfterAnimation.slices) {
                CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                shadowAnimation.fromValue = @(0.15);
                shadowAnimation.toValue = @(0.5);
                shadowAnimation.duration = .09;
                shadowAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                [slice.layer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
                [slice.layer setValue:shadowAnimation.toValue forKeyPath:shadowAnimation.keyPath];
            }
        }
        
        if ([self shouldCompleteShredForPercent:percent]) {
            
            CGRect maskFrame = { .origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
            
            maskFrame.origin.x = (self.twoFingerDeletionDirection == NTDDeletionDirectionRight) ? noteWidth : -noteWidth;
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
            
            [self clearAllShreddedPieces];
        }
        
        if (completionBlock)
            completionBlock();
    }];

}

- (void) cancelShredForVisibleNote
{
    [self cancelShredForVisibleNoteWithCompletionBlock:nil];
}

- (void) cancelShredForVisibleNoteWithCompletionBlock:(void(^)(void))completionBlock
{
    if (self.columnsForDeletion.count == 0)
        return;
  
    CGFloat shredByPercent = (self.twoFingerDeletionDirection == NTDDeletionDirectionRight) ? 0 : 1;
    [self shredVisibleNoteByPercent:shredByPercent completion:^{
        // remove slices from view
        self.currentDeletionCell.layer.mask = nil;
        [self clearAllShreddedPieces];
        if (completionBlock) completionBlock();
    }];
}

- (void) clearAllShreddedPieces {
    for (ColumnForShredding *col in self.columnsForDeletion) {
        for (UIView *slice in col.slices)
            [slice removeFromSuperview];
    }
}

- (BOOL)shouldCompleteShredForPercent:(float)percent {
    return ((self.twoFingerDeletionDirection == NTDDeletionDirectionRight && percent == 1)
            || (self.twoFingerDeletionDirection == NTDDeletionDirectionLeft && percent == 0));
}

- (void)restoreShreddedNote:(NTDDeletedNotePlaceholder *)restoredNote
{
    for (ColumnForShredding *col in restoredNote.savedColumnsForDeletion)
        for (UIImageView *slice in col.slices)
            [self.collectionView addSubview:slice];

    ShredAnimationDuration = UnshredAnimationDuration;
    self.twoFingerDeletionDirection = restoredNote.deletionDirection;
    self.columnsForDeletion = restoredNote.savedColumnsForDeletion;
    [self cancelShredForVisibleNoteWithCompletionBlock:^{
        [self.collectionView reloadData];
        ShredAnimationDuration = DefaultShredAnimationDuration;
    }];
    
}

#pragma mark - utilities

- (BOOL) column:(ColumnForShredding *)column shouldBeDeletedAtPercent:(float)percent {
    float noteWidth = self.currentDeletionCell.frame.size.width;
    float columnWidth = noteWidth/self.deletedNoteVertSliceCount;
    
    if (column.isDeleted)
        return NO;
    
    if (self.twoFingerDeletionDirection == NTDDeletionDirectionRight)
        return ((column.percentLeft + (columnWidth/noteWidth)) <= percent);
    else if (self.twoFingerDeletionDirection == NTDDeletionDirectionLeft)
        return (column.percentLeft >= percent);
    else 
        return NO; /* Should never reach here. */    
}

- (UIImage *)imageForView:(UIView *)view
{
    CGSize imageSize = view.frame.size;
    CGFloat scale = [UIDeviceHardware isHighPerformanceDevice] ? 0 : 1;
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage* ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return ret;
}

@end
