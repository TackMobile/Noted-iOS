//
//  NoteCollectionViewController.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteCollectionViewCell.h"

typedef NS_ENUM(NSInteger, NTDPageDeletionDirection) {
    NTDPageDeletionDirectionLeft = 0,
    NTDPageDeletionDirectionRight
};

@interface NoteCollectionViewController : UICollectionViewController

@property (nonatomic, strong, readonly) NoteCollectionViewCell *visibleCell;

@property (nonatomic) int deletedNoteVertSliceCount;
@property (nonatomic) int deletedNoteHorizSliceCount;
@property (nonatomic, strong) NSMutableArray *columnsForDeletion;
@property (nonatomic, strong) NoteCollectionViewCell *currentDeletionCell;
@property (nonatomic) NTDPageDeletionDirection deletionDirection;

@end
