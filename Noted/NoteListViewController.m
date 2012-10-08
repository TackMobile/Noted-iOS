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
#import "StackViewController.h"

NSString *const kEditingNoteIndex = @"editingNoteIndex";
static const NSUInteger kShadowViewTag = 56;

typedef enum {
    kNew,
    kNoteItems
} NoteListSections;

@interface NoteListViewController ()
{
    NoteEntryCell *_deletedCell;
    BOOL _viewingNoteStack;
    NSUInteger _previousRowCount;
    BOOL _scrolling;
    
    BOOL _shouldAutoShowNote;
    
    NoteEntryCell *_placeholder;
    StackViewController *_stackViewController;
    BOOL _animating;
    
}

@end

@implementation NoteListViewController

@synthesize tableView,lastRowExtenderView;

- (id)init
{
    self = [super initWithNibName:@"NoteListViewController" bundle:nil];
    if (self){
        _previousRowCount = 0;
        _shouldAutoShowNote = NO;
        _viewingNoteStack = NO;
        _scrolling = NO;
        _animating = NO;
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
    self.tableView.backgroundView  = backgroundView;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight       = 60;
    self.view.layer.cornerRadius = 6.0;
    self.view.clipsToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNoteListChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        
        int noteCount = [ApplicationModel sharedInstance].currentNoteEntries.count;
        [self.tableView reloadData];
        
        if (noteCount>0) {
            [self listDidUpdate];
        }
        
    }];
#warning TODO: reimplement using iCloud syncing
    /*
     [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
     
     
     if ([[NSUserDefaults standardUserDefaults] objectForKey:kEditingNoteIndex] && !_viewingNoteStack) {
     _shouldAutoShowNote = YES;
     }
     
     
     }];
     
     [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
     _shouldAutoShowNote = NO;
     }];
     
     */
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"didToggleStatusBar" object:nil queue:nil usingBlock:^(NSNotification *note){
        
        CGRect newFrame =  [[UIApplication sharedApplication] statusBarFrame];
        float height = newFrame.size.height;
        if (height==20.0) {
            
        }
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#warning TODO: reimplement using iCloud syncing    
    /*
     if (_viewingNoteStack) {
     
     [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kEditingNoteIndex];
     _viewingNoteStack = NO;
     _shouldAutoShowNote = NO;
     
     }
     
     */
    
    
    [self.tableView reloadData];
    if (_stackViewController) {
        [self.view addSubview:_stackViewController.view];
        [self configureLastRowExtenderView];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.tableView setContentOffset:CGPointMake(0.0, 0.0) animated:NO];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTableView:nil];
    [super viewDidUnload];
}



- (void)listDidUpdate
{
    if (!_stackViewController) {
        _stackViewController = [[StackViewController alloc] init];
        
    }
    
    if (!_animating) {
        [_stackViewController.view setFrameX:-320.0];
    }
    
    [self.view insertSubview:_stackViewController.view aboveSubview:self.tableView];
    [_stackViewController generateCells];
    [self configureLastRowExtenderView];
}

- (void)configureLastRowExtenderView
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    // find out if bottom of last row is visible
    UITableViewCell *lastCell = [[self.tableView visibleCells] lastObject];
    if (model.currentNoteEntries.count==0 || !lastCell) {
        return;
    }
    CGRect frame = [self.tableView convertRect:lastCell.frame toView:self.view];
    CGRect bounds = self.view.bounds;
    CGRect hiddenFrame = CGRectMake(0.0, self.view.bounds.size.height, 320.0, 66.0);
    
    
    NSIndexPath *lastIndexPath = [self.tableView indexPathForCell:lastCell];
    NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:lastIndexPath.row];
    if (CGRectGetMaxY(frame) < bounds.size.height) {
        if (!self.lastRowExtenderView) {
            self.lastRowExtenderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.bounds.size.height, 320.0, 66.0)];
            [self.view addSubview:self.lastRowExtenderView];
            
            [self.lastRowExtenderView setUserInteractionEnabled:NO];
        }
        
        CGRect newFrame = CGRectMake(0.0, CGRectGetMaxY(frame), 320.0, bounds.size.height-CGRectGetMaxY(frame));
        [self.lastRowExtenderView setFrame:newFrame];
        [self.lastRowExtenderView setBackgroundColor:noteEntry.noteColor];
    } else {
        // hide it
        [self.lastRowExtenderView setFrame:hiddenFrame];
    }
}


#pragma mark - Table View methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kNew) {
        return 44;
    } else {
        return 66;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kNew) {
        return 1;
    } else {
        ApplicationModel *model = [ApplicationModel sharedInstance];
        return [model.currentNoteEntries count];
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
            newNoteCell.textLabel.adjustsFontSizeToFitWidth = YES;
            newNoteCell.textLabel.backgroundColor = [UIColor clearColor];
            newNoteCell.label.textColor = [UIColor colorWithHexString:@"AAAAAA"];
            newNoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            newNoteCell.contentView.backgroundColor = [UIColor whiteColor];
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
        int count = model.currentNoteEntries.count;
        if (indexPath.row == count-1) {
            [shadow setHidden:YES];
        }
    }
}

- (void)didPanRightInCell:(UIPanGestureRecognizer *)recognizer
{
    UITableViewCell *view = (UITableViewCell *)recognizer.view;
    
    CGPoint point = [recognizer translationInView:view.contentView];
    CGPoint velocity = [recognizer velocityInView:view.contentView];
    CGRect viewFrame = view.contentView.frame;
    //int xDirection = (velocity.x < 0) ? 1 : 0;
    //NSLog(@"velocity: %@",NSStringFromCGPoint(velocity));
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (velocity.x > 0 && !_scrolling) {
            point = [recognizer translationInView:view.contentView];
            CGRect newFrame;
            newFrame = CGRectMake(0 + point.x, 0, viewFrame.size.width, viewFrame.size.height);
            view.contentView.frame = newFrame;
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
    _scrolling = YES;
    [self configureLastRowExtenderView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _scrolling = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _scrolling = NO;
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

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (indexPath.section == kNew) {
        [model createNoteWithCompletionBlock:^(NoteEntry *entry){
            // new note entry should always appear at row 0, right?
            NSIndexPath *freshIndexPath = [NSIndexPath indexPathForRow:0 inSection:kNoteItems];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:freshIndexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
        [self listDidUpdate];
    } else {
        model.selectedNoteIndex = indexPath.row;
        [_stackViewController.view setFrameX:0.0];
        _animating = YES;

        [_stackViewController expandRowsForViewController:self selectedIndexPath:indexPath completion:^(){
            _animating = NO;
            [_stackViewController.view setFrameX:-320.0];
            NoteEntry *noteEntry = [model noteAtIndex:indexPath.row];
            if (!noteEntry.adding) {
                [self showNoteStackForSelectedRow:indexPath.row animated:NO];
            }
        
        }];
        
        _viewingNoteStack = YES;
    }
}

- (void)showNoteStackForSelectedRow:(NSUInteger)row animated:(BOOL)animated
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:model.selectedNoteIndex] forKey:kEditingNoteIndex];
    
    _viewingNoteStack = YES;
    NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithDismissalBlock:^(NSUInteger row,float currentNoteOffset){
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kEditingNoteIndex];
        _viewingNoteStack = NO;
        _shouldAutoShowNote = NO;
        
        CGRect frame = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:kNoteItems]];
        [self.tableView setContentOffset:CGPointMake(0.0, frame.origin.y - currentNoteOffset) animated:NO];
        int64_t delayInSeconds = 1.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.tableView setContentOffset:CGPointZero animated:YES];
        });
        
    } andStackVC:_stackViewController];
    
    [self presentViewController:stackViewController animated:animated completion:NULL];
}

- (void)didSwipeToDeleteCellWithIndexPath:(UIView *)cell
{
    CGPoint correctedPoint = [cell convertPoint:cell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:correctedPoint];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:^{
        
        //[EZToastView showToastMessage:@"note deleted from cloud"];
    }];
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self configureLastRowExtenderView];
    
    [self delayedCall:0.1 withBlock:^{
        [self.tableView reloadData];
        if (_stackViewController) {
            [_stackViewController generateCells];
        }
        
    }];

}

- (void)delayedCall:(float)delay withBlock:(void(^)())block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        block();
    });
}


@end
