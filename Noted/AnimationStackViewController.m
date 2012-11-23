//
//  StackViewController.m
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "AnimationStackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "StackViewItem.h"
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

typedef enum {
    kOpening,
    kClosing
} AnimationDirection;

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200
#define SECZERO_ROWZERO_TAG 687
#define NOTE_TAG            697
#define SHADOW_TAG          56
#define SHADOW_TAG_DUP      57

#define DEBUG_ANIMATIONS    1
#define DEBUG_VIEWS         0

#define IS_NOTE_SECTION(indexPath) indexPath.section==1

static const float  kAnimationDuration      = 0.5;
static const float  kDebugAnimationDuration = 2.5;
static const float  kCellHeight             = 66.0;

@interface AnimationStackViewController ()
{
    UITableView *_tableView;
    UITextView *_placeholderText;
    
    StackState _state;
    
    //NSMutableArray *_noteEntryModels;
    
    BOOL _sectionZeroRowOneVisible;
    //int _sectionZeroCellIndex;
    
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
    
    NoteEntryCell *currentNoteCell;
    NoteEntryCell *firstNoteCell;
    NoteEntryCell *lastNoteCell;
    BOOL currentNoteIsLast;
    
    NSMutableArray *_stackItems;
    StackViewItem *_activeStackItem;
    NSMutableDictionary *_stackViews;
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
        //_sectionZeroCellIndex = -1;
        //_noteEntryModels = [[NSMutableArray alloc] init];
        
        _stackItems = [[NSMutableArray alloc] init];
        _stackViews = [[NSMutableDictionary alloc] init];
        
        [self.view setBackgroundColor:[UIColor whiteColor]];
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

- (BOOL)updatedStackItemsForIndexPath:(NSIndexPath *)selectedIndexPath andDirection:(AnimationDirection)direction {
    
    NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
    
    if (direction==kClosing) {
        if ([_tableView numberOfRowsInSection:1]>2 && visibleIndexPaths.count==2) {
            NSIndexPath *next = [NSIndexPath indexPathForRow:selectedIndexPath.row-1 inSection:1];
            [_tableView scrollToRowAtIndexPath:next atScrollPosition:UITableViewScrollPositionTop animated:NO];
            visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        }
    }
    
    _sectionZeroRowOneVisible = YES;
    NSIndexPath *firstVisibleNote = [visibleIndexPaths objectAtIndex:1];
    
    if (IS_NOTE_SECTION(firstVisibleNote)) {
        firstVisibleNote = [visibleIndexPaths objectAtIndex:0];
        _sectionZeroRowOneVisible = NO;
    }
    
    if (selectedIndexPath.row < firstVisibleNote.row) {
        // scrolling too fast, or some other weirdness
        return NO;
    }
    
    [_stackItems removeAllObjects];
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    [self.view setFrame:appFrame];
    _selectedViewIndex = 0;
    currentNoteIsLast = NO;
    
    _selectedViewIndex = selectedIndexPath.row - [firstVisibleNote row];
    
    NSArray *allNoteEntries = [[[ApplicationModel sharedInstance] currentNoteEntries] array];
    int i = 0;
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        StackViewItem *item = [[StackViewItem alloc] initWithIndexPath:indexPath];
        UITableViewCell *cell = nil;
        if (!IS_NOTE_SECTION(indexPath)) {
            
            [item setIsNoteEntry:NO];
            
            cell = (UITableViewCell *)[self.view viewWithTag:SECZERO_ROWZERO_TAG];
            if (!cell) {
                NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:self options:nil];
                
                cell = (UITableViewCell *)[views objectAtIndex:0];
                [NewNoteCell configure:(NewNoteCell *)cell];
                [cell setFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
                cell.tag = SECZERO_ROWZERO_TAG;
                [item setCell:cell];
                [item setNoteEntry:(id)[NSNull null]];
            }
        } else {
            
            cell = [self cellForIndex:i];
            [item setCell:cell];
            [item setNoteEntry:[allNoteEntries objectAtIndex:indexPath.row]];
            
            NSString *key = [NSNumber numberWithInt:i].stringValue;
            [_stackViews setObject:cell forKey:key];
            
            if (i==0) {
                [item setIsFirst:YES];
                firstNoteCell = (NoteEntryCell *)cell;
            }
            [item setIndex:i];
            [item setIsNoteEntry:YES];
            
            if ([indexPath isEqual:[visibleIndexPaths lastObject]]) {
                [item setIsLast:YES];
                lastNoteCell = (NoteEntryCell *)cell;
            }
            
            if ([indexPath isEqual:selectedIndexPath]) {
                [item setIsActive:YES];
                currentNoteCell = (NoteEntryCell *)cell;
                _activeStackItem = item;
                if (item.isLast) {
                    currentNoteIsLast = YES;
                } else {
                    currentNoteIsLast = NO;
                }
            } else {
                int offsetIndex = -(_selectedViewIndex - i);
                [item setOffsetFromActive:offsetIndex];
            }
            
            CGRect rect = CGRectZero;
            if (direction==kClosing) {
                
                // where it should animate to
                rect = [_tableView rectForRowAtIndexPath:indexPath];
                rect = [_tableView.superview convertRect:rect fromView:_tableView];
                if (item.isActive) {
                    _centerNoteDestinationFrame = rect;
                }
                
                // where it should animate from
                int offsetIndex = item.offsetFromActive;
                float baselineYOffset = offsetIndex < 0 ? 0.0 : self.view.bounds.size.height;
                float offsetFactor = offsetIndex < 0 ? offsetIndex : offsetIndex-1;
                float yOrigin = baselineYOffset+ offsetFactor*kCellHeight;
                [item setStartingFrame:CGRectMake(0.0, yOrigin, 320.0, kCellHeight)];
                
            } else if (direction==kOpening) {
                if (item.isActive) {
                    rect = [[UIScreen mainScreen] applicationFrame];
                } else {
                    if (item.isLast) {
                        rect = CGRectMake(0.0, self.view.bounds.size.height, 320.0, 200.0); // arbitrary height?
                    } else {
                        float yOrigin = item.offsetFromActive > 0 ? self.view.bounds.size.height : 0.0;
                        rect = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                    }
                }
            }
            [item setDestinationFrame:rect];
            
            i ++;
        }
        
        [_stackItems addObject:item];
        
        for (StackViewItem *item in _stackItems) {
            UITableViewCell *cell = item.cell;
            [self.view addSubview:cell];
        }
        
        if (direction==kOpening) {
            [self.view addSubview:currentNoteCell];
        }
        
        [self debugView:currentNoteCell color:[UIColor redColor]];
    }
    
    return YES;
}

- (UITableViewCell *)cellForIndex:(NSUInteger)index
{
    UITableViewCell *cell = nil;

    NSString *key = [NSNumber numberWithInt:index].stringValue;
    cell = (UITableViewCell *)[_stackViews objectForKey:key];
    if (!cell) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        cell = (UITableViewCell *)[views lastObject];
        [cell setClipsToBounds:NO];
        
        cell.contentView.backgroundColor = [self randomColor];
    }
    
    [_stackViews setObject:cell forKey:key];
    [self debugView:currentNoteCell color:[UIColor clearColor]];
    
    return cell;
}

#pragma mark Pinch to collapse animation

- (void)prepareForCollapse
{
    NSIndexPath *selectedIndexPath = [_tableView indexPathForSelectedRow];
    
    if (![self updatedStackItemsForIndexPath:selectedIndexPath andDirection:kClosing]) {
        return;
    }
    
    if (DEBUG_VIEWS) {
        
        DrawView *debug = (DrawView *)[self.view viewWithTag:888];
        if (debug) {
            [debug removeFromSuperview];
        }
        
        debug = [[DrawView alloc] initWithFrame:self.view.bounds];
        [debug setUserInteractionEnabled:NO];
        [debug setTag:888];
        [debug setBackgroundColor:[UIColor clearColor]];
        
        [debug setDrawBlock:^(UIView* v,CGContextRef context){
            
            for (StackViewItem *item in _stackItems) {
                
                CGRect frame = item.destinationFrame;
                UIBezierPath* bezierPath = [UIBezierPath bezierPath];
                if (!item.isActive) {
                    [[UIColor blueColor] setStroke];
                    bezierPath.lineWidth = 1.0;
                } else {
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

    }
   
    /*
     if (originFrames) {
     [originFrames removeAllObjects];
     }
     originFrames = [[NSMutableArray alloc] initWithCapacity:_tableView.indexPathsForVisibleRows.count];
     BOOL secZeroRowOne = [self sectionZeroRowOneVisible];
     [_stackItems enumerateObjectsUsingBlock:^(id obj,NSUInteger index,BOOL *stop) {
     StackViewItem *item = (StackViewItem *)obj;
     if (item.isActive) {
     [originFrames addObject:[NSNull null]];
     } else {
     
     int offsetIndex = item.offsetFromActive;
     float baselineYOffset = offsetIndex < 0 ? 0.0 : self.view.bounds.size.height;
     float offsetFactor = offsetIndex < 0 ? offsetIndex : offsetIndex-1;
     float yOrigin = baselineYOffset+ offsetFactor*kCellHeight;
     CGRect frame = CGRectMake(0.0, yOrigin, 320.0, kCellHeight);
     if (secZeroRowOne) {
     if (index==0) {
     //NSLog(@"subview with class %@",NSStringFromClass([[_noteViews objectAtIndex:index] class]));
     frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0);
     }
     }
     [originFrames addObject:[NSValue valueWithCGRect:frame]];
     
     }
     }];
     */
    
    [self setNotesToCollapseBeginPositions:NO];
    
    //NSLog(@"%i %i %i %i   [%i]",destinationFrames.count,_noteViews.count,originFrames.count,_tableView.indexPathsForVisibleRows.count,__LINE__);
    //NSAssert(destinationFrames.count==_noteViews.count, @"destinationFrames count should equal noteViewscount");
    //NSAssert(originFrames.count==_noteViews.count, @"originFrames count should equal noteViews count");
    //NSAssert(originFrames.count==destinationFrames.count, @"originFrames count should equal destinationFrames count");
    
    UIView *fullText = [currentNoteCell.contentView viewWithTag:FULL_TEXT_TAG];
    if (currentNoteIsLast) {
        fullText.alpha = 1.0;
        currentNoteCell.subtitleLabel.alpha = 0.0;
    }
}

// hack fix
/*
 - (void)pruneSubviews
 {
 int count = 0;
 for (int i = 0; i < self.view.subviews.count; i++) {
 UIView *view = (UIView *)[self.view.subviews objectAtIndex:i];
 if (view.tag != 888) {
 count++;
 //NSLog(@"subview with class %@ and frame %@",NSStringFromClass([view class]),NSStringFromCGRect(view.frame));
 if (![_noteViews containsObject:view]) {
 [view removeFromSuperview];
 }
 } else {
 //NSLog(@"detected debug view");
 }
 }
 }
 */


- (void)setNotesToCollapseBeginPositions:(BOOL)animated
{
    __block UIView *prevNote = nil;
    
    [_stackItems enumerateObjectsUsingBlock:^(id obj,NSUInteger index,BOOL *stop) {
        
        StackViewItem *item = (StackViewItem *)obj;
        UITableViewCell *cell = item.cell;
        if (item.isFirst) {
            UIView *shadow2 = [cell viewWithTag:SHADOW_TAG_DUP];
            [shadow2 setHidden:NO];
        }
        
        if (!item.isActive) {
            
            UIView *shadow = [cell viewWithTag:SHADOW_TAG];
            float h = [self noteIsLast:cell] ? CGRectGetMaxY(cell.frame)+7.0 : kCellHeight;
            [shadow setFrameY:h-7];
            
            CGRect frame = [item startingFrame];
            if (animated) {
                [UIView animateWithDuration:kAnimationDuration
                                 animations:^{
                                     [cell setFrame:frame];
                                 }
                                 completion:nil];
                
            } else {
                [cell setFrame:frame];
            }
            
            int offsetIndex = [item offsetFromActive];
            if (offsetIndex < 0) {
                [self.view insertSubview:cell belowSubview:currentNoteCell];
            } else {
                if (prevNote) {
                    [self.view insertSubview:cell belowSubview:prevNote];
                }
            }
            prevNote = cell;
        }
    }];
}

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    _pinchPercentComplete = pinchPercent;
    
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
        
        UITextView *textView = [self makeFullTextForStackItem:_activeStackItem];
        [textView setHidden:NO];
    }
    
    [self collapseCurrentNoteWithScale:scale];
    [self shrinkStackedNotesForScale:scale];
}

- (void)shrinkStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < _stackItems.count; i ++) {
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

- (UITextView *)makeFulltextViewForCell:(UITableViewCell *)cell
{
    CGRect frame = self.view.bounds;
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, cell.frame.size.height)];
    
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
    StackViewItem *item = [_stackItems objectAtIndex:index];
    
    if (item.isActive) {
        return;
    }

    NoteEntryCell *cell = (NoteEntryCell *)item.cell;
    
    CGRect destinationFrame = item.destinationFrame;//;[(NSValue *)[destinationFrames objectAtIndex:index] CGRectValue];
    
    CGRect originFrame = item.startingFrame;[(NSValue *)[originFrames objectAtIndex:index] CGRectValue];
    
    CGFloat startY = originFrame.origin.y;
    CGFloat destY = destinationFrame.origin.y;
    
    float diff = -(startY-destY);
    diff = diff*_pinchPercentComplete;
    CGFloat newY = startY;
    
    UITextView *textView = [self makeFullTextForStackItem:item];
    [textView setHidden:YES];
    [cell.subtitleLabel setHidden:NO];
    cell.subtitleLabel.alpha = 1.0;
    
    if (diff == 0 && _pinchPercentComplete == 1.0) {
        
        newY = destY;
    } else {
        newY = startY + diff;

    }
    
    [self updateSubviewsForNote:cell scaled:YES];
    
    float newHeight = kCellHeight;
    
    if ([self noteIsLast:cell]) {
        [textView setHidden:NO];
        [cell.subtitleLabel setHidden:YES];
        newHeight = kCellHeight + (destinationFrame.size.height - kCellHeight)*_pinchPercentComplete;
    }
    
    CGRect newFrame = CGRectMake(0.0, newY, self.view.bounds.size.width, newHeight);
    [cell setFrame:newFrame];

}

- (void)collapseCurrentNoteWithScale:(CGFloat)scale
{
    float destHeight = _centerNoteDestinationFrame.size.height;
    
    float diff = self.view.bounds.size.height-destHeight;
    float newHeight = (self.view.bounds.size.height-(_pinchPercentComplete*diff));
    
    //NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
    //NSLog(@"dest height: %f",destHeight);
    //NSLog(@"diff: %f",diff);
    
    [self updateSubviewsForNote:currentNoteCell scaled:YES];
    
    float centerFactor = currentNoteIsLast ? 1.0 : 0.5;
    float newY = 0.0;;
    if (currentNoteIsLast) {
        newY = (self.view.bounds.size.height-newHeight)*centerFactor;
    } else {
        newY = _centerNoteDestinationFrame.origin.y*_pinchPercentComplete;

    }
    
    //NSLog(@"new y: %f",newY);
    
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
    
    UIView *fullText = [self makeFullTextForStackItem:_activeStackItem];
        
    if (currentNoteIsLast) {
        newHeight = self.view.bounds.size.height - newY;
    } else {
        float factor = 1.0-((1.0-_pinchPercentComplete)*.3);
        fullText.alpha = 1.0-(_pinchPercentComplete*factor);
        currentNoteCell.subtitleLabel.alpha = _pinchPercentComplete+factor;
    }
    
    _centerNoteFrame = CGRectMake(0.0, newY, self.view.bounds.size.width, newHeight);
    
    UIView *shadow = [currentNoteCell viewWithTag:SHADOW_TAG];
    float sY = newHeight-7.0;
    [shadow setFrameY:sY];
    
    [currentNoteCell setFrame:_centerNoteFrame];
    
}

- (void)finishCollapse:(void(^)())complete
{
    complete();
    _pinchPercentComplete = 0.0;
    [self.view setFrameX:-320.0];
    
     for (UITableViewCell *cell in _noteViews) {
         UIView *shadow2 = [cell viewWithTag:SHADOW_TAG_DUP];
         //[shadow2 setHidden:YES];
     }
}

- (UITextView *)makeFullTextForStackItem:(StackViewItem *)item
{
    UITableViewCell *cell = item.cell;
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:FULL_TEXT_TAG];
    UILabel *subtitle = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
    
    NoteEntry *noteEntry = item.noteEntry;
    
    if (!textView) { // if it doesn't have it, add it and hide title text
        textView = [self makeFulltextViewForCell:cell];
        [cell.contentView addSubview:textView];
    }
    
    BOOL isCurrentAndLast = currentNoteIsLast && [cell isEqual:currentNoteCell];
    if (_pinchPercentComplete > 0.0 && !isCurrentAndLast && !item.isLast) {
        NSString *text = noteEntry.text;
        NSRange range = [text rangeOfString:@"\n"];
        if (range.location != NSNotFound) {
            text = [text stringByReplacingCharactersInRange:NSMakeRange(0, range.location) withString:@""];
        }
        textView.text = text;
    } else {
        textView.text = noteEntry.text;
    }
    
    textView.textColor = subtitle.textColor;
    [textView setHidden:NO];
    
    return textView;
}

- (void)showFullTextForOpeningNote:(StackViewItem *)item animated:(BOOL)animated
{
    UITextView *textView = [self makeFullTextForStackItem:item];

    UILabel *subtitle = (UILabel *)[item.cell.contentView viewWithTag:LABEL_TAG];
    
    if (animated) {
        textView.alpha = 0.0;
        [UIView animateWithDuration:[self animationDuration]*0.4
                         animations:^{
                             
                             textView.alpha = 1.0;
                             subtitle.alpha = 0.0;
                             
                         }
                         completion:^(BOOL finished){
                             subtitle.alpha = 0.0;
                         }];
    } else {
        textView.alpha = 1.0;
        subtitle.alpha = 0.0;
    }
}


- (void)updateNoteText
{
    NoteEntryCell *noteCell = (NoteEntryCell *)_activeStackItem.cell;
    UITextView *fullText = (UITextView *)[noteCell.contentView viewWithTag:FULL_TEXT_TAG];
    NoteEntry *noteEntry = _activeStackItem.noteEntry;
    NSString *newText = noteEntry.text;

    fullText.text = newText;
    noteCell.subtitleLabel.text = newText;
    
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
    
    noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
}

- (void)logSubviewsAndMisc
{
    NSLog(@"count of all cells: %d",_noteViews.count);
    NSLog(@"count of all subviews before opening: %d",self.view.subviews.count);
    NSLog(@"count of note entry cells: %d",[self noteEntryViewsCount]);
    NSLog(@"count of visible rows: %d",[_tableView indexPathsForVisibleRows].count);
    NSLog(@"active index: %i",_selectedViewIndex);
}

#pragma mark Tap to open animation

- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    if (![self updatedStackItemsForIndexPath:selectedIndexPath andDirection:kOpening]) {
        return;
    }

    [self.view setFrameX:0.0];
    
    _animating = YES;

    for (StackViewItem *item in _stackItems) {
        
        NoteEntryCell *modelCellView = (NoteEntryCell* )[_tableView cellForRowAtIndexPath:item.indexPath];
        
        NoteEntryCell *cell = (NoteEntryCell *)item.cell;
        CGRect frame = [_tableView convertRect:modelCellView.frame toView:[_tableView superview]];
        cell.frame = frame;
        
        UIView *shadow = [cell viewWithTag:SHADOW_TAG];
        float shadowHeight = 7.0;
        [shadow setFrameY:-shadowHeight];
        [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        
        UILabel *circle = (UILabel *)[cell viewWithTag:78];
        [circle setHidden:NO];
        
        if (item.isActive) {
            [self openCurrentNoteWithCompletion:completeBlock];
        } else {
            [self openNote:item isLast:item.isLast isBelow:item.offsetFromActive>0];
        }
        
        NSLog(@"%@",item.description);
    }
}

- (NSRange)rangeForNoteViews
{
    return NSMakeRange(0,_noteViews.count);
}

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
    if (currentNoteIsLast) {
        [self showFullTextForOpeningNote:_activeStackItem animated:NO];
    } else {
        [self showFullTextForOpeningNote:_activeStackItem animated:YES];
    }
    
    [UIView animateWithDuration:[self animationDuration]
                     animations:^{
                         
                        [_activeStackItem.cell setFrame:_activeStackItem.destinationFrame];
                         _activeStackItem.cell.layer.cornerRadius = 6.0;
                         
                         // transistion its subviews
                         UILabel *circle = (UILabel *)[_activeStackItem.cell viewWithTag:78];
                         [circle setHidden:NO];
                         circle.alpha = 1.0;
                         
                     }
                     completion:^(BOOL finished){
                         _animating = NO;
                         completeBlock();
                         
                         [self finishExpansion];
                         
                     }];
}

- (void)openNote:(StackViewItem *)item isLast:(bool)isLast isBelow:(BOOL)isBelow
{
    if (isLast) {
        [self showFullTextForOpeningNote:item animated:NO];
    } 
    
    float duration = DEBUG_ANIMATIONS ? kDebugAnimationDuration : kAnimationDuration;
    [UIView animateWithDuration:duration
                     animations:^{
                         
                        [item.cell setFrame:item.destinationFrame];
                         
                         // transistion its subviews
                         UILabel *circle = (UILabel *)[item.cell viewWithTag:78];
                         circle.alpha = 1.0;
                     }
                     completion:nil];
}

- (void)finishExpansion
{
    [self.view setFrameX:-320.0];
}

- (void)resetToExpanded:(void(^)())completion
{
    _pinchPercentComplete = 0.0;
    [self setNotesToCollapseBeginPositions:YES];
    
    // just the active note
    [UIView animateWithDuration:0.5
                     animations:^{
                         [currentNoteCell setFrame:self.view.bounds];
                         if (!currentNoteIsLast) {
                             [[currentNoteCell viewWithTag:FULL_TEXT_TAG] setAlpha:1.0];
                             [[currentNoteCell viewWithTag:LABEL_TAG] setAlpha:0.0];
                         }
                         
                         [[currentNoteCell viewWithTag:SHADOW_TAG] setFrameY:CGRectGetMaxY(self.view.bounds)];
                         
                     }
                     completion:^(BOOL finished){
                         [self finishExpansion];
                         //[self pruneSubviews];
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
    finalY = _centerNoteDestinationFrame.origin.y;
    return finalY;
}

- (NoteEntry *)currentNoteEntry
{
    return [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];
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

/*
 - (void)updateCellsWithModels
 {
 int i = 0;
 for (NoteEntry *noteEntry in _noteEntryModels) {
 
 NoteEntryCell *noteCell = [_noteViews objectAtIndex:i];
 if (i==_sectionZeroCellIndex&&[self sectionZeroVisible]){
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
 
 noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
 
 noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
 [noteCell.subtitleLabel setText:noteEntry.title];
 UITextView *fullText = (UITextView *)[noteCell.contentView viewWithTag:FULL_TEXT_TAG];
 if (fullText) {
 fullText.text = noteEntry.text;
 }
 noteCell.relativeTimeText.text = [noteEntry relativeDateString];
 
 UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
 
 circle.textColor = noteCell.subtitleLabel.textColor;
 circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
 circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
 
 i++;
 }
 
 //NoteEntryCell *lastCell = [_noteViews lastObject];
 //UIColor *color = lastCell.contentView.backgroundColor;
 
 [self.view setBackgroundColor:[UIColor whiteColor]];
 }
 */

- (int)indexOfNoteView:(UIView *)view
{
    return [_noteViews indexOfObject:view];
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
    int viewIndex = [self indexOfNoteView:currentNoteCell];
    
    if (viewIndex == NSNotFound) {
        NSLog(@"wtf");
    }
    
    return [self noteIsLast:currentNoteCell];
}

- (BOOL)noteIsLast:(UIView *)noteView
{
    int viewIndex = [self indexOfNoteView:noteView];
    int lastIndex = _noteViews.count-1;
    
    return viewIndex == lastIndex;
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
