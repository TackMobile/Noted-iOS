//
//  NoteListViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteListViewController.h"
#import "AppDelegate.h"
#import "ApplicationModel.h"
#import "NoteEntryCell.h"
#import "NoteEntry.h"
#import "NoteDocument.h"
#import "UIColor+HexColor.h"
#import "NoteStackViewController.h"
#import "NoteStackViewController.h"
#import "FileStorageState.h"
#import "CloudManager.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+position.h"
#import "AnimationStackViewController.h"
#import "WalkThroughViewController.h"

NSString *const kEditingNoteIndex =         @"editingNoteIndex";
static const NSUInteger kShadowViewTag =    56;

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200
#define kFingerTipsTag      576

#define DISABLE_NEW_CELL    NO

typedef enum {
    kNoteItems
} NoteListSections;

@interface NoteListViewController ()
{
    NoteEntryCell *_deletedCell;
    BOOL _viewingNoteStack;
    float yOffset;
    NSUInteger _previousRowCount;
    
    BOOL _scrolling;
    BOOL _dragging;
    BOOL _lastRowVisible;
    BOOL _lastRowWasVisible;
    BOOL _shouldAutoShowNote;
    int _noteCount;
    UIColor *_lastRowColor;
    
    NoteEntryCell *_lastRow;
    NSIndexPath *_lastIndexPath;
    NSIndexPath *_selectedIndexPath;
    AnimationStackViewController *_stackViewController;
    UITextView *_lastRowFullText;
    
    NSDictionary *_currentTourStep;
    
    NSTimer *walkthroughGestureTimer;

}


@end

@implementation NoteListViewController

@synthesize tableView,lastRowExtenderView;
@synthesize selectedIndexPath=_selectedIndexPath;

- (id)init
{
    self = [super initWithNibName:@"NoteListViewController" bundle:nil];
    if (self){
        _noteCount = 0;
        _previousRowCount = 0;
        _shouldAutoShowNote = NO;
        _viewingNoteStack = NO;
        _scrolling = NO;
        _dragging = NO;
        
        // pullToCreate
        dragToCreateController = [[DragToCreateViewController alloc] init];
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)deleteAll
{
    for (NSIndexPath *ip in [self.tableView indexPathsForVisibleRows]) {
        [[ApplicationModel sharedInstance] deleteNoteEntryAtIndex:ip.row withCompletionBlock:^{
            //
        }];
    }
}

- (BOOL)hasData
{
    return _noteCount > 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    self.tableView.backgroundView   = backgroundView;
    [self.tableView setBackgroundColor:[UIColor colorWithHexString:@"808080"]];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight        = 60;
    self.view.layer.cornerRadius    = 6.0;
    self.tableView.backgroundView   = nil;
    self.view.clipsToBounds = YES;
       
    CGRect pullToCreateRect = (CGRect){
        {0, dragToCreateController.view.frame.size.height*(-1)},
        dragToCreateController.view.frame.size
    };
    
    UIView *dragView = dragToCreateController.view;
    [dragView setFrame:pullToCreateRect];
    [dragView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
    [self.tableView insertSubview:dragView atIndex:0];
    
    [self handleNotifications];

}

- (void)handleNotifications
{
    [[NSNotificationCenter defaultCenter] addObserverForName:kNoteListChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        
        [self listDidUpdate];
        [self.tableView reloadData];
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"didToggleStatusBar" object:nil queue:nil usingBlock:^(NSNotification *note){
        
        CGRect newFrame =  [[UIScreen mainScreen] applicationFrame];
        [self.view setFrame:newFrame];
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kWalkThroughStepBegun object:nil queue:nil usingBlock:^(NSNotification *note){
        if ([[note.userInfo objectForKey:kStepViewControllerClass] isEqual:NSStringFromClass([self class])]) {
            _currentTourStep = note.userInfo;
            [self performSelector:@selector(beginTouchDemoAnimation) withObject:nil afterDelay:1.2];
        } else {
            _currentTourStep = nil;
            [self endTouchDemoAnimation];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kWalkThroughExited object:nil queue:nil usingBlock:^(NSNotification *note){
        _currentTourStep = nil;
        [self endTouchDemoAnimation];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
        if (_noteCount == 0) {
            [[ApplicationModel sharedInstance] refreshNotes];
        }
    }];
}

- (void)createAndShowFirstNote
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    NSString *text = nil;
    if (![FileStorageState isFirstUse]) {
        text = @"Take note";
    } else {
        text = @"Welcome to Noted, a gesture-driven notepad. Learn how to use it by starting the tour below, or skip it if you're feeling adventurous.";
    }
    
    [model createNoteWithText:text andCompletionBlock:^(NoteEntry *entry){
        // new note entry should always appear at row 0, right?
        NSIndexPath *freshIndexPath = [NSIndexPath indexPathForRow:0 inSection:kNoteItems];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:freshIndexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        model.selectedNoteIndex = 0;
        [_stackViewController openSingleNoteForIndexPath:freshIndexPath completion:^(){
            
            NoteEntry *noteEntry = [model noteAtIndex:freshIndexPath.row];
            if (!noteEntry.adding) {
                [self showNoteStackForSelectedRow:freshIndexPath.row animated:NO];
                
            }
        }];

    }];

    _noteCount = model.currentNoteEntries.count;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self listDidUpdate];
       
    _viewingNoteStack = YES;
}

- (void)tourCheck:(int)stepNum
{
    if (_currentTourStep) {
        int index = [[_currentTourStep objectForKey:@"index"] intValue];
        if (index == stepNum) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWalkThroughStepComplete object:nil userInfo:_currentTourStep];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _viewingNoteStack = NO;
    if (_viewingNoteStack && yOffset>0) {
        
        yOffset = 0.0;
        if ([_selectedIndexPath isEqual:[[self.tableView indexPathsForVisibleRows] lastObject]]) {
            [self.tableView scrollToRowAtIndexPath:_selectedIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        } else {
            [self.tableView scrollToRowAtIndexPath:_selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }
    
    if (![FileStorageState isFirstUse]) {
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[ApplicationModel sharedInstance] refreshNotes];
        });
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _noteCount = [[[ApplicationModel sharedInstance] currentNoteEntries] count];
    
    if (_viewingNoteStack) {
        CGRect frame = [self.tableView rectForRowAtIndexPath:_selectedIndexPath];
        
        BOOL rowZeroVisible = [self rowZeroVisible];
        if (!rowZeroVisible){
            CGPoint offset = CGPointMake(0.0, frame.origin.y-yOffset);
            [self.tableView setContentOffset:offset animated:NO];
        }
    }
        
    [self.tableView reloadData];
    if (_stackViewController) {
        [self setStackState];
    }
}

- (int)selectedIndexPathForStack
{
    return _selectedIndexPath.row;
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)listDidUpdate
{
    NSMutableOrderedSet *notes = [[ApplicationModel sharedInstance] currentNoteEntries];
    _noteCount = notes.count;
    
    if (_noteCount == 0) {
        [self performSelector:@selector(createAndShowFirstNote) withObject:nil afterDelay:0.5];
    }
    
    if (_noteCount>0) {

        _lastRowColor = [(NoteEntry *)[notes lastObject] noteColor];
        [self updateBackgroundColorForScrollview:self.tableView];
        
        if (!_stackViewController) {
            _stackViewController = [[AnimationStackViewController alloc] init];
            _stackViewController.tableView = self.tableView;
            _stackViewController.delegate = self;
        }
        
        int64_t delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            NSArray *allVisibleRows = [self.tableView indexPathsForVisibleRows];
            for (NSIndexPath *indexPath in allVisibleRows) {
                if (indexPath.section == kNoteItems) {
                    [_stackViewController setSectionZeroRowOneVisible:[self rowZeroVisible]];
                    [self setStackState];
                    break;
                }
            }
        });
        
        [self.tableView reloadData];
    }
}

- (void)indexDidChange
{
    NSMutableOrderedSet *notes = [[ApplicationModel sharedInstance] currentNoteEntries];
    if (_noteCount != notes.count) {
        [self listDidUpdate];
    }
    
    _selectedIndexPath = [NSIndexPath indexPathForRow:[ApplicationModel sharedInstance].selectedNoteIndex inSection:kNoteItems];
    [self.tableView reloadData];
    if ([_selectedIndexPath isEqual:[[self.tableView indexPathsForVisibleRows] lastObject]]) {
        [self.tableView selectRowAtIndexPath:_selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    } else {
        [self.tableView selectRowAtIndexPath:_selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 2.0;
}

#pragma mark - Table View methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _noteCount-1) {
        NSInteger totalSize = _noteCount * 66;
            
        CGFloat calculatedCellSize = 66.0;
            
        if (totalSize < self.view.bounds.size.height) {
            calculatedCellSize = self.view.bounds.size.height - totalSize;
        }
            
        return calculatedCellSize;
    }
    
    return 66;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _noteCount;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ApplicationModel *model = [ApplicationModel sharedInstance];
        
        NSLog(@"Vorher gibt %i model currentNoteEntries %s",_noteCount,__PRETTY_FUNCTION__);
        [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:^{
            //
        }];
        _noteCount = model.currentNoteEntries.count;
        NSLog(@"Es gibt %i model currentNoteEntries, %s",_noteCount,__PRETTY_FUNCTION__);
        
        NSMutableOrderedSet *notes = [[ApplicationModel sharedInstance] currentNoteEntries];
        _noteCount = notes.count;
        
        [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellId = @"NoteCellId";
    static UIColor *blueRowBgColor = nil;
    
    if (blueRowBgColor==nil) {
        blueRowBgColor = [UIColor colorWithRed:0.05f green:0.54f blue:0.82f alpha:1.00f];
    }
    
    NoteEntryCell *noteEntryCell = [tableView dequeueReusableCellWithIdentifier:CellId];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
    
    if (noteEntryCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
        noteEntryCell = [topLevelObjects objectAtIndex:0];
        noteEntryCell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        
        int prevIndex = indexPath.row-1;
        if (prevIndex>=0) {
            NoteEntry *previous = [model.currentNoteEntries objectAtIndex:prevIndex];
            [noteEntryCell setCornerColorsWithPrevNoteEntry:previous.noteColor];
        } else {
            [noteEntryCell setCornerColorsWithPrevNoteEntry:[UIColor colorWithHexString:@"808080"]];
        }
        
#ifdef DEBUG
        UILabel *fileURLLabel = (UILabel *)[noteEntryCell viewWithTag:889];
        [fileURLLabel setHidden:NO];
        NSString *url = noteEntry.fileURL.lastPathComponent;
        fileURLLabel.text = [url substringToIndex:15];
#endif
    }
    
    if (noteEntry.adding) {
        [noteEntryCell setSubviewsBgColor:[UIColor lightGrayColor]];
        
        [self delayedCall:1.0 withBlock:^{
            [UIView animateWithDuration:0.5
                             animations:^{
                                 noteEntryCell.contentView.backgroundColor = noteEntry.noteColor;
                             }
                             completion:nil];
        }];
        
    } else {
        [noteEntryCell setSubviewsBgColor:noteEntry.noteColor];
    }
    
    noteEntryCell.subtitleLabel.text = noteEntry.title;
    
    BOOL isLastNote = indexPath.row == _noteCount-1 ? YES : NO;
    UITextView *textView = (UITextView *)[noteEntryCell.contentView viewWithTag:FULL_TEXT_TAG];
    if (textView && !isLastNote) {
        [textView removeFromSuperview];
    }
    
    noteEntryCell.relativeTimeText.text = [noteEntry relativeDateString];
    
    return noteEntryCell;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NoteEntryCell *noteEntryCell = (NoteEntryCell *)cell;
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
    
    //NSLog(@"NoteList::willDisplayCell:: %i", indexPath.row);
    
    UIColor *bgColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
    int index = [[UIColor getNoteColorSchemes] indexOfObject:bgColor];
    if (index == NSNotFound) {
        index = 0;
    }
    if (index >= 4) {
        [noteEntryCell.subtitleLabel setTextColor:[UIColor whiteColor]];
        [noteEntryCell.relativeTimeText setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    } else {
        [noteEntryCell.subtitleLabel setTextColor:[UIColor colorWithHexString:@"333333"]];
        [noteEntryCell.relativeTimeText setTextColor:[UIColor colorWithWhite:0.2 alpha:0.5]];
    }
    
    UIView *shadow = [cell viewWithTag:kShadowViewTag];

    if (indexPath.row == _noteCount-1) {
        
        [shadow setHidden:YES];
        [noteEntryCell setSubviewsBgColor:_lastRowColor];
        
        // Create a CGSize variable that represents the MAXIMUM size the label can be.
        CGSize maximumLabelSize = CGSizeMake(noteEntryCell.subtitleLabel.frame.size.width, noteEntryCell.frame.size.height - 14 - noteEntryCell.subtitleLabel.frame.origin.y);
        
        //NSLog(@"%i::maximumLabelSize: %@", indexPath.row, NSStringFromCGSize(maximumLabelSize));
        
        NSString *actualNoteText = noteEntry.title;
        
        // Create a CGSize variable that represents 
        CGSize expectedLabelSize = [actualNoteText sizeWithFont:noteEntryCell.subtitleLabel.font constrainedToSize:maximumLabelSize lineBreakMode:noteEntryCell.subtitleLabel.lineBreakMode];
        
        //NSLog(@"%i::expectedLabelSize: %@", indexPath.row, NSStringFromCGSize(expectedLabelSize));
        
        CGRect updatedFrame = [noteEntryCell.subtitleLabel frame];
        updatedFrame.size.height = expectedLabelSize.height;
        
        //NSLog(@"%i::updatedFrame: %@", indexPath.row, NSStringFromCGSize(maximumLabelSize));
        
        [noteEntryCell.subtitleLabel setNumberOfLines:0];
        [noteEntryCell.subtitleLabel setFrame:updatedFrame];
    } else {
        noteEntryCell.subtitleLabel.numberOfLines = 3;
        [noteEntryCell.subtitleLabel sizeToFit];
    }
}

- (void)didDeleteCellWithIndexPath:(NoteEntryCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:^{
        //
    }];
    _noteCount = model.currentNoteEntries.count;
    NSLog(@"%i",_noteCount);
    
    NSMutableOrderedSet *notes = [[ApplicationModel sharedInstance] currentNoteEntries];
    _noteCount = notes.count;
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath { //random comment
  
    //UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
    /*
     BOOL editing = cell.editing;
     if (editing) {
     //[cell setEditing:NO animated:YES];
     return;
     }
     */
    
    _selectedIndexPath = indexPath;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
   
    model.selectedNoteIndex = indexPath.row;
    [_stackViewController animateOpenForIndexPath:indexPath completion:^(){
        
        NoteEntry *noteEntry = [model noteAtIndex:indexPath.row];
        if (!noteEntry.adding) {
            [self showNoteStackForSelectedRow:indexPath.row animated:NO];
        }
    }];
    
    _viewingNoteStack = YES;
}

- (void)verifyFullTextParent
{
    if (!_lastRowFullText) {
        return;
    }
    
    UITableViewCell *parentCell = (UITableViewCell *)_lastRowFullText.superview.superview;
    if (![parentCell isEqual:[self.tableView visibleCells].lastObject]) {
        [_lastRowFullText removeFromSuperview];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _dragging = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
     _dragging = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([ApplicationModel sharedInstance].currentNoteEntries.count ==0) {
        return;
    }
    
    [self endTouchDemoAnimation];
    
    if (scrollView.contentOffset.y < 0) {
        if (_dragging) {
            [dragToCreateController scrollingWithYOffset:scrollView.contentOffset.y];
        } 
    }
    
    [self updateBackgroundColorForScrollview:scrollView];
    
    [_stackViewController setSectionZeroRowOneVisible:[self rowZeroVisible]];

    _scrolling = YES;
}

- (void)updateBackgroundColorForScrollview:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 0;
    if(y > h + reload_distance || _noteCount == 1) {
        self.tableView.backgroundColor = _lastRowColor;
    } else {
        self.tableView.backgroundColor = [UIColor colorWithHexString:@"808080"];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _scrolling = NO;
    
    if (!decelerate) {
        [self setStackState];
    } 
    
    if (scrollView.contentOffset.y < 0) {
        if ( ABS(scrollView.contentOffset.y) >= dragToCreateController.view.frame.size.height) {
            [dragToCreateController setDragging:NO];
            [self makeNewNote];
        }
    }
}

- (void)makeNewNote
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model createNoteWithCompletionBlock:^(NoteEntry *entry){
        
    }];
    _noteCount = model.currentNoteEntries.count;
    
    [dragToCreateController commitNewNoteCreation:^{
        NSIndexPath *freshIndexPath = [NSIndexPath indexPathForRow:0 inSection:kNoteItems];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:freshIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self showNoteStackForSelectedRow:0 animated:NO];
        [self.tableView setFrameY:0.0];
    }];
    
    [self performSelector:@selector(slideOffTableView) withObject:nil afterDelay:0.0];
}

- (void)slideOffTableView
{
    
    //[self.tableView setScrollEnabled:NO];
    [UIView animateWithDuration:0.7
                     animations:^{
                         [self.tableView setFrameY:CGRectGetMaxY(self.view.frame)];
                     }
                     completion:^(BOOL finished){
                         [self.tableView setFrameY:0.0];
                         //[self.tableView setScrollEnabled:YES];
                         [self.tableView setContentOffset:CGPointMake(0.0, 0.0)];
                     }];
}

-(void)openLastNoteCreated:(NSTimer *)timer { // called by a timer
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kNoteItems]];
}

- (void)setStackState
{
    if (_stackViewController.state != kTableView) {
        [_stackViewController setState:kTableView];
        [self.view addSubview:_stackViewController.view];
        [_stackViewController.view setFrameX:-320.0];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _scrolling = NO;
    
    if (_lastRowWasVisible) {
        //self.tableView.backgroundColor = [UIColor whiteColor];
        _lastRowWasVisible = NO;
    }

    [self setStackState];
    /*
     NSLog(@"frame %@",NSStringFromCGRect(self.tableView.frame));
     NSLog(@"content size %@",NSStringFromCGSize(self.tableView.contentSize));
     NSLog(@"");
     */
}

/*
 - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
 {
 return YES;
 }
 */

- (NSString *)displayTitleForNoteEntry:(NoteEntry *)entry
{
    NSString *title = nil;
    if (!IsEmpty([entry text]) && ![entry.text isEqualToString:@"\n"]){
        title = [entry text];
        if ([entry.text hasPrefix:@"\n"]) {
            title = [entry title];
        }
    } else {
        title = @"...";
    }
    
    return title;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if (interfaceOrientation==UIInterfaceOrientationPortrait ) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Stack VC callback

- (void)showNoteStackForSelectedRow:(NSUInteger)row animated:(BOOL)animated
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:model.selectedNoteIndex] forKey:kEditingNoteIndex];
    
    _viewingNoteStack = YES;
    NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithDismissalBlock:^(float currentNoteOffset){
        _selectedIndexPath = [NSIndexPath indexPathForRow:[ApplicationModel sharedInstance].selectedNoteIndex inSection:kNoteItems];
        yOffset = currentNoteOffset;
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kEditingNoteIndex];
        _shouldAutoShowNote = NO;
        
    } andStackVC:_stackViewController];
    stackViewController.delegate = self;
    [self presentViewController:stackViewController animated:animated completion:^{
        [self tourCheck:walkThroughStepPullToCreate];
    }];
}

- (void)debugView:(UIView *)view description:(NSString *)desc line:(int)line
{
    if (!view) {
        NSLog(@"%@ doesn't exist!",desc);
    }
    NSLog(@"view: %p",view);
    NSLog(@"view class: %@\n\n",[view.superview class]);
    NSLog(@"\n\n%@ is hidden: %s",desc,view.isHidden ? "yes" : "no");
    NSLog(@"alpha: %f",view.alpha);
    NSLog(@"frame: %@",NSStringFromCGRect(view.frame));
    NSLog(@"superview: %@",view.superview);
    NSLog(@"superview class: %@\n\n",[view.superview class]);
    
}

- (BOOL)rowZeroVisible
{
    return [self isVisibleRow:0 inSection:kNoteItems];
}

- (BOOL)isVisibleRow:(int)row inSection:(int)section
{
    if (_noteCount == 0) {
        return NO;
    } else if (_noteCount == 1) {
        return YES;
    }
    
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
    cellRect = [self.tableView convertRect:cellRect toView:self.tableView.superview];
    BOOL completelyVisible = CGRectIntersectsRect(self.tableView.frame, cellRect);
    
    return completelyVisible;
}

- (void)delayedCall:(float)delay withBlock:(void(^)())block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        block();
    });
}

#pragma mark Walk through

- (void)beginTouchDemoAnimation
{
    [self endTouchDemoAnimation];
    
    walkthroughGestureTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(runGestureDemoForWalkthroughStep:) userInfo:[_currentTourStep objectForKey:@"index"] repeats:YES];
    [walkthroughGestureTimer fire];
}

- (void)endTouchDemoAnimation
{
    if (walkthroughGestureTimer) {
        [walkthroughGestureTimer invalidate];
        walkthroughGestureTimer = nil;
    }
    
    [[self.view viewWithTag:kFingerTipsTag] removeFromSuperview];
}

- (void)runGestureDemoForWalkthroughStep:(NSTimer *)timer
{
    NSNumber *step = timer.userInfo;
    int stepNum = step.intValue;
    
    float width = 60.0;
    float circleRadius = 25.0;
    
    UIView *container = [self.view viewWithTag:kFingerTipsTag];
    if (container) {
        [container removeFromSuperview];
    }
    
    container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 60.0)];;
    [container setTag:kFingerTipsTag];
    
    CGRect viewFrame = self.view.frame;
    
    UIImageView *circle1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fingertip"]];
    
    switch (stepNum) {
        case walkThroughStepPullToCreate:
        {
            [self.view addSubview:container];
            [circle1 setFrame:CGRectMake(0.0, 0.0, circleRadius, circleRadius)];
            [container setFrame:CGRectMake((viewFrame.size.width - container.frame.size.width)*0.5, 15.0, circleRadius, circleRadius)];
            float yTranslate = viewFrame.size.height - 185.0;
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [container setFrameY:yTranslate];
                             }
                             completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.5 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState
                                                  animations:^{
                                                      [container setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
                                                      [container setAlpha:0.0];
                                                  }
                                                  completion:^(BOOL finished){
                                                      [container removeFromSuperview];
                                                  }];
                                 
                             }];
        }
            break;
        
        default:
            return;
            break;
    }
    
    [container addSubview:circle1];
    
}



@end
