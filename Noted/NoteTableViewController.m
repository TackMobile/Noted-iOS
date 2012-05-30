//
//  NoteTableViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteTableViewController.h"
#import "TransformableNoteCell.h"
#import "NoteTableGestureRecognizer.h"
#import "UIColor+HexColor.h"

@interface NoteTableViewController () <NoteTableGestureEditingRowDelegate, NoteTableGestureAddingRowDelegate, NoteTableGestureMoveRowDelegate>
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NoteTableGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;
@end

@implementation NoteTableViewController
@synthesize rows;
@synthesize tableViewRecognizer;
@synthesize grabbedObject;

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // In this example, we setup self.rows as datasource
    self.rows = [NSMutableArray arrayWithObjects:
                 @"Swipe to the right to complete",
                 @"Swipe to left to delete",
                 @"Drag down to create a new cell",
                 @"Pinch two rows apart to create cell",
                 @"Long hold to start reorder cell",
                 nil];
    
    
    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
    
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight       = NORMAL_CELL_FINISHING_HEIGHT;}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rows count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSObject *object = [self.rows objectAtIndex:indexPath.row];
    UIColor *backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.12 * indexPath.row / [self tableView:tableView numberOfRowsInSection:indexPath.section]];
    if ([object isEqual:ADDING_CELL]) {
        NSString *cellIdentifier = nil;
        TransformableNoteCell *cell = nil;
        
        // IndexPath.row == 0 is the case we wanted to pick the pullDown style
        if (indexPath.row == 0) {
            cellIdentifier = @"PullDownTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableNoteCell transformableNoteCellWithStyle:TransformableNoteCellStylePullDown
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = UITextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pulling...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
            
        } else {
            // Otherwise is the case we wanted to pick the pullDown style
            cellIdentifier = @"UnfoldingTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableNoteCell transformableNoteCellWithStyle:TransformableNoteCellStyleUnfolding
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = UITextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pinching...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
        }
        
    } else {
        
        static NSString *cellIdentifier = @"MyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", (NSString *)object];
        cell.detailTextLabel.text = @" ";
        if ([object isEqual:DONE_CELL]) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.contentView.backgroundColor = [UIColor darkGrayColor];
        } else if ([object isEqual:DUMMY_CELL]) {
            cell.textLabel.text = @"";
            cell.contentView.backgroundColor = [UIColor clearColor];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.contentView.backgroundColor = backgroundColor;
        }
        return cell;
    }
    
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NORMAL_CELL_FINISHING_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"tableView:didSelectRowAtIndexPath: %@", indexPath);
}

#pragma mark -
#pragma mark JTTableViewGestureAddingRowDelegate

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows insertObject:ADDING_CELL atIndex:indexPath.row];
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:@"Added!"];
    TransformableNoteCell *cell = (id)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    cell.finishedHeight = NORMAL_CELL_FINISHING_HEIGHT;
    cell.textLabel.text = @"Just Added!";
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows removeObjectAtIndex:indexPath.row];
}

#pragma mark JTTableViewGestureEditingRowDelegate

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer didEnterEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    UIColor *backgroundColor = nil;
    switch (state) {
        case NoteCellEditingStateMiddle:
            backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.12 * indexPath.row / [self tableView:self.tableView numberOfRowsInSection:indexPath.section]];
            break;
        case NoteCellEditingStateRight:
            backgroundColor = [UIColor greenColor];
            break;
        default:
            backgroundColor = [UIColor darkGrayColor];
            break;
    }
    cell.contentView.backgroundColor = backgroundColor;
    if ([cell isKindOfClass:[TransformableNoteCell class]]) {
        ((TransformableNoteCell *)cell).tintColor = backgroundColor;
    }
}

// This is needed to be implemented to let our delegate choose whether the panning gesture should work
- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer commitEditingState:(NoteCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = gestureRecognizer.tableView;
    [tableView beginUpdates];
    if (state == NoteCellEditingStateLeft) {
        // An example to discard the cell at JTTableViewCellEditingStateLeft
        [self.rows removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (state == NoteCellEditingStateRight) {
        // An example to retain the cell at commiting at JTTableViewCellEditingStateRight
        [self.rows replaceObjectAtIndex:indexPath.row withObject:DONE_CELL];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]
    }
    [tableView endUpdates];
    
    // Row color needs update after datasource changes, reload it.
    [tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:indexPath afterDelay:NoteTableRowAnimationDuration];
}

#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.rows objectAtIndex:indexPath.row];
    [self.rows replaceObjectAtIndex:indexPath.row withObject:DUMMY_CELL];
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id object = [self.rows objectAtIndex:sourceIndexPath.row];
    [self.rows removeObjectAtIndex:sourceIndexPath.row];
    [self.rows insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(NoteTableGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:self.grabbedObject];
    self.grabbedObject = nil;
}

@end