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

@interface StackViewController : UIViewController

- (void)updateForTableView:(UITableView *)tableView selectedIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (UIView *)viewForIndexOffsetFromTop:(NSInteger)offset;
- (void)setShadowsOnHighNotes;
- (void)resetToExpanded;

@end
