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
    
    NSMutableArray *colsToRemove = [NSMutableArray array];
    __block BOOL useNextPercentForMask = NO;
    __block BOOL removeNextPercentForMask = NO;
    __block BOOL shiftMaskAfterAnimation = NO;
    __block ColumnForShredding *columnForUseAsMaskAfterAnimation = nil;
    
    // animate slices
    [UIView animateWithDuration:.5 animations:^{
        // fade out
        // decide which rows will be deleted
        for (ColumnForShredding *column in self.columnsForDeletion) {
            if (column.isDeleted) {
                if (column.percentLeft >= percent) {
                    // begin to animate slices back in
                    // animate un-shredding of the column
                    for (UIImageView *slice in column.slices) {
                        slice.alpha = 1;
                        
                        // set the transform to normal
                        slice.transform = CGAffineTransformIdentity;
                        // give it a lil shadow
                        slice.layer.shadowPath = CGPathCreateWithRect(CGRectOffset(slice.bounds, 0, 0), nil);
                        slice.layer.shadowOpacity = .5;
                        
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
            
            /*if (removeNextPercentForMask) { // need to do this for the animating back in
             [column.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
             slice.layer.shadowOpacity = 0;
             }];
             removeNextPercentForMask = NO;
             }*/
            
            if (useNextPercentForMask) {
                if (shiftMaskAfterAnimation) {
                    columnForUseAsMaskAfterAnimation = column;
                    shiftMaskAfterAnimation = NO;
                    removeNextPercentForMask = YES;
                } else {
                    // shift the mask over
                    [CATransaction begin];
                    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                    self.currentDeletionCell.layer.mask.frame = (CGRect){{column.percentLeft * noteWidth, 0}, self.currentDeletionCell.layer.mask.frame.size};
                    [CATransaction commit];
                    
                    // give it a lil shadow
                    [column.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                        slice.layer.shadowPath = CGPathCreateWithRect(CGRectOffset(slice.bounds, 0, 0), nil);
                        slice.layer.shadowOpacity = .5;
                    }];
                }
                useNextPercentForMask = NO;
            }
            
            if (!column.isDeleted && column.percentLeft < percent) {
                //[colsToRemove addObject:column];
                
                useNextPercentForMask = YES;
                
                // animate shredding of the column
                for (UIImageView *slice in column.slices) {
                    // remove any mask and set up properties
                    slice.layer.shadowPath = CGPathCreateWithRect(CGRectOffset(slice.bounds, 0, 0), nil);
                    slice.layer.shadowOpacity = (float)rand()/RAND_MAX * .8;
                    slice.alpha = 0;
                    
                    // Rotate some degrees
                    CGAffineTransform rotate = CGAffineTransformMakeRotation((float)rand()/RAND_MAX*M_PI_2 - M_PI_4);
                    
                    // Move to the left
                    CGAffineTransform translate = CGAffineTransformMakeTranslation((float)rand()/RAND_MAX * -100,(float)rand()/RAND_MAX * 100 - 50);
                    
                    // Apply them to a view
                    slice.transform = CGAffineTransformConcat(translate, rotate);
                }
                
                column.isDeleted = YES;
            }
        }
        
        if (useNextPercentForMask && !shiftMaskAfterAnimation) { // the last column was deleted
            // remove the mask
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = (CGRect){{noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
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
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = (CGRect){{columnForUseAsMaskAfterAnimation.percentLeft*noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
            [CATransaction commit];
            
            // give it a lil shadow
            [columnForUseAsMaskAfterAnimation.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                slice.layer.mask = nil;
            }];
            
        }
        
        if (percent >= 1) {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = (CGRect){{noteWidth, 0}, self.currentDeletionCell.layer.mask.frame.size};
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
    
    [self shredVisibleNoteByPercent:0.0 completion:^{
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
