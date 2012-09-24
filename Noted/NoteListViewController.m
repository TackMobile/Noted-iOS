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
#import "NewNoteCell.h"
#import "FileStorageState.h"
#import "CloudManager.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+position.h"

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
}

@end

@implementation NoteListViewController

@synthesize tableView;

- (id)init
{
    self = [super initWithNibName:@"NoteListViewController" bundle:nil];
    if (self){
        _previousRowCount = 0;
        _shouldAutoShowNote = NO;
        _viewingNoteStack = NO;
        _scrolling = NO;
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
    
    
     [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
     
         if ([[NSUserDefaults standardUserDefaults] objectForKey:kEditingNoteIndex] && !_viewingNoteStack) {
             _shouldAutoShowNote = YES;
         }
         
         ApplicationModel *model = [ApplicationModel sharedInstance];
         [model refreshNotes];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
        _shouldAutoShowNote = NO;
    }];
     
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_viewingNoteStack) {
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kEditingNoteIndex];
        _viewingNoteStack = NO;
        _shouldAutoShowNote = NO;
        
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    /*
     NSRange range = NSMakeRange(1, 1);
     NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
     [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
     */
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void) noteListChanged:(NSNotification *)notification {
    
    int noteCount = [ApplicationModel sharedInstance].currentNoteDocuments.count;
    NSLog(@"noteListChanged, count: %d [%d]",noteCount,__LINE__);
    [self.tableView reloadData];
    
    if (_shouldAutoShowNote && noteCount > 0) {
        NSUInteger row = [[[NSUserDefaults standardUserDefaults] objectForKey:kEditingNoteIndex] integerValue];
        if (row < noteCount-1) {
            [self showNoteStackForSelectedRow:row animated:NO];
        }
        
        _shouldAutoShowNote = NO;
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
        
        NoteDocument *document = [model.currentNoteEntries objectAtIndex:indexPath.row];
        NoteEntry *noteEntry = [document noteEntry];
        
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
                                     //[noteEntryCell.contentView setBackgroundColor:blueRowBgColor];
                                     noteEntryCell.contentView.backgroundColor = document.color;
                                 }
                                 completion:nil];
            }];
            
        } else {
            noteEntryCell.contentView.backgroundColor = document.color;
        }
        
        noteEntryCell.subtitleLabel.text = [self displayTitleForNoteEntry:noteEntry];
        noteEntryCell.relativeTimeText.text = [noteEntry relativeDateString];
        noteEntryCell.absoluteTimeText.text = [noteEntry absoluteDateString];
        
        
        return noteEntryCell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section==kNoteItems) {
        NoteEntryCell *noteCell = (NoteEntryCell *)cell;
        UIColor *tempColor = [UIColor colorWithHexString:@"AAAAAA"];
        noteCell.subtitleLabel.textColor = [UIColor blackColor];
        noteCell.relativeTimeText.textColor = tempColor;
        noteCell.absoluteTimeText.textColor = tempColor;
        
        ApplicationModel *model = [ApplicationModel sharedInstance];
        UIView *shadow = [cell viewWithTag:kShadowViewTag];
        if (indexPath.row == model.currentNoteEntries.count-1) {
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
    NSLog(@"velocity: %@",NSStringFromCGPoint(velocity));
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
            title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        }
    } else {
        title = @"...";
    }
    
    return title;
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (indexPath.section == 0) {
        [model createNote];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        
        NoteEntryCell *placeholder = [self makePlaceholderForIndexPath:indexPath];
        [self.view addSubview:placeholder];
        CGRect ogFrame = _placeholder.frame;
        
        // animate all the other cells
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            NSIndexPath *cellIndex = [self.tableView indexPathForCell:cell];
            
            if (cellIndex.row != indexPath.row && cellIndex.section != 0) {

                UIImageView *cellImg = [[UIImageView alloc] initWithImage:[self imageRepresentationForCell:cell]];
                cellImg.frame = cell.frame;
                [self.view addSubview:cellImg];
                
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     float originY = cellIndex.row < indexPath.row ? -66.0 : 480.0;
                                     [cellImg setFrameY:originY];
                                 }
                                 completion:^(BOOL finished){
                                     [cellImg setFrame:cell.frame];
                                     [cellImg setHidden:YES];
                                 }];
                
            } 
        }
                
        [UIView animateWithDuration:0.5
                         animations:^{
                             [placeholder setFrame:self.view.bounds];
                         }
                         completion:^(BOOL finished){
                             [placeholder removeFromSuperview];
                             [placeholder setFrame:ogFrame];
                             [_placeholder viewWithTag:56].alpha = 1.0;
                             
                             NoteDocument *doc = [model noteDocumentAtIndex:indexPath.row];
                             if (![doc noteEntry].adding) {
                                 [self showNoteStackForSelectedRow:indexPath.row animated:NO];
                             }
                         }];
                
        // remember indexPath so we can reload this row
        // on return without round-trip to iCloud
        _viewingNoteStack = YES;
        
    }
}

- (NoteEntryCell *)makePlaceholderForIndexPath:(NSIndexPath *)indexPath
{
    if (!_placeholder) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        _placeholder = (NoteEntryCell *)[views lastObject];
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteDocument *document = [model.currentNoteEntries objectAtIndex:indexPath.row];
    _placeholder.subtitleLabel.text = [self displayTitleForNoteEntry:[document noteEntry]];
    _placeholder.relativeTimeText.text = [[document noteEntry] relativeDateString];
    _placeholder.absoluteTimeText.text = [[document noteEntry] absoluteDateString];
    
    [_placeholder setFrame:[self.tableView cellForRowAtIndexPath:indexPath].frame];
    
    _placeholder.subtitleLabel.textColor = [UIColor blackColor];
    [_placeholder.subtitleLabel setText:document.text];
    _placeholder.contentView.backgroundColor = document.color;
    
    // fade the shadow
    [UIView animateWithDuration:0.2
                     animations:^{
                         [_placeholder viewWithTag:56].alpha = 0.0;
                     }
                     completion:^(BOOL finished){

                     }];
    
    return _placeholder;
}

- (void)showNoteStackForSelectedRow:(NSUInteger)row animated:(BOOL)animated
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    model.selectedNoteIndex = row;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:model.selectedNoteIndex] forKey:kEditingNoteIndex];
    
    _viewingNoteStack = YES;
    NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithDismissalBlock:^(NSUInteger row){
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kEditingNoteIndex];
        _viewingNoteStack = NO;
        _shouldAutoShowNote = NO;
        
    }];
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
    
    [self delayedCall:0.35 withBlock:^{
        [self.tableView reloadData];
    }];

}

- (void)delayedCall:(float)delay withBlock:(void(^)())block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        block();
    });
}

#pragma mark Image utility
#define radians(degrees) (degrees * M_PI/180)

- (UIImage *)imageRepresentationForCell:(UITableViewCell *)cell
{
	UIGraphicsBeginImageContextWithOptions(cell.bounds.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [cell.contentView.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}


@end
