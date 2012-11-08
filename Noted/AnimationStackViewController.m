//
//  StackViewController.m
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "AnimationStackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteEntryCell.h"
#import "NewNoteCell.h"
#import "UIView+position.h"
#import "ApplicationModel.h"
#import "NoteDocument.h"
#import "NoteEntry.h"
#import "UIColor+HexColor.h"
#import "NoteViewController.h"
#import "NoteListViewController.h"
#import "DrawView.h"

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200
#define SECZERO_ROWZERO_TAG 687

#define DEBUG_ANIMATIONS    1

static const float  kAnimationDuration      = 0.5;
static const float  kDebugAnimationDuration = 0.5;
static const float  kCellHeight             = 66.0;

@interface AnimationStackViewController ()
{
    UITableView *_tableView;
    UITextView *_placeholderText;
    
    StackState _state;
    
    NSMutableArray *_noteEntryModels;
    
    BOOL _sectionZeroRowOneVisible;
    int _sectionZeroCellIndex;
    
    BOOL _isPinching;
    BOOL _animating;
    float _pinchPercentComplete;
    int _selectedViewIndex;
    
    CGRect _centerNoteFrame;
    CGRect _centerNoteDestinationFrame;
    
    NSMutableArray *stackingViews;
    NSMutableArray *_noteViews;
    
    NSMutableArray *destinationFrames;
    NSMutableArray *originFrames;
}

@end

@implementation AnimationStackViewController

@synthesize noteViews=_noteViews;
@synthesize tableView=_tableView;
@synthesize state=_state;
@synthesize delegate;
@synthesize sectionZeroRowOneVisible = _sectionZeroRowOneVisible;

- (id)init
{
    self = [super initWithNibName:@"AnimationStackView" bundle:nil];
    if (self){
        _isPinching = NO;
        
        _noteViews = [[NSMutableArray alloc] init];
        _centerNoteFrame = CGRectZero;
        _animating = NO;
        
        _state = kNoteStack;
        _sectionZeroCellIndex = -1;
        _noteEntryModels = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoadOptionsViewController
{
    [super viewDidLoad];
    [self.view setUserInteractionEnabled:NO];
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)setIndexOfSelectedNoteView:(int)index
{
    _selectedViewIndex = index;
    
    if (_sectionZeroRowOneVisible) {
        _selectedViewIndex ++;
    } else {
        NSIndexPath *firstVisible = [[_tableView indexPathsForVisibleRows] objectAtIndex:0];
        _selectedViewIndex = index - firstVisible.row;
        if (_selectedViewIndex < 0) {
//NSLog(@"should not be less than zero");
        }
    }
    
//NSLog(@"Selected view index: %d",_selectedViewIndex);
}

- (void)prepareForAnimation  
{
    if (!_animating) {
        [self.view setFrameX:-self.view.bounds.size.width];
    }
    
    [_noteEntryModels removeAllObjects];
    NSArray *allEntries = [[[ApplicationModel sharedInstance] currentNoteEntries] array];
    NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];

    NSIndexPath *firstVisible = [visibleIndexPaths objectAtIndex:0];
    if (firstVisible.section==0) {
        _sectionZeroRowOneVisible = YES;
        _sectionZeroCellIndex = 0;
    } else {
        _sectionZeroRowOneVisible = NO;
        _sectionZeroCellIndex = -1;
    }
    
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            [_noteEntryModels addObject:[NSNull null]];
        } else {
            [_noteEntryModels addObject:[allEntries objectAtIndex:indexPath.row]];
        }
    }
    
//NSLog(@"Number of visible rows: %d",visibleIndexPaths.count);
//NSLog(@"Section zero visible: %s (%d)",_sectionZeroCellIndex != -1 ? "yes":"no",_sectionZeroCellIndex);
//NSLog(@"has dummy model for sec 0 row 0 ---> %s",[_noteEntryModels indexOfObject:[NSNull null]] != NSNotFound ? "yes" : "no");
    
    [self trimCellViews];

    [self updateCellsWithModels];

}

#pragma mark Pinch to collapse animation

- (void)prepareForCollapse
{
    
    NSArray *visibleRows = _tableView.indexPathsForVisibleRows;
    //BOOL isLast = [self currentNoteIsLast];
    
    NSIndexPath *selectedIndexPath = [_tableView indexPathForSelectedRow];
    _selectedViewIndex = selectedIndexPath.row - [(NSIndexPath *)[visibleRows objectAtIndex:0] row];
    if (_sectionZeroRowOneVisible) {
        _selectedViewIndex += 1;
    }
    NSLog(@"selectedViewIndex is now %i",_selectedViewIndex);
    _centerNoteDestinationFrame = [_tableView rectForRowAtIndexPath:selectedIndexPath];
    _centerNoteDestinationFrame = [_tableView.superview convertRect:_centerNoteDestinationFrame fromView:_tableView];

    
    if (destinationFrames) {
        [destinationFrames removeAllObjects];
    }
    destinationFrames = [[NSMutableArray alloc] initWithCapacity:_tableView.indexPathsForVisibleRows.count];
    
    /*
     DrawView *debug = (DrawView *)[self.view viewWithTag:888];
     if (debug) {
     [debug removeFromSuperview];
     }
     
     debug = [[DrawView alloc] initWithFrame:self.view.bounds];
     [debug setUserInteractionEnabled:NO];
     [debug setTag:888];
     [debug setBackgroundColor:[UIColor clearColor]];
     
     */
    
    for (int i = 0; i < visibleRows.count; i++) {
        NSIndexPath *indexPath = [visibleRows objectAtIndex:i];
        CGRect rect = [_tableView rectForRowAtIndexPath:indexPath];
        rect = [_tableView.superview convertRect:rect fromView:_tableView];

        //NSLog(@"Rect %@",NSStringFromCGRect(rect));
        if (i != _selectedViewIndex) {
            [destinationFrames addObject:[NSValue valueWithCGRect:rect]];
        } else {
            [destinationFrames addObject:[NSNull null]];
        }
    }
    
    /*
     [debug setDrawBlock:^(UIView* v,CGContextRef context){
     
     for (NSValue *val in destinationFrames) {
     
     CGRect frame = CGRectZero;
     UIBezierPath* bezierPath = [UIBezierPath bezierPath];
     if (val != (id)[NSNull null]) {
     frame = val.CGRectValue;
     [[UIColor blueColor] setStroke];
     bezierPath.lineWidth = 1.0;
     } else {
     frame = _centerNoteDestinationFrame;
     [[UIColor orangeColor] setStroke];
     bezierPath.lineWidth = 3.0;
     }
     
     float yOrigin = frame.origin.y;
     [bezierPath moveToPoint: CGPointMake(0.0, yOrigin)];
     [bezierPath addLineToPoint: CGPointMake(320.0, yOrigin)];
     [bezierPath moveToPoint: CGPointMake(0.0, yOrigin+frame.size.height)];
     [bezierPath addLineToPoint: CGPointMake(320.0, yOrigin+frame.size.height)];
     
     [bezierPath stroke];
     }
     }];
     
    [self.view addSubview:debug];
     */
    
    //NSLog(@"Num of destination frames: %d",destinationFrames.count);
    //NSLog(@"Num of noteViews: %d",_noteViews.count);
    
    //NSLog(@"\n\ndestinationFrames: %@\n\n",destinationFrames);
    //NSLog(@"selected dest frame: %@",NSStringFromCGRect(_centerNoteDestinationFrame));
    
    if (originFrames) {
        [originFrames removeAllObjects];
    }
    originFrames = [[NSMutableArray alloc] initWithCapacity:_tableView.indexPathsForVisibleRows.count];
    [_noteViews enumerateObjectsUsingBlock:^(id obj,NSUInteger index,BOOL *stop) {
        
        if (index == _selectedViewIndex) {
            [originFrames addObject:[NSNull null]];
        } else {
            
            int offsetIndex = -(_selectedViewIndex - index);
            float baselineYOffset = offsetIndex < 0 ? 0.0 : self.view.bounds.size.height;
            float offsetFactor = offsetIndex < 0 ? offsetIndex : offsetIndex-1;
            float yOrigin = baselineYOffset+ offsetFactor*kCellHeight;//*multiplier;
            CGRect frame = CGRectMake(0.0, yOrigin, 320.0, kCellHeight);
            [originFrames addObject:[NSValue valueWithCGRect:frame]];
            
        }
    }];
    
    [self setNotesToCollapseBeginPositions:NO];
    [self pruneSubviews];
}

- (void)pruneSubviews
{
    int count = 0;
    for (int i = 0; i < self.view.subviews.count; i++) {
        UIView *view = (UIView *)[self.view.subviews objectAtIndex:i];
        if (view.tag != 888) {
            count++;
            NSLog(@"subview with class %@ and frame %@",NSStringFromClass([view class]),NSStringFromCGRect(view.frame));
            if (![_noteViews containsObject:view]) {
                NSLog(@"culprit is %@",view);
                [view removeFromSuperview];
                NSLog(@"hack fix!");
            }
        } else {
            NSLog(@"detected debug view");
        }
    }
    NSLog(@"Num of views");
}

- (void)setNotesToCollapseBeginPositions:(BOOL)animated
{
    __block UIView *prevNote = nil;
    NSLog(@"crash here? [%i]",__LINE__);
    if (_selectedViewIndex>_noteEntryModels.count-1) {
        NSLog(@"NSRange exception [%d]",__LINE__);
    }
    UIView *currentNote = [_noteViews objectAtIndex:_selectedViewIndex];
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             [currentNote setFrame:self.view.bounds];
                         }
                         completion:^(BOOL finished){
                             NSLog(@"finished reopening current note");
                             [self countOfAllSubviews];
                         }];
    } else {
        [currentNote setFrame:self.view.bounds];
    }
    
    [_noteViews enumerateObjectsUsingBlock:^(id obj,NSUInteger index,BOOL *stop) {
        
        if (index != _selectedViewIndex) {
            
            UIView *note = (UIView *)obj;
            NSLog(@"here? [%i]",__LINE__);
            CGRect frame = [[originFrames objectAtIndex:index] CGRectValue];
            if (animated) {
                [UIView animateWithDuration:kAnimationDuration
                                 animations:^{
                                     [note setFrame:frame];
                                 }
                                 completion:nil];
                
            } else {
                [note setFrame:frame];
            }
            
            int offsetIndex = -(_selectedViewIndex - index);
            if (offsetIndex < 0) {
                [self.view insertSubview:note belowSubview:currentNote];
            } else {
                if (prevNote) {
                    [self.view insertSubview:note belowSubview:prevNote];
                }
            }
            prevNote = note;
        }
    }];
}

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    _pinchPercentComplete = pinchPercent;
    
//    int index = [self.delegate selectedIndexPathForStack];
//    [self setIndexOfSelectedNoteView:index];
    
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
        [[[self currentNote] viewWithTag:FULL_TEXT_TAG] setHidden:NO];
    }
    //[[self currentNote] setHidden:YES];
    //[self.bottomExtender setHidden:YES];
    
    [self collapseCurrentNoteWithScale:scale];
    [self shrinkStackedNotesForScale:scale];
    
    NSLog(@"num note views: %d, pinch complete: %f",_noteViews.count,_pinchPercentComplete);
}

- (void)shrinkStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < _noteViews.count; i ++) {
        [self collapseStackedNoteAtIndex:i withScale:scale];
    }
}

- (NSUInteger)noteEntryViewsCount
{
    int count = 0;
    for (int i = 0; i < _noteViews.count; i++) {
        if ([[_noteViews objectAtIndex:i] isKindOfClass:[NoteEntryCell class]]) {
            count++;
        }
    }
    
    return count;
}

- (UITextView *)makeFulltextView
{
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 250.0)];
    
    textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    textView.backgroundColor = [UIColor clearColor];
    textView.tag = FULL_TEXT_TAG;
    [textView setFrameY:21.0];
    [textView setEditable:NO];
    [textView setUserInteractionEnabled:NO];
    
    return textView;
}

- (void)collapseStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    BOOL sectionZeroRowZero = index == 0 && _sectionZeroRowOneVisible;
    if (index==_selectedViewIndex) {
        return;
    }
    
    if (sectionZeroRowZero) {
        return;
    }

    NoteEntryCell *noteView = [_noteViews objectAtIndex:index];

    CGRect destinationFrame = [(NSValue *)[destinationFrames objectAtIndex:index] CGRectValue];

    CGRect originFrame = [(NSValue *)[originFrames objectAtIndex:index] CGRectValue];
 
    CGFloat startY = originFrame.origin.y;
    CGFloat destY = destinationFrame.origin.y;

    float diff = -(startY-destY);
    diff = diff*_pinchPercentComplete;
    CGFloat newY = startY;
    if (diff == 0 && _pinchPercentComplete == 1.0) {
        newY = destY;
    } else {
        newY = startY + diff;
    }
    
    [self updateSubviewsForNote:noteView scaled:YES];
    
    float newHeight = kCellHeight;
    
    if ([self noteIsLast:[self indexOfNoteView:noteView accountForSectionZero:NO]]) {
        
        newHeight = kCellHeight + (destinationFrame.size.height - kCellHeight)*_pinchPercentComplete;
        
#warning reimp!
        /*
         UITextView *textView = (UITextView *)[noteView.contentView viewWithTag:FULL_TEXT_TAG];
         UILabel *subtitle = (UILabel *)[noteView.contentView viewWithTag:LABEL_TAG];
         NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtIndex:[self indexOfNoteView:noteView accountForSectionZero:YES]];;
         if (!textView) { // if it doesn't have it, add it and hide title text
         textView = [self makeFulltextView];
         textView.text = noteEntry.text;
         textView.textColor = subtitle.textColor;
         [noteView.contentView addSubview:textView];
         }
         
         [textView setHidden:NO];
         textView.alpha = 1.0;
         [subtitle setHidden:YES];
         
         */
    }
    
    
    CGRect newFrame = CGRectMake(0.0, newY, 320.0, newHeight);
    [noteView setFrame:newFrame];
    
    return;
    
    /*
     int offset = -(_selectedViewIndex - index);
     float currentNoteOffset = 0.0;
     
     newHeight = kCellHeight;
     if (offset<0) {
     currentNoteOffset = offset*kCellHeight;
     newY = CGRectGetMinY([self currentNote].frame) + currentNoteOffset;
     
     } else if (offset>0) {
     currentNoteOffset = CGRectGetMaxY([self currentNote].frame) + (offset-1)*kCellHeight;
     newY = currentNoteOffset;
     //NSLog(@"CGRectGetMaxY([self currentNote].frame: %f",CGRectGetMaxY([self currentNote].frame));
     //NSLog(@"_centerNoteFrame max y: %f",CGRectGetMaxY(_centerNoteFrame));
     newHeight = self.view.bounds.size.height-CGRectGetMaxY(_centerNoteFrame);
     }
     
     if ([self noteIsLast:[self indexOfNoteView:noteView accountForSectionZero:NO]]) {
     
     UITextView *textView = (UITextView *)[noteView.contentView viewWithTag:FULL_TEXT_TAG];
     UILabel *subtitle = (UILabel *)[noteView.contentView viewWithTag:LABEL_TAG];
     NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtIndex:[self indexOfNoteView:noteView accountForSectionZero:YES]];;
     if (!textView) { // if it doesn't have it, add it and hide title text
     textView = [self makeFulltextView];
     textView.text = noteEntry.text;
     textView.textColor = subtitle.textColor;
     [noteView.contentView addSubview:textView];
     }
     
     [textView setHidden:NO];
     textView.alpha = 1.0;
     [subtitle setHidden:YES];
     
     }
     */
}

- (void)collapseCurrentNoteWithScale:(CGFloat)scale
{
    BOOL currentIsLast = [self currentNoteIsLast];
    float destHeight = _centerNoteDestinationFrame.size.height;
    float diff = self.view.bounds.size.height-destHeight;
    float newHeight = self.view.bounds.size.height-(diff*_pinchPercentComplete);
    
    NoteEntryCell *currentNoteCell = (NoteEntryCell *)[self currentNote];
    [self updateSubviewsForNote:currentNoteCell scaled:YES];
    
    float centerFactor = currentIsLast ? 1.0 : 0.5;
    float newY;
    if (currentIsLast) {
        newY = (self.view.bounds.size.height-newHeight)*centerFactor;
    } else {
        newY = _centerNoteDestinationFrame.origin.y*_pinchPercentComplete;
    }
    
    /*
     if (_pinchPercentComplete>0.5&&_pinchPercentComplete>0.45) {
     NSLog(@"count of all cells: %d",_noteViews.count);
     NSLog(@"count of all subviews before opening: %d",[self countOfAllSubviews]);
     NSLog(@"count of note entry cells: %d",[self noteEntryViewsCount]);
     NSLog(@"count of visible rows: %d",[_tableView indexPathsForVisibleRows].count);
     }
     
     */
    if (newY < 0) {
        newY = 0;
    }
#warning this is null!
    UIView *fullText = [currentNoteCell.contentView viewWithTag:FULL_TEXT_TAG];
    if ([self currentNoteIsLast]) {
        newHeight = self.view.bounds.size.height - newY;
        fullText.alpha = 1.0;
        currentNoteCell.subtitleLabel.alpha = 0.0;
    } else {
        float factor = 1.0-((1.0-_pinchPercentComplete)*.3);
        fullText.alpha = 1.0-(_pinchPercentComplete*factor);
        currentNoteCell.subtitleLabel.alpha = _pinchPercentComplete+factor;
    }
    
    _centerNoteFrame = CGRectMake(0.0, newY, 320.0, newHeight);
    
    [currentNoteCell setFrame:_centerNoteFrame];
}

- (void)finishCollapse:(void(^)())complete
{
    complete();
    [self.view setFrameX:-320.0];
    
    return;
    float duration = DEBUG_ANIMATIONS ? kDebugAnimationDuration : kAnimationDuration;
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         float currentNoteY = _centerNoteFrame.origin.y;
                         if ([self currentNoteIsLast]) {
                             _centerNoteFrame = CGRectMake(0.0, currentNoteY, 320.0, self.view.bounds.size.height-currentNoteY);
                         } else {
                             _centerNoteFrame = CGRectMake(0.0, currentNoteY, 320.0, kCellHeight);
                         }
                         
                         [[self currentNote] setFrame:_centerNoteFrame];
                         
                         for (int i = 0; i < _noteViews.count; i ++) {
                             // skip the current view && section zero row 1 view if necessary
                             NSLog(@"here? [%i]",__LINE__);
                             if (i == _selectedViewIndex  || ![[_noteViews objectAtIndex:i] isKindOfClass:[NoteEntryCell class]]) {
                                 i++;
                                 continue;
                             }
                             NSLog(@"here? [%i]",__LINE__);
                             UIView *note = [_noteViews objectAtIndex:i];//[noteDict objectForKey:@"noteView"];
                             
                             int offset = -(_selectedViewIndex - i);
                             
                             float newHeight = kCellHeight;
                             float newY = 0.0;
                             if (offset < 0) {
                                 float finalCY = [self finalYOriginForCurrentNote];
                                 float correction = offset*kCellHeight;
                                 newY = finalCY + correction;
                                 
                             } else if (offset>0) {
                                 newHeight = self.view.bounds.size.height-CGRectGetMaxY([self currentNote].frame);
                                 newY = (CGRectGetMaxY(_centerNoteFrame))+((offset-1)*kCellHeight);
                             }
                             
                             CGRect newFrame = CGRectMake(0.0, newY, 320.0, newHeight);
                             [note setFrame:newFrame];
                         }
                     }
     
                     completion:^(BOOL finished){
                         
                         complete();
                         [self.view setFrameX:-320.0];
                         //[self toggleFullTextForNoteOpening:NO inCell:(UITableViewCell *)[self currentNote]];
                         
                     }];
}

- (void)toggleFullTextForNoteOpening:(BOOL)opening inCell:(UITableViewCell *)cell
{
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:FULL_TEXT_TAG];
    UILabel *subtitle = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
    
    NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];;
    if (!textView) { // if it doesn't have it, add it and hide title text
        textView = [self makeFulltextView];
        textView.text = noteEntry.text;
        textView.textColor = subtitle.textColor;
        [cell.contentView addSubview:textView];
    }
    
    //NSLog(@"textView is hidden: %s",textView.isHidden ? "ja" : "nein");
    
    if ([self currentNoteIsLast]) {
        textView.alpha = 1.0;
        subtitle.alpha = 0.0;
    } else {
        textView.alpha = 0.0;
        [UIView animateWithDuration:[self animationDuration]*0.4
                         animations:^{
                             
                             textView.alpha = 1.0;
                             subtitle.alpha = 0.0;
                             
                         }
                         completion:^(BOOL finished){
                             subtitle.alpha = 0.0;
                         }];
    }
}

- (void)updateNoteText
{
    if (_selectedViewIndex>_noteViews.count-1) {
        NSLog(@"uh oh");
    }
    NSLog(@"here? [%i]",__LINE__);
    NoteEntryCell *noteCell = (NoteEntryCell *)[_noteViews objectAtIndex:_selectedViewIndex];
    UITextView *fullText = (UITextView *)[noteCell.contentView viewWithTag:FULL_TEXT_TAG];
    NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];
    NSString *newText = noteEntry.text;
    NSLog(@"updating text from %@ to %@",fullText.text,newText);
    fullText.text = newText;
    
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
    
    if (![noteCell respondsToSelector:@selector(setRelativeTimeText:)]) {
        NSLog(@"stop!");
    }
    noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
    
    noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
    NSLog(@"Note cell subtitle was: %@, now it's: %@:",noteCell.subtitleLabel.text,noteEntry.title);
}


#pragma mark Tap to open animation

- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    int count = [self countOfAllSubviews];
    NSLog(@"count: %i",count);
    
    /*
     if ([selectedIndexPath isEqual:[[_tableView indexPathsForVisibleRows] lastObject]]) {
     NSLog(@"count of all cells: %d",_noteViews.count);
     NSLog(@"count of all subviews before opening: %d",self.view.subviews.count);
     NSLog(@"count of note entry cells: %d",[self noteEntryViewsCount]);
     NSLog(@"count of visible rows: %d",[_tableView indexPathsForVisibleRows].count);
     }
     */
    
    [self prepareForAnimation];
    [self.view setFrameX:0.0];
    
    [self setIndexOfSelectedNoteView:selectedIndexPath.row];
    //NSLog(@"%d",_selectedViewIndex);
    _animating = YES;
    
    
    
    if (!_sectionZeroRowOneVisible) {
        NSAssert(_noteViews.count == [self noteEntryViewsCount], @"If section zero isn't visible, counts should be equal");
    }
    
    int noteViewIndex = 0;
    
    for (NSIndexPath *indexPath in [_tableView indexPathsForVisibleRows]) {
        NoteEntryCell *modelCellView = (NoteEntryCell* )[_tableView cellForRowAtIndexPath:indexPath];
        NSLog(@"here? [%i]",__LINE__);
        NoteEntryCell *noteCell = [_noteViews objectAtIndex:noteViewIndex];
        CGRect frame = [_tableView convertRect:modelCellView.frame toView:[_tableView superview]];
        noteCell.frame = frame;
        
        NSLog(@"Note view class: %@, frame will be %@",[noteCell class],NSStringFromCGRect(frame));
        
        if (noteCell.tag == SECZERO_ROWZERO_TAG) {
            
            [noteCell setBackgroundColor:[UIColor purpleColor]];
            
            //[noteCell setFrameX:20.0];
            
            noteViewIndex ++;
            continue;
        }
        
        UIView *shadow = [noteCell viewWithTag:56];
        float shadowHeight = 7.0;
        [shadow setFrameY:-shadowHeight];
        [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        [circle setHidden:NO];
        
        BOOL isSelectedCell = _selectedViewIndex == noteViewIndex;
        
        if (isSelectedCell) {
            [self.view addSubview:noteCell];
            [self openCurrentNoteWithCompletion:completeBlock];
        } else {
            BOOL isBelow = noteViewIndex > _selectedViewIndex;
            BOOL isLastCell = [self noteIsLast:noteViewIndex];
            
            [self openNote:noteCell isLast:isLastCell isBelow:isBelow];
        }
        
        noteViewIndex ++;
    }
    
}

- (NSRange)rangeForNoteViews
{
    return NSMakeRange(0,_noteViews.count);
}

/*
 - (NSRange)rangeForNoteModels
 {
 NSRange range = NSMakeRange(0, 0);
 if (_state == kTableView) {
 // figure out a range based on tableView's visible rows
 NSArray *visible = [self visibleNoteSectionRows];
 if (visible.count==0) {
 return range;
 }
 int location = [(NSIndexPath *)[visible objectAtIndex:0] row];
 int length = [(NSIndexPath *)[visible lastObject] row] - location;
 range = NSMakeRange(location, length+1);
 
 } else if (_state == kNoteStack) {
 // figure out a range based on ApplicationModel's current index
 ApplicationModel *model = [ApplicationModel sharedInstance];
 NSMutableOrderedSet *allEntries = [model currentNoteEntries];
 
 int count = allEntries.count;
 float offset = [self sectionZeroVisible] ? 44.0 : 0.0;
 float usableScreenHeight = self.view.bounds.size.height - offset; // for section zero row one
 int displayableCellCount = (int)ceilf((usableScreenHeight/kCellHeight));
 displayableCellCount = displayableCellCount > count ? count : displayableCellCount;
 
 int beginRange = model.selectedNoteIndex;
 int endRange = model.selectedNoteIndex;
 while (endRange-beginRange<=displayableCellCount) {
 beginRange--;
 endRange++;
 }
 
 beginRange = beginRange < 0 ? 0 : beginRange;
 endRange = endRange-beginRange < displayableCellCount ? displayableCellCount : endRange;
 endRange = endRange > count ? count : endRange;
 
 while (endRange-beginRange<displayableCellCount && beginRange>0) {
 beginRange--;
 }
 
 NSLog(@"begin: %d, end: %d",beginRange,endRange);
 
 range = NSMakeRange(beginRange, endRange-beginRange);
 }
 
 return range;
 }
 */

- (NSArray *)visibleNoteSectionRows
{
    NSArray *allVisibleRows = [_tableView indexPathsForVisibleRows];
    
    return allVisibleRows;
}



- (float)animationDuration
{
    return DEBUG_ANIMATIONS ? kDebugAnimationDuration : kAnimationDuration;
}

- (void)openCurrentNoteWithCompletion:(animationCompleteBlock)completeBlock
{
    NoteEntryCell *noteCell = (NoteEntryCell *)[self currentNote];
    
    [self toggleFullTextForNoteOpening:YES inCell:noteCell];
    
    [UIView animateWithDuration:[self animationDuration]
                     animations:^{
                         
                         // NSLog(@"current frame of note cell: %@",NSStringFromCGRect(noteCell.frame));
                         CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
                         appFrame.origin.y = 0.0;
                         NSLog(@"cell label frame %@",NSStringFromCGRect(noteCell.subtitleLabel.frame));
                         UIView *fullText = [noteCell.contentView viewWithTag:FULL_TEXT_TAG];
                         NSLog(@"fulltext is hidden: %s",fullText.isHidden ? "yes" : "no");
                         NSLog(@"fulltext text: %@",[(UITextView *)fullText text]);
                         NSLog(@"alpha of fulltext is %f",fullText.alpha);
                         
                         
                         [noteCell setFrame:appFrame];
                         noteCell.layer.cornerRadius = 6.0;
                         
                         // transistion its subviews
                         UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
                         [circle setHidden:NO];
                         circle.alpha = 1.0;
                         
                     }
                     completion:^(BOOL finished){
                         
                         // debug
                         //noteCell.contentView.backgroundColor = [self randomColor];
                         
                         _animating = NO;
                         completeBlock();
                         
                         int count = [self countOfAllSubviews];
                         NSLog(@"count: %i",count);
                         
                         [self finishExpansion];
                         
                     }];
}

- (void)openNote:(NoteEntryCell *)noteCell isLast:(bool)isLast isBelow:(BOOL)isBelow
{
    float duration = DEBUG_ANIMATIONS ? kDebugAnimationDuration : kAnimationDuration;
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         if (isLast) {
                             CGRect destinationFrame = CGRectMake(0.0, self.view.bounds.size.height, 320.0, 200.0); // arbitrary height?
                             
                             [noteCell setFrame:destinationFrame];
                             //[extenderView setFrameY:CGRectGetMaxY(self.view.bounds)+66.0];
                         } else {
                             float yOrigin = isBelow ? self.view.bounds.size.height : 0.0;
                             CGRect destinationFrame = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                             [noteCell setFrame:destinationFrame];
                         }
                         
                         // transistion its subviews
                         UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
                         circle.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         // debug
                         //noteCell.contentView.backgroundColor = [self randomColor];
                     }];
}

- (void)finishExpansion
{
    [self.view setFrameX:-320.0];
}

- (void)resetToExpanded:(void(^)())completion
{
    [self setNotesToCollapseBeginPositions:YES];

    NoteEntryCell *current = (NoteEntryCell *)[_noteViews objectAtIndex:_selectedViewIndex];
    [UIView animateWithDuration:0.5
                     animations:^{
                         [current setFrame:self.view.bounds];
                         if (![self currentNoteIsLast]) {
                             [[current viewWithTag:FULL_TEXT_TAG] setAlpha:1.0];
                             [[current viewWithTag:LABEL_TAG] setAlpha:0.0];
                         }
                         
                     }
                     completion:^(BOOL finished){
                         [self finishExpansion];
                         completion();
                     }];
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 2.0;
}

- (void)updateSubviewsForNote:(UIView *)note scaled:(BOOL)scaled
{
    UIView *littleCircle = [note viewWithTag:78];
    if (!scaled) {
        littleCircle.alpha = 0.0;
        return;
    }
    
    littleCircle.alpha = 1.0-(_pinchPercentComplete*1.1);
}

#pragma mark Data source

- (float)finalYOriginForCurrentNote
{
    float finalY = (self.view.bounds.size.height-kCellHeight)*0.5;
    
    return finalY;
}

- (UIView *)currentNote
{
    return [_noteViews objectAtIndex:_selectedViewIndex];
}

- (UIView *)lastNote
{
    return (UIView *)[_noteViews lastObject];
}

- (NoteEntry *)currentNoteEntry
{
    return [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];
}

// trim/add-to the array of views so they
// reflect the number of notes currently in range
// either the visible cells in the tableview, or if
// viewing the ntoestack vc, the range of views to left or right
//

- (void)trimCellViews
{
    if (!_sectionZeroRowOneVisible) {
        BOOL removed = [self removeSectionZeroRowOne];
        //NSLog(@"Removed [0,0] view: %s",removed ? "yes" : "no");
    } else {
        // replace with placeholder UIView
        //UIView *firstView = (UIView *)[_noteViews objectAtIndex:_sectionZeroCellIndex];
        int secZeroViewIndex = [_noteViews indexOfObject:[self.view viewWithTag:SECZERO_ROWZERO_TAG]];
        if (secZeroViewIndex == NSNotFound) {
            UIView *newPlaceholder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            newPlaceholder.tag = SECZERO_ROWZERO_TAG;
            if (_noteViews.count>0) {
                [_noteViews replaceObjectAtIndex:_sectionZeroCellIndex withObject:newPlaceholder];
            } else {
                [_noteViews addObject:newPlaceholder];
            }
        
        } else {
            [_noteViews replaceObjectAtIndex:_sectionZeroCellIndex withObject:[self.view viewWithTag:SECZERO_ROWZERO_TAG]];
        }
    }
    
    //NSLog(@"Num of total subviews: %i [%i]",[self.view subviews].count,__LINE__);
    //NSLog(@"_noteViews count: %d, noteModels count: %d",_noteViews.count,_noteEntryModels.count);
    int max = _sectionZeroRowOneVisible ? _noteEntryModels.count + 1 : _noteEntryModels.count;
    if (self.view.subviews.count > max) {
        NSMutableArray *staleViews = [[NSMutableArray alloc] initWithCapacity:_noteViews.count];
        for (int i = max; i < self.view.subviews.count; i++) {
            UIView *subview = [[self.view subviews] objectAtIndex:i];
            if ([subview isKindOfClass:[NoteEntryCell class]]) {
                [staleViews addObject:subview];
            }
        }
        
        //NSLog(@"trimmed %d",staleViews.count);
        for (UIView *view in staleViews) {
            [view removeFromSuperview];
        }
        [_noteViews removeObjectsInArray:staleViews];
    }
        
    float y = 0.0;
    
    int cellIndex = _noteViews.count;
    // _noteEntryModels.count
    
    while (cellIndex<[_tableView indexPathsForVisibleRows].count) {
        
        UIView *noteView = nil;
        //int secZeroViewIndex = [_noteViews indexOfObject:[self.view viewWithTag:SECZERO_ROWZERO_TAG]];
        if (cellIndex ==_sectionZeroCellIndex){//secZeroViewIndex == NSNotFound && _sectionZeroRowOneVisible) {//cellIndex ==_sectionZeroCellIndex &&
            cellIndex++;
            continue;
            //_sectionZeroRowOneVisible){
            //noteView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            //noteView.tag = SECZERO_ROWZERO_TAG;
        } else {
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
            noteView = (NoteEntryCell *)[views lastObject];
        }
        
        [noteView setFrameY:y];
        
        if (NO) {
            [noteView.layer setBorderColor:[self randomColor].CGColor];
            [noteView.layer setBorderWidth:3.0];
        }
        
        [noteView setClipsToBounds:NO];
        //[self debugView:noteCell.subtitleLabel color:[UIColor greenColor]];
        
        [self.view addSubview:noteView];
        
        y += noteView.frame.size.height;
        if (noteView.tag == SECZERO_ROWZERO_TAG) {
            [_noteViews insertObject:noteView atIndex:0];
        } else {
            [_noteViews addObject:noteView];
        }
        
        [self.view addSubview:noteView];
        
        cellIndex++;
    }
}

- (BOOL)removeSectionZeroRowOne
{
    UIView *sectionZeroRowOne = nil;
    
    for (UIView *view in _noteViews) {
        if (![view isKindOfClass:[NoteEntryCell class]]) {
            sectionZeroRowOne = view;
            break;
        }
    }
    
    if (sectionZeroRowOne) {
        [_noteViews removeObject:sectionZeroRowOne];
        [sectionZeroRowOne removeFromSuperview];
        sectionZeroRowOne = nil;
        return YES;
    }
    
    return NO;
}

- (void)updateCellsWithModels
{
    int i = 0;
    for (NoteEntry *noteEntry in _noteEntryModels) {

        NoteEntryCell *noteCell = [_noteViews objectAtIndex:i];
        if (i==_sectionZeroCellIndex){
            i++;
            continue;
        }
        
        
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
        
        if (![noteCell respondsToSelector:@selector(setRelativeTimeText:)]) {
//NSLog(@"stop!");
        }
        noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
        
        noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
        [noteCell.subtitleLabel setText:noteEntry.title];
        noteCell.relativeTimeText.text = [noteEntry relativeDateString];
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        
        circle.textColor = noteCell.subtitleLabel.textColor;
        circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
        circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
        
        i++;
    }
    
    NoteEntryCell *lastCell = [_noteViews lastObject];
    //UIColor *color = lastCell.contentView.backgroundColor;
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (int)indexOfNoteView:(UIView *)view accountForSectionZero:(BOOL)account
{
    int index = [_noteViews indexOfObject:view];
    if (account) {
        if (_sectionZeroRowOneVisible) {
            index --;
        }
    }
    
    return index;
}

- (UIView *)viewAtIndex:(NSInteger)index
{
    return (NoteEntryCell *)[_noteViews objectAtIndex:index];
}

- (int)documentCount
{
    return [[ApplicationModel sharedInstance] currentNoteEntries].count;
}

- (BOOL)currentNoteIsLast
{
    int viewIndex = [self indexOfNoteView:[self currentNote] accountForSectionZero:NO];
//NSLog(@"Reporting that current note with index %d is last: %s",viewIndex,viewIndex == _noteViews.count-1 ? "yes" : "no");
    return viewIndex == _noteViews.count-1;
}

- (BOOL)noteIsLast:(int)index
{
    BOOL yeppers = index == _noteViews.count-1;
    if (yeppers) {
        if (index==4) {
//NSLog(@"uh oh again");
        }
//NSLog(@"reporting that index %d is last",index);
    }
    return yeppers;
}

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)sectionZeroVisible
{
    return [self isVisibleRow:0 inSection:0];
}

- (BOOL)isVisibleRow:(int)row inSection:(int)section
{
    CGRect cellRect = [_tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
    cellRect = [_tableView convertRect:cellRect toView:_tableView.superview];
    BOOL completelyVisible = CGRectIntersectsRect(_tableView.frame, cellRect);
    
    return completelyVisible;
}

@end
