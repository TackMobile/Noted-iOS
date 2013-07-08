//
//  NoteCollectionViewController+Shredding.m
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewController+Shredding.h"
#import "NoteCollectionViewCell.h"
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

@implementation NoteCollectionViewController (Shredding)

- (void) prepareVisibleNoteForShredding {
    self.columnsForDeletion = [NSMutableArray array];
    

    self.currentDeletionCell = self.visibleCell;
    [self.columnsForDeletion removeAllObjects];
    
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
                        slice.transform = CGAffineTransformIdentity;
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
                    CGRect maskFrame;
                    switch (self.deletionDirection) {
                        case NTDPageDeletionDirectionRight:
                            maskFrame = (CGRect){{column.percentLeft * noteWidth, 0}, self.currentDeletionCell.layer.mask.frame.size};
                            break;
                            
                        case NTDPageDeletionDirectionLeft:
                            maskFrame = (CGRect){{-(1-column.percentLeft) * noteWidth - columnWidth, 0}, self.currentDeletionCell.layer.mask.frame.size};
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
            
            if (!column.isDeleted
                && (( self.deletionDirection == NTDPageDeletionDirectionRight && column.percentLeft < percent)
                    || (self.deletionDirection == NTDPageDeletionDirectionLeft && column.percentLeft >= percent))) {
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
                    
                    // Rotate some degrees
                    CGAffineTransform rotate = CGAffineTransformMakeRotation((float)rand()/RAND_MAX*M_PI_2 - M_PI_4);
                    
                    // Move to the left
                    CGAffineTransform translate = CGAffineTransformMakeTranslation(direction * (float)rand()/RAND_MAX * -100,(float)rand()/RAND_MAX * 100 - 50);
                    
                    // Apply them to a view
                    slice.transform = CGAffineTransformConcat(translate, rotate);
                }
                
                column.isDeleted = YES;
            }
        }
        
        if ((self.deletionDirection == NTDPageDeletionDirectionLeft && percent==0) ||
            (self.deletionDirection == NTDPageDeletionDirectionRight && percent==1)) { // the last column was deleted
            // remove the mask
            CGRect maskFrame;
            switch (self.deletionDirection) {
                case NTDPageDeletionDirectionRight:
                    maskFrame = (CGRect){{noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                case NTDPageDeletionDirectionLeft:
                    maskFrame = (CGRect){{-noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                default:
                    break;
            }
            
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
            CGRect maskFrame;
            switch (self.deletionDirection) {
                case NTDPageDeletionDirectionRight:
                    maskFrame = (CGRect){{columnForUseAsMaskAfterAnimation.percentLeft*noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                case NTDPageDeletionDirectionLeft:
                    maskFrame = (CGRect){{-(1-columnForUseAsMaskAfterAnimation.percentLeft)*noteWidth + columnWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                default:
                    break;
            }
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
            
            // give it a lil shadow
            [columnForUseAsMaskAfterAnimation.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                slice.layer.mask = nil;
            }];
            
        }
        
        if ((self.deletionDirection == NTDPageDeletionDirectionRight && percent >= 1)
            || (self.deletionDirection == NTDPageDeletionDirectionLeft && percent <= 0)) {
            
            CGRect maskFrame;
            switch (self.deletionDirection) {
                case NTDPageDeletionDirectionRight:
                    maskFrame = (CGRect){{noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                case NTDPageDeletionDirectionLeft:
                    maskFrame = (CGRect){{-noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    break;
                    
                default:
                    break;
            }
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = maskFrame;
            [CATransaction commit];
            
            [self.columnsForDeletion removeAllObjects];
            
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
        case NTDPageDeletionDirectionRight:
            shredByPercent = 0;
            break;
            
        case NTDPageDeletionDirectionLeft:
            shredByPercent = 1;
            break;
            
        default:
            shredByPercent = 0;
            break;
    }
    
    [self shredVisibleNoteByPercent:shredByPercent completion:^{
        // remove slices from view
        [self.columnsForDeletion enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ColumnForShredding *col, NSUInteger idx, BOOL *stop) {
            [col.slices enumerateObjectsUsingBlock:^(UIView *slice, NSUInteger idx, BOOL *stop) {
                [slice removeFromSuperview];
            }];
        }];
        self.currentDeletionCell.layer.mask = nil;
        [self.columnsForDeletion removeAllObjects];
    }];
    
}

#pragma mark - utilities

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
