//
//  NoteCollectionViewController.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDCollectionViewCell.h"
#import "NTDListCollectionViewLayout.h"
#import "NTDPagingCollectionViewLayout.h"

typedef NS_ENUM(NSInteger, NTDPageDeletionDirection) {
    NTDPageDeletionDirectionLeft = 0,
    NTDPageDeletionDirectionRight
};

@interface NTDCollectionViewController : UICollectionViewController

@property (nonatomic, strong, readonly) NSIndexPath *visibleCardIndexPath;
@property (nonatomic, strong, readonly) NTDCollectionViewCell *visibleCell;

@property (nonatomic, strong) NTDListCollectionViewLayout *listLayout;
@property (nonatomic, strong) NTDPagingCollectionViewLayout *pagingLayout;

@property (nonatomic) int deletedNoteVertSliceCount;
@property (nonatomic) int deletedNoteHorizSliceCount;
@property (nonatomic, strong) NSMutableArray *columnsForDeletion;
@property (nonatomic, strong) NTDCollectionViewCell *currentDeletionCell;
@property (nonatomic) NTDPageDeletionDirection deletionDirection;

@end
