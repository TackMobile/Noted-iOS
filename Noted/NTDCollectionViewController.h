//
//  NoteCollectionViewController.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDCollectionViewCell.h"
#import "NTDOptionsViewController.h"
#import "NTDDeletedNotePlaceholder.h"
#import "NTDPagingCollectionViewLayout.h"

typedef NS_ENUM(NSInteger, NTDDeletionDirection) {
    NTDDeletionDirectionNoDirection = 0,
    NTDDeletionDirectionLeft,
    NTDDeletionDirectionRight
};

@class NTDListCollectionViewLayout, NTDPagingCollectionViewLayout;
@protocol NTDPagingCollectionViewLayoutDelegate;

@interface NTDCollectionViewController : UICollectionViewController <NTDOptionsViewDelegate, NTDPagingCollectionViewLayoutDelegate>

@property (nonatomic, strong, readonly) NTDCollectionViewCell *visibleCell;

/* Shredding */
@property (nonatomic) int deletedNoteVertSliceCount;
@property (nonatomic) int deletedNoteHorizSliceCount;
@property (nonatomic, strong) NSMutableArray *columnsForDeletion;
@property (nonatomic, strong) NTDCollectionViewCell *currentDeletionCell;
@property (nonatomic) NTDDeletionDirection deletionDirection;

/* Walkthrough */
//TODO rename removeCard & twoFingerPan
//TODO organize GRs according to layout
@property (nonatomic, strong) UIPanGestureRecognizer *removeCardGestureRecognizer, *panCardGestureRecognizer,
*twoFingerPanGestureRecognizer, *panCardWhileViewingOptionsGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *selectCardGestureRecognizer, *tapCardWhileViewingOptionsGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchToListLayoutGestureRecognizer;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) NSMapTable *tokenRecognizerTable;
@property (nonatomic, strong) NTDListCollectionViewLayout *listLayout;
@property (nonatomic, strong) NTDPagingCollectionViewLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) dispatch_group_t note_refresh_group;

- (void)reloadNotes;
- (void)updateLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated;
- (void)restoreDeletedNote;
@end
