//
//  NoteCollectionViewController+Shredding.h
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewController.h"

@interface NoteCollectionViewController (Shredding)

- (void) prepareVisibleNoteForShredding;
- (void) shredVisibleNoteByPercent:(float)percent completion:(void (^)(void))completionBlock;
- (void) cancelShredForVisibleNote;

@end
