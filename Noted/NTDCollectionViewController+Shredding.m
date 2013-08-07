//
//  NoteCollectionViewController+Shredding.m
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController+Shredding.h"
#import "NTDCollectionViewCell.h"
#import "UIImage+Crop.h"
#import <QuartzCore/QuartzCore.h>

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

/*@interface NoteCollectionViewController ()

@property (nonatomic, strong) NSMutableArray *columnsForDeletion;
@property (nonatomic, strong) NoteCollectionViewCell *currentDeletionCell;

@end*/

@implementation NTDCollectionViewController (Shredding)

static CGFloat zTranslation;

- (void) prepareVisibleNoteForShredding {
    self.columnsForDeletion = [NSMutableArray array];
    
    self.currentDeletionCell = self.visibleCell;
    [self.columnsForDeletion removeAllObjects];
        
    zTranslation = [[self.visibleCell.layer valueForKeyPath:@"transform.translation.z"] floatValue] -1;
    
    CGSize sliceSize = CGSizeMake(self.collectionView.frame.size.width / self.deletedNoteVertSliceCount, self.collectionView.frame.size.height / self.deletedNoteHorizSliceCount);
    CGRect sliceRect = (CGRect){CGPointZero,sliceSize};
    
    UIImage *noteImage = [self imageForView:self.currentDeletionCell];
    
    for (int i=0; i<self.deletedNoteVertSliceCount; i++) {
        // add a column
        ColumnForShredding *currentColumn = [[ColumnForShredding alloc] init];
        currentColumn.percentLeft = (sliceSize.width*i)/self.collectionView.frame.size.width;
        [self.columnsForDeletion addObject:currentColumn];
        
        // insert the slices
        for (int j=0; j<self.deletedNoteHorizSliceCount; j++) {
            
            CGRect cropRect = CGRectOffset(sliceRect, i*sliceSize.width, j*sliceSize.height);
            
            UIImageView *sliceImageView = [[UIImageView alloc] initWithImage:[noteImage crop:cropRect]];
            
            sliceImageView.frame = cropRect;
            sliceImageView.layer.shadowOffset = CGSizeZero;
            sliceImageView.layer.shouldRasterize = YES;
            
            sliceImageView.layer.shadowPath = CGPathCreateWithRect(CGRectOffset(sliceImageView.bounds, 0, 0), nil);
            sliceImageView.layer.shadowOpacity = .5;
            
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

- (void) shredVisibleNoteByPercent:(float)percent completion:(void (^)(void))completionBlock {
    // percent should range between 0.0 and 1.0
    
    float noteWidth = self.currentDeletionCell.frame.size.width;
    float columnWidth = noteWidth/self.deletedNoteVertSliceCount;
    
    NSMutableArray *colsToRemove = [NSMutableArray array];
    __block BOOL useNextPercentForMask = NO;
    __block BOOL shiftMaskAfterAnimation = NO;
    __block ColumnForShredding *columnForUseAsMaskAfterAnimation = nil;
    
    // animate slices
    [UIView animateWithDuration:.4 animations:^{
        // fade out
        // decide which rows will be deleted
        for (ColumnForShredding *column in self.columnsForDeletion) {
            if (column.isDeleted) {
                if ((self.deletionDirection == NTDPageDeletionDirectionRight && column.percentLeft >= percent)
                    || (self.deletionDirection == NTDPageDeletionDirectionLeft && column.percentLeft <= percent)) {
                    // begin to animate slices back in
                    // animate un-shredding of the column
                    for (UIImageView *slice in column.slices) {
                        slice.alpha = 1;
                        
                        // set the transform to normal
//                        slice.layer.transform = CATransform3DIdentity;
                        slice.layer.transform = CATransform3DMakeTranslation(0, 0, zTranslation);
                        slice.layer.shadowRadius = 3;
                        
                        // causes performance issues
                        /*mask the shadow so it doesn't overlap other slices
                         CAShapeLayer *sliceMask = [CAShapeLayer layer];
                         CGRect sliceMaskRect = (CGRect){{-10, 0},{slice.bounds.size.width+10, slice.bounds.size.height}};
                         sliceMask.path = CGPathCreateWithRect(sliceMaskRect, nil);
                         slice.layer.mask = sliceMask;*/
                        
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
                    switch (self.deletionDirection) {
                        case NTDPageDeletionDirectionRight:
                            maskFrame.origin.x = column.percentLeft * noteWidth;
                            break;
                            
                        case NTDPageDeletionDirectionLeft:
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
                if (self.deletionDirection == NTDPageDeletionDirectionLeft)
                    direction = -1;
                
                // animate shredding of the column
                for (UIImageView *slice in column.slices) {
                    // remove any mask and set up properties
                    slice.layer.shadowPath = CGPathCreateWithRect(CGRectOffset(slice.bounds, 0, 0), nil);
                    slice.layer.shadowRadius = (float)rand()/RAND_MAX * 3 + 3;
                    slice.alpha = 0;
                    
//                    // Rotate some degrees
//                    CGAffineTransform randomRotation = CGAffineTransformMakeRotation((float)rand()/RAND_MAX*M_PI_2 - M_PI_4);
//                    
//                    // Move to the left
//                    CGAffineTransform randomTranslation = CGAffineTransformMakeTranslation(direction * (float)rand()/RAND_MAX * -100,(float)rand()/RAND_MAX * 100 - 50);
//                    
//                    // Apply them to a view
//                    CGAffineTransform randomTransformation = CGAffineTransformConcat(randomTranslation, randomRotation);
                    CATransform3D randomRotation = CATransform3DRotate(slice.layer.transform, (float)rand()/RAND_MAX*M_PI_2 - M_PI_4, 0, 0, 1);
                    CATransform3D randomTranslation = CATransform3DTranslate(randomRotation, direction * (float)rand()/RAND_MAX * -100, (float)rand()/RAND_MAX * 100 - 50, 0);
                    
                    slice.layer.transform = randomTranslation;
                    

                }
                
                column.isDeleted = YES;
            }
        }
        
        if ([self shouldCompleteShredForPercent:percent]) { // the last column was deleted
            // remove the mask
            CGRect maskFrame = {.origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
            
            maskFrame.origin.x = (self.deletionDirection == NTDPageDeletionDirectionRight) ? noteWidth : -noteWidth;
            
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
            
            if (self.deletionDirection == NTDPageDeletionDirectionRight) {
                maskFrame.origin.x = columnForUseAsMaskAfterAnimation.percentLeft*noteWidth;
            } else {
                maskFrame.origin.x = (columnForUseAsMaskAfterAnimation.percentLeft-1)*noteWidth + columnWidth;
            }
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
        }
        
        if ([self shouldCompleteShredForPercent:percent]) {
            
            CGRect maskFrame = { .origin.y = 0, .size = self.currentDeletionCell.layer.mask.frame.size};
            
            maskFrame.origin.x = (self.deletionDirection == NTDPageDeletionDirectionRight) ? noteWidth : -noteWidth;
            
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

- (void) cancelShredForVisibleNote {
    
    // make sure we have columns to delete
    if (self.columnsForDeletion.count == 0)
        return;
    
    float shredByPercent;
    switch (self.deletionDirection) {
        case NTDPageDeletionDirectionLeft:
            shredByPercent = 1;
            break;
            
        case NTDPageDeletionDirectionRight:
        default:
            shredByPercent = 0;
            break;
    }
    
    [self shredVisibleNoteByPercent:shredByPercent completion:^{
        // remove slices from view
        self.currentDeletionCell.layer.mask = nil;
        [self clearAllShreddedPieces];
    }];
    
}

- (void) clearAllShreddedPieces {
    for (ColumnForShredding *col in self.columnsForDeletion) {
        for (UIView *slice in col.slices)
            [slice removeFromSuperview];
    }
    [self.columnsForDeletion removeAllObjects];
}

- (BOOL)shouldCompleteShredForPercent:(float)percent {
    return ((self.deletionDirection == NTDPageDeletionDirectionRight && percent == 1)
            || (self.deletionDirection == NTDPageDeletionDirectionLeft && percent == 0));
}

#pragma mark - utilities

- (BOOL) column:(ColumnForShredding *)column shouldBeDeletedAtPercent:(float)percent {
    float noteWidth = self.currentDeletionCell.frame.size.width;
    float columnWidth = noteWidth/self.deletedNoteVertSliceCount;
    
    if (column.isDeleted)
        return NO;
    
    if (self.deletionDirection == NTDPageDeletionDirectionRight)
        return ((column.percentLeft + (columnWidth/noteWidth)) <= percent);
    else if (self.deletionDirection == NTDPageDeletionDirectionLeft)
        return (column.percentLeft >= percent);
    else 
        return NO; /* Should never reach here. */    
}

- (UIImage *)imageForView:(UIView *)view
{
    // this does not take scale into account on purpose (performance)
    UIGraphicsBeginImageContext(view.frame.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return ret;
}


@end
