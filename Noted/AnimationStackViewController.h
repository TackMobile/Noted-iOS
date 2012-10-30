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

@protocol AnimationStackDelegate;

@interface AnimationStackViewController : UIViewController

@property (nonatomic, assign) StackState state;
@property (nonatomic, assign) BOOL sectionZeroRowOneVisible;
@property (nonatomic, strong) NSArray *noteViews;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) id <AnimationStackDelegate> delegate;

- (float)finalYOriginForCurrentNote;
- (UIView *)currentNote;

- (void)prepareForAnimationState:(StackState)state withParentView:(UIView *)view;

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent;
- (void)finishCollapse:(void(^)())complete;

- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (void)resetToExpanded:(void(^)())completion;

- (void)updateNoteText;

@end

@protocol AnimationStackDelegate <NSObject>

- (int)selectedIndexPathForStack;

@end
