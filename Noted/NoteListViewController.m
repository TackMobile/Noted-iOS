//
//  NoteListViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteListViewController.h"
#import "ApplicationModel.h"
#import "NoteEntryCell.h"
#import "NoteEntry.h"
#import "NoteDocument.h"
#import "UIColor+HexColor.h"
#import "NoteStackViewController.h"
#import "NoteStackViewController.h"
#import "NewNoteCell.h"
#import "FileStorageState.h"
#import "CloudManager.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+position.h"
#import "AnimationStackViewController.h"

NSString *const kEditingNoteIndex = @"editingNoteIndex";
static const NSUInteger kShadowViewTag = 56;

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200
#define DISABLE_NEW_CELL    NO

typedef enum {
    kNew,
    kNoteItems
} NoteListSections;

@interface NoteListViewController ()
{
    NoteEntryCell *_deletedCell;
    BOOL _viewingNoteStack;
    float yOffset;
    NSUInteger _previousRowCount;
    
    BOOL _scrolling;
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
        
        // pullToCreate
        if (DRAG_TO_CREATE) {
            dragToCreateController = [[DragToCreateViewController alloc] initWithNibName:@"DragToCreateViewController" bundle:nil];
        }
        
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    self.tableView.backgroundView   = backgroundView;
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight        = 60;
    self.view.layer.cornerRadius    = 6.0;
    self.tableView.backgroundView   = nil;
    self.view.clipsToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNoteListChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        
        [self listDidUpdate];
        [self.tableView reloadData];
    }];
    
    if (DRAG_TO_CREATE) {
        CGRect pullToCreateRect = (CGRect){
            {0, dragToCreateController.view.frame.size.height*(-1)},
            dragToCreateController.view.frame.size
        };
        
        [dragToCreateController.view setFrame:pullToCreateRect];
        
        [self.tableView addSubview:dragToCreateController.view];
    }

    /*
     [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
     
     
     }
     
     
     }];
     
     [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){

     }];
     
     */
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"didToggleStatusBar" object:nil queue:nil usingBlock:^(NSNotification *note){
        
        //CGRect newFrame =  [[UIApplication sharedApplication] statusBarFrame];
        
    }];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
     if (_viewingNoteStack) {
         CGRect frame = [self.tableView rectForRowAtIndexPath:_selectedIndexPath];
         
         BOOL sectionZero = [self sectionZeroVisible];
         if (!sectionZero){
             //CGRect aFrame = CGRectMake(0.0, frame.origin.y - yOffset, 320.0, 66.0);
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
    NSLog(@"note count: %d",_noteCount);
    if (_noteCount>0) {
        _lastRowColor = [(NoteEntry *)[notes lastObject] noteColor];
        
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
                    [_stackViewController setSectionZeroRowOneVisible:[self sectionZeroVisible]];
                    [self setStackState];
                    break;
                }
            }
        });
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
    return 2;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kNew) {
        return 44;
    } else {
        
        if (indexPath.row == _noteCount-1) {
            return self.view.bounds.size.height-44.0;
        }
         
        return 66;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kNew) {
        return 1;
    } else {
        return _noteCount;
    }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section != kNew);
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellId = @"NoteCellId";
    static NSString *NewNoteCellId = @"NewNoteCellId";
    static UIColor *blueRowBgColor = nil;
    
    if (blueRowBgColor==nil) {
        blueRowBgColor = [UIColor colorWithRed:0.05f green:0.54f blue:0.82f alpha:1.00f];
    }
    
    if (indexPath.section == kNew) {
        NewNoteCell *newNoteCell = [tableView dequeueReusableCellWithIdentifier:NewNoteCellId];
        if (newNoteCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:self options:nil];
            newNoteCell = [topLevelObjects objectAtIndex:0];
            [NewNoteCell configure:newNoteCell];
            
            //newNoteCell setTime
        }
        newNoteCell.label.text = NSLocalizedString(@"New Note", @"New Note");
        return newNoteCell;
        
    } else {
        
        NoteEntryCell *noteEntryCell = [tableView dequeueReusableCellWithIdentifier:CellId];
        ApplicationModel *model = [ApplicationModel sharedInstance];
        
        NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
        
        if (noteEntryCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
            noteEntryCell = [topLevelObjects objectAtIndex:0];
            
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanRightInCell:)];
            [panGesture setDelegate:self];
            [noteEntryCell addGestureRecognizer:panGesture];

        }
        
        if (noteEntry.adding) {
            noteEntryCell.contentView.backgroundColor = [UIColor lightGrayColor];
            
            [self delayedCall:1.0 withBlock:^{
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     noteEntryCell.contentView.backgroundColor = noteEntry.noteColor;
                                 }
                                 completion:nil];
            }];
            
        } else {
            noteEntryCell.contentView.backgroundColor = noteEntry.noteColor;
        }
        
        noteEntryCell.subtitleLabel.text = noteEntry.title;
        NSLog(@"noteEntryCell.subtitleLabel.text: %@",noteEntryCell.subtitleLabel.text);
        BOOL isLastNote = indexPath.row == _noteCount-1 ? YES : NO;
        UITextView *textView = (UITextView *)[noteEntryCell.contentView viewWithTag:FULL_TEXT_TAG];
        if (textView && !isLastNote) {
            [textView removeFromSuperview];
        }
              
        noteEntryCell.relativeTimeText.text = [noteEntry relativeDateString];
        
        return noteEntryCell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section==kNoteItems) {
        NoteEntryCell *noteCell = (NoteEntryCell *)cell;
        ApplicationModel *model = [ApplicationModel sharedInstance];
        NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
                
        UIColor *bgColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
        int index = [[UIColor getNoteColorSchemes] indexOfObject:bgColor];
        if (index==NSNotFound) {
            index = 0;
        }
        if (index >= 4) {
            [noteCell.subtitleLabel setTextColor:[UIColor whiteColor]];
        } else {
            [noteCell.subtitleLabel setTextColor:[UIColor colorWithHexString:@"AAAAAA"]];
        }

        noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
        
        UIView *shadow = [cell viewWithTag:kShadowViewTag];

        if (indexPath.row == _noteCount-1) {
            [shadow setHidden:YES];
            noteCell.contentView.backgroundColor = _lastRowColor;
        }
        
        if (indexPath.row==_noteCount-1) {
            [self willDisplayLastRowCell:cell atIndexPath:indexPath];
        }
    }
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath { //random comment
  
    _selectedIndexPath = indexPath;
    NSLog(@"selected index row: %d",_selectedIndexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (indexPath.section == kNew) { //if "New Note" cell was pressed
        
        if (DISABLE_NEW_CELL) {
            [EZToastView showToastMessage:@"disabled"];
            return;
        }
        NSLog(@"Before count: %d",model.currentNoteEntries.count);
        [model createNoteWithCompletionBlock:^(NoteEntry *entry){
            // new note entry should always appear at row 0, right?
            NSIndexPath *freshIndexPath = [NSIndexPath indexPathForRow:0 inSection:kNoteItems];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:freshIndexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }];
        _noteCount = model.currentNoteEntries.count;
        NSLog(@"After count: %d",model.currentNoteEntries.count);
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
        
        [self listDidUpdate];
        
        
    } else { //if an existing note was selected
        
        if (_viewingNoteStack) {
            //return;
        }
        
        model.selectedNoteIndex = indexPath.row;
        NSLog(@"%s Selected table row %d",__PRETTY_FUNCTION__,indexPath.row);
        [_stackViewController animateOpenForIndexPath:indexPath completion:^(){
            
            NoteEntry *noteEntry = [model noteAtIndex:indexPath.row];
            if (!noteEntry.adding) {
                [self showNoteStackForSelectedRow:indexPath.row animated:NO];
            }
            
        }];
        
        _viewingNoteStack = YES;
    }
}

- (void)willDisplayLastRowCell:(UITableViewCell *)lastCell atIndexPath:(NSIndexPath *)lastIndexPath
{
    _lastRow = (NoteEntryCell *)lastCell;
    _lastIndexPath = lastIndexPath;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *noteEntry = [model.currentNoteEntries lastObject];
    if (_lastRowFullText) {
        [_lastRowFullText removeFromSuperview];
    }
    UITextView *textView = (UITextView *)[lastCell.contentView viewWithTag:FULL_TEXT_TAG];
    UILabel *subtitle = (UILabel *)[lastCell.contentView viewWithTag:LABEL_TAG];
    if (!textView) {
        
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 250.0)];
        
        textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        textView.backgroundColor = [UIColor clearColor];
        textView.tag = FULL_TEXT_TAG;
        [textView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [textView setFrameY:21.0];
        
        textView.textColor = subtitle.textColor;
        NSLog(@"noteEntry.tex: %@",noteEntry.text);
        textView.text = noteEntry.text;
        [textView setEditable:NO];
        [textView setUserInteractionEnabled:NO];
        
        [subtitle setHidden:YES];
        [lastCell.contentView addSubview:textView];
        
        _lastRowFullText = textView;
    }
 
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

- (void)didPanRightInCell:(UIPanGestureRecognizer *)recognizer
{
    UITableViewCell *view = (UITableViewCell *)recognizer.view;
    
    CGPoint point = [recognizer translationInView:view.contentView];
    CGPoint velocity = [recognizer velocityInView:view.contentView];
    CGRect viewFrame = view.contentView.frame;
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (velocity.x > 0 && !_scrolling) {
            point = [recognizer translationInView:view.contentView];
            CGRect newFrame;
            newFrame = CGRectMake(0 + point.x, 0, viewFrame.size.width, viewFrame.size.height);
            view.contentView.frame = newFrame;
            if (_lastRowWasVisible) {
                self.tableView.backgroundColor = [UIColor whiteColor];
                _lastRowWasVisible = NO;
            }
        } else {
            //NSLog(@"not moving because it IS scrolling");
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (point.x > CGRectGetMidX(view.bounds) && velocity.x > 200.0) {
            [self didSwipeToDeleteCellWithIndexPath:view];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView animateWithDuration:0.4
                             animations:^{
                                 [view.contentView setFrame:CGRectMake(viewFrame.size.width, 0.0, viewFrame.size.width, viewFrame.size.height)];
                             }
                             completion:^(BOOL finished){
                                 
                             }];
            
            
        } else {
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [view.contentView setFrame:CGRectMake(0.0, 0.0, viewFrame.size.width, viewFrame.size.height)];
                             }
                             completion:^(BOOL finished){
                                 
                             }];
        }
    } 
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([ApplicationModel sharedInstance].currentNoteEntries.count ==0) {
        return;
    }
    if (DRAG_TO_CREATE) {
        if (scrollView.contentOffset.y < 0) {
            [dragToCreateController scrollingWithYOffset:scrollView.contentOffset.y];
        }
    }
    
    _lastRowVisible = [self isVisibleRow:_noteCount-1 inSection:kNoteItems];
    if (_lastRowVisible) {
        CGRect frame = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:_noteCount-1 inSection:kNoteItems]];
        frame = [self.view convertRect:frame fromView:self.tableView];
        if (CGRectGetMaxY(frame) < CGRectGetMaxY(self.view.bounds)) {
            self.tableView.backgroundColor = _lastRowColor;
        }
        
        _lastRowWasVisible = YES;
    }
    
    [_stackViewController setSectionZeroRowOneVisible:[self sectionZeroVisible]];
    if (![self sectionZeroVisible]) {
        //NSLog(@"sec 0 1 not visible");
    }

    _scrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _scrolling = NO;
    
    if (!decelerate) {
        [self setStackState];
    }
    
    if (DRAG_TO_CREATE) {
        if ( ABS(scrollView.contentOffset.y) >= dragToCreateController.view.frame.size.height) {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kNew]];
            [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(openLastNoteCreated:) userInfo:nil repeats:NO];
            
        }
    }
    
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
        self.tableView.backgroundColor = [UIColor whiteColor];
        _lastRowWasVisible = NO;
    }

    [self setStackState];
    /*
     NSLog(@"frame %@",NSStringFromCGRect(self.tableView.frame));
     NSLog(@"content size %@",NSStringFromCGSize(self.tableView.contentSize));
     NSLog(@"");
     */
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

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
    [self presentViewController:stackViewController animated:animated completion:NULL];
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

- (BOOL)sectionZeroVisible
{
    return [self isVisibleRow:0 inSection:kNew];
}


- (BOOL)isVisibleRow:(int)row inSection:(int)section
{
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
    cellRect = [self.tableView convertRect:cellRect toView:self.tableView.superview];
    BOOL completelyVisible = CGRectIntersectsRect(self.tableView.frame, cellRect);
    
    return completelyVisible;
}

- (void)didSwipeToDeleteCellWithIndexPath:(UIView *)cell
{
    
    CGPoint correctedPoint = [cell convertPoint:cell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:correctedPoint];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:^{
        //
    }];
    _noteCount = model.currentNoteEntries.count;
    [self listDidUpdate];
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

}

- (void)delayedCall:(float)delay withBlock:(void(^)())block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        block();
    });
}

@end
