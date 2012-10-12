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

@property (nonatomic, strong) NSArray *noteViews;

- (float)finalYOriginForCurrentNote;
- (UIView *)currentNote;

- (void)prepareForCollapseAnimationForView:(UIView *)view;
- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent;
- (void)finishCollapse:(void(^)())complete;

- (void)prepareForExpandAnimationForView:(UIView *)view;
- (void)animateOpenForController:(NoteListViewController *)noteList indexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock;
- (void)resetToExpanded:(void(^)())completion;

- (void)update;
- (void)updateNoteText;

@end
