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

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200

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
    
    NoteEntryCell *_lastRow;
    NSIndexPath *_lastIndexPath;
    StackViewController *_stackViewController;
    
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
        [_stackViewController prepareForExpandAnimationForView:self.view];
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

    [_stackViewController prepareForExpandAnimationForView:self.view];
    
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
        int count = [ApplicationModel sharedInstance].currentNoteEntries.count;
        if (indexPath.row == count-1) {
            
            float maxVisibleHeight = self.view.bounds.size.height-44;
            float height = maxVisibleHeight - ((indexPath.row)*66);
            
            return height;
        }
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
        NSLog(@"noteEntryCell.subtitleLabel.text: %@",noteEntryCell.subtitleLabel.text);
        BOOL isLastNote = indexPath.row==[ApplicationModel sharedInstance].currentNoteEntries.count-1;
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
        int count = model.currentNoteEntries.count;
        if (indexPath.row == count-1) {
            [shadow setHidden:YES];
        }
        
        if (indexPath.row==[ApplicationModel sharedInstance].currentNoteEntries.count-1) {
            [self willDisplayLastRowCell:cell atIndexPath:indexPath];
        }
    }
}

- (void)willDisplayLastRowCell:(UITableViewCell *)lastCell atIndexPath:(NSIndexPath *)lastIndexPath
{
    _lastRow = (NoteEntryCell *)lastCell;
    _lastIndexPath = lastIndexPath;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *noteEntry = [model.currentNoteEntries lastObject];
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
        
        [self debugView:[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[ApplicationModel sharedInstance].currentNoteEntries.count-1 inSection:1]].contentView viewWithTag:FULL_TEXT_TAG] description:@"last row fulltext view" line:__LINE__];
        
        [_stackViewController animateOpenForController:self indexPath:indexPath completion:^(){
            
            NoteEntry *noteEntry = [model noteAtIndex:indexPath.row];
            if (!noteEntry.adding) {
                [self showNoteStackForSelectedRow:indexPath.row animated:NO];
            }
        
        }];
        
        _viewingNoteStack = YES;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if (interfaceOrientation==UIInterfaceOrientationPortrait ) {
        return YES;
    } else {
        return NO;
    }
}

- (void)showNoteStackForSelectedRow:(NSUInteger)row animated:(BOOL)animated
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:model.selectedNoteIndex] forKey:kEditingNoteIndex];
    
    _viewingNoteStack = YES;
    NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithDismissalBlock:^(float currentNoteOffset){
        
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
        
        [self debugView:[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[ApplicationModel sharedInstance].currentNoteEntries.count-1 inSection:1]].contentView viewWithTag:FULL_TEXT_TAG] description:@"last row fulltext view" line:__LINE__];
        
    } andStackVC:_stackViewController];
    
    [self presentViewController:stackViewController animated:animated completion:NULL];
}

- (void)debugView:(UIView *)view description:(NSString *)desc line:(int)line
{
    if (!view) {
        NSLog(@"%@ doesn't exist!",desc);
    }
    NSLog(@"view: %@",view);
    NSLog(@"view class: %@\n\n",[view.superview class]);
    NSLog(@"\n\n%@ is hidden: %s",desc,view.isHidden ? "yes" : "no");
    NSLog(@"alpha: %f",view.alpha);
    NSLog(@"frame: %@",NSStringFromCGRect(view.frame));
    NSLog(@"superview: %@",view.superview);
    NSLog(@"superview class: %@\n\n",[view.superview class]);
    
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
    
    [self delayedCall:0.1 withBlock:^{
        [self.tableView reloadData];
        if (_stackViewController) {
            [_stackViewController update];
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
