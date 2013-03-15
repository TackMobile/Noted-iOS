//
//  StackViewController.h
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DEBUG_ANIMATIONS    0
#define DEBUG_VIEWS         0

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
- (void)prepareForCollapse;
- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent;
- (void)finishCollapse:(void(^)())complete;
- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (void)openSingleNoteForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (void)resetToExpanded:(void(^)())completion;
- (void)updateNoteText;
- (BOOL)needsAnimation;

@end

@protocol AnimationStackDelegate <NSObject>

- (int)selectedIndexPathForStack;

@end
