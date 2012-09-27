//
//  StackViewController.h
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^animationCompleteBlock)();

@class NoteDocument;
@class NoteListViewController;

@interface StackViewController : UIViewController

- (void)expandRowsForViewController:(NoteListViewController *)noteList selectedIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (UIView *)viewAtIndex:(NSInteger)offset;
- (void)setShadowsOnHighNotes;
- (void)resetToExpanded;
- (void)generateCells;

@end
