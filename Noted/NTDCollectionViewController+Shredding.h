//
//  NoteCollectionViewController+Shredding.h
//  Noted
//
//  Created by Nick Place on 7/1/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController.h"

@interface NTDCollectionViewController (Shredding)

- (void) prepareVisibleNoteForShredding;
- (void) shredVisibleNoteByPercent:(float)percent completion:(void (^)(void))completionBlock;
- (void) cancelShredForVisibleNote;

@end
