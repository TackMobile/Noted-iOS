//
//  NoteTableGestureRecognizer.h
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
   NoteCellEditingStateMiddle,
    NoteCellEditingStateLeft,
    NoteCellEditingStateRight,
} NoteCellEditingState;

extern CGFloat const NoteTableCommitEditingRowDefaultLength;

// RowAnimationDuration is decided to be as close as the internal settings of UITableViewRowAnimation duration
extern CGFloat const NoteTableRowAnimationDuration;

@protocol NoteTableGestureAddingRowDelegate;
@protocol NoteTableGestureEditingRowDelegate;
@protocol NoteTableGestureMoveRowDelegate;

@interface NoteTableGestureRecognizer : NSObject <UITableViewDelegate>
@property (readonly,nonatomic, assign) UITableView *tableView;
+(NoteTableGestureRecognizer*)gestureRecognizerWithTableView:(UITableView*)tableView delegate:(id)delegate;

@end

#pragma mark -

// Conform to GestureAddingRowDelegate to enable features
// - drag down to add cell
// - pinch to add cell
@protocol NoteTableGestureAddingRowDelegate <NSObject>

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSIndexPath *)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer heightForCommittingRowAtIndexPath:(NSIndexPath *)indexPath;


@end


// Conform to GestureEditingRowDelegate to enable features
// - swipe to edit cell
@protocol NoteTableGestureEditingRowDelegate <NSObject>

// Panning (required)
- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer didEnterEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer commitEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;

@end


// Conform to GestureMoveRowDelegate to enable features
// - long press to reorder cell
@protocol NoteTableGestureMoveRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@interface UITableView (NoteTableGestureDelegate)

- (NoteTableGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;

// Helper methods for updating cell after datasource changes
- (void)reloadVisibleRowsExceptIndexPath:(NSIndexPath *)indexPath;

@end