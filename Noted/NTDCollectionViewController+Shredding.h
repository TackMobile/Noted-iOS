//
//  NoteCollectionViewController+Shredding.h
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController.h"

@class NTDCollectionViewLayoutAttributes;

@interface NTDCollectionViewController (Shredding)

- (void) prepareVisibleNoteForShredding;
- (void) shredVisibleNoteByPercent:(float)percent completion:(void(^)(void))completionBlock;
- (void) cancelShredForVisibleNote;
- (void) cancelShredForVisibleNoteWithCompletionBlock:(void(^)(void))completionBlock;
- (void)restoreShreddedNote:(NTDDeletedNotePlaceholder *)restoredNote;

@end
