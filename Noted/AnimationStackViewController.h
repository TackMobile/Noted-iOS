//
//  StackViewController.h
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kTableView,
    kNoteStack
} StackState;

typedef void(^animationCompleteBlock)();

@class NoteDocument;
@class NoteListViewController;

@interface AnimationStackViewController : UIViewController

@property (nonatomic, strong) NSArray *noteViews;
@property (nonatomic, strong) UITableView *tableView;

- (float)finalYOriginForCurrentNote;
- (UIView *)currentNote;

- (void)prepareForAnimationState:(StackState)state withParentView:(UIView *)view;

//- (void)prepareForCollapseAnimationForView:(UIView *)view;
- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent;
- (void)finishCollapse:(void(^)())complete;

//- (void)prepareForExpandAnimationForView:(UIView *)view offsetForSectionZero:(BOOL)offset;
- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (void)resetToExpanded:(void(^)())completion;

- (void)update;
- (void)updateNoteText;

@end
