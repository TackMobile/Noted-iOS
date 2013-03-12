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

#define IS_NOTE_SECTION(indexPath) indexPath.section==0

static const float  kAnimationDuration      = 0.5;
static const float  kDebugAnimationDuration = 1.5;
static const float  kCellHeight             = 66.0;

@interface AnimationStackViewController ()
{
    UITableView *_tableView;
    
    StackState _state;
        
    BOOL _sectionZeroRowOneVisible;
    
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
    
    AnimationDirection _currentDirection;
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
        //NSLog(@"AnimationStackVC::init");
        
        _isPinching = NO;
        
        _noteViews = [[NSMutableArray alloc] init];
        _centerNoteFrame = CGRectZero;
        _animating = NO;
        
        _state = kNoteStack;
 
        _stackItems = [[NSMutableArray alloc] init];
        _stackViews = [[NSMutableDictionary alloc] init];
        
        [self.view setBackgroundColor:[UIColor clearColor]];
        //[self debugView:self.view color:[UIColor greenColor]];
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
    //NSLog(@"AnimationStackVC::viewDidLoadOptionsViewController");
    
    [self.view setUserInteractionEnabled:NO];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
}

- (BOOL)needsAnimation;
{
    //NSLog(@"AnimationStackVC::needsAnimation");
    BOOL needsAnimation = YES;
    needsAnimation = !CGRectEqualToRect(_activeStackItem.cell.frame, _centerNoteDestinationFrame);
    
    return YES;
}

- (BOOL)updatedStackItemsForIndexPath:(NSIndexPath *)selectedIndexPath andDirection:(AnimationDirection)direction {
    
    NSLog(@"AnimationStackVC::updatedStackItemsForIndexPath %i  %i", selectedIndexPath.row, direction);
    
    [_tableView visibleCells];
    NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
    _currentDirection = direction;
    
     if (direction==kClosing) {
         int modelCount = [[ApplicationModel sharedInstance] currentNoteEntries].count;
         if (_activeStackItem.indexPath.row == modelCount-1) {
             float offset = _tableView.contentOffset.y;
             offset -= 99.0;
             if (offset < 0.0) {
                 offset = 0.0;
             }
             [_tableView setContentOffset:CGPointMake(0.0, offset) animated:NO];
             visibleIndexPaths = [_tableView indexPathsForVisibleRows];
         }
     }
    
    _sectionZeroRowOneVisible = NO;
    NSIndexPath *firstVisibleNote = [visibleIndexPaths objectAtIndex:0];
      
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
        if (IS_NOTE_SECTION(indexPath)) {
            
           cell = [self cellForIndex:i];
            [item setCell:cell];
            [item setNoteEntry:[allNoteEntries objectAtIndex:indexPath.row]];
            
            
            
            if (i==0) {
                [item setIsFirst:YES];
                firstNoteCell = (NoteEntryCell *)cell;
                if (_currentDirection==kOpening) {
                    [cell setClipsToBounds:YES];
                }
            } else {
                [cell setClipsToBounds:NO];
            }
            [item setIndex:i];
            [item setIsNoteEntry:YES];
            
            if ([indexPath isEqual:[visibleIndexPaths lastObject]]) {
                [item setIsLast:YES];
                lastNoteCell = (NoteEntryCell *)cell;
                
            }
            
            if ([indexPath isEqual:selectedIndexPath]) {
                [item setIsActive:YES];
                if (_currentDirection==kOpening){
                    _centerNoteDestinationFrame = self.view.frame;
                }
                currentNoteCell = (NoteEntryCell *)cell;
                CGRect rect = CGRectZero;
                rect = [_tableView rectForRowAtIndexPath:indexPath];
                rect = [_tableView.superview convertRect:rect fromView:_tableView];
                [currentNoteCell setFrame:rect];
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
            if (_currentDirection==kClosing) {
                
                // where it should animate to
                rect = [_tableView rectForRowAtIndexPath:indexPath];
                rect = [_tableView.superview convertRect:rect fromView:_tableView];
                
                if (item.isLast) {
                    rect.size.height = self.view.frame.size.height - rect.origin.y;
                }
                if (item.isActive) {
                    _centerNoteDestinationFrame = rect;
                }
                
                // where it should animate from
                int offsetIndex = item.offsetFromActive;
                float baselineYOffset = offsetIndex < 0 ? 0.0 : self.view.bounds.size.height;
                float offsetFactor = offsetIndex < 0 ? offsetIndex : offsetIndex-1;
                float yOrigin = baselineYOffset+ offsetFactor*kCellHeight;
                if (item.isActive) {
                    [item setStartingFrame:self.view.frame];
                } else {
                    [item setStartingFrame:CGRectMake(0.0, yOrigin, 320.0, kCellHeight)];
                }
                
            } else if (_currentDirection==kOpening) {
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
                
                CGRect originFrame = [_tableView rectForRowAtIndexPath:indexPath];
                originFrame = [_tableView.superview convertRect:originFrame fromView:_tableView];
                item.startingFrame = originFrame;
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
        
    }
    
    //NSLog(@"num of vis index paths %i, num of stack items created for it %i",visibleIndexPaths.count,_stackItems.count);
    
    return YES;
}

- (UITableViewCell *)cellForIndex:(NSUInteger)index
{
    UITableViewCell *cell = nil;
    //NSLog(@"AnimationStackVC::cellForIndex - %i", index);
    
    NSString *key = [NSNumber numberWithInt:index].stringValue;
    cell = (UITableViewCell *)[_stackViews objectForKey:key];
    if (!cell) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        cell = (UITableViewCell *)[views lastObject];
        
        cell.contentView.backgroundColor = [self randomColor];
    }
    
    [_stackViews setObject:cell forKey:key];
    //[self debugView:currentNoteCell color:[UIColor clearColor]];
    
    return cell;
}

#pragma mark Pinch to collapse animation

- (void)prepareForCollapse
{
    NSIndexPath *selectedIndexPath = [_tableView indexPathForSelectedRow];
    NSLog(@"AnimationStackVC::prepareForCollapse - %i", selectedIndexPath.row);
    
    if (![self updatedStackItemsForIndexPath:selectedIndexPath andDirection:kClosing]) {
        return;
    }
    
    if (DEBUG_VIEWS) {
        [self showDebugViews];
    }
    
    [self setNotesToCollapseBeginPositions:NO];
    
    // ??? If collapsing from the last (top) note then this should display the
    // note text in the note cell
    if (currentNoteIsLast) {
        UIView *fullText = [currentNoteCell.contentView viewWithTag:FULL_TEXT_TAG];
        fullText.alpha = 1.0;
        currentNoteCell.subtitleLabel.alpha = 0.0;
    }
}

- (void)showDebugViews
{
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
            const float p[2] = {2, 2.9};
            [bezierPath setLineDash:p count:2 phase:0.3];
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

- (void)setNotesToCollapseBeginPositions:(BOOL)animated
{
    __block UIView *prevNote = nil;
    NSLog(@"AnimationStackVC::setNotesToCollapseBeginPositions animated %i", animated);
    
    [_stackItems enumerateObjectsUsingBlock:^(id obj,NSUInteger index,BOOL *stop) {
        
        StackViewItem *item = (StackViewItem *)obj;
        UITableViewCell *cell = item.cell;
        if (item.isFirst) {
            UIView *shadow2 = [cell viewWithTag:SHADOW_TAG_DUP];
            [shadow2 setHidden:NO];
        }
        
        UIView *shadow = [cell viewWithTag:SHADOW_TAG];
        
        UITextView *textView = (UITextView *)[cell.contentView viewWithTag:FULL_TEXT_TAG];
        
        if (DEBUG_VIEWS) {
            textView.backgroundColor = [UIColor yellowColor];
            textView.textColor = [UIColor purpleColor];
        }
        
        if (item.isLast) {
            [textView setFrameHeight:item.destinationFrame.size.height];
        } else {
            [textView setFrameHeight:item.startingFrame.size.height];
        }
        
        if (!item.isActive) {
            
            float h = item.isLast ? CGRectGetMaxY(cell.frame)+7.0 : kCellHeight;
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
            } else if (offsetIndex>0) {
                if (item.indexPath.row == [[ApplicationModel sharedInstance] currentNoteEntries].count-1) {
                    [self.view addSubview:cell];
                } else if (prevNote) {
                    [self.view insertSubview:cell belowSubview:prevNote];
                }
            }
            prevNote = cell;
        } else {
            NSAssert([_activeStackItem isEqual:item],@"should be active item");
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
        }
    }];
}

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    _pinchPercentComplete = pinchPercent;
    NSLog(@"AnimationStackVC::animateCollapseForScale for _pinchPercentComplete %f, num of stack items: %i",pinchPercent,_stackItems.count);
    
    // If the animation stack view is not on the screen???
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
        
        UITextView *textView = [self makeFullTextForStackItem:_activeStackItem];
        
        if (DEBUG_VIEWS) {
            textView.textColor = [UIColor greenColor];
            textView.backgroundColor = [UIColor redColor];
        }
        
        [textView setHidden:NO];
    }
    
    [self collapseCurrentNoteWithScale:scale];
    [self shrinkStackedNotesForScale:scale];
}

- (void)shrinkStackedNotesForScale:(CGFloat)scale
{
    //NSLog(@"AnimationStackVC::shrinkStackedNotesForScale: %f", scale);
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
    //NSLog(@"AnimationStackVC::noteEntryViewsCount for _pinchPercentComplete %i", count);
    return count;
}

- (UITextView *)textFieldForItem:(StackViewItem *)item
{
    //UITableViewCell *cell = item.cell;
    CGRect frame = self.view.bounds;
    CGRect textFrame = CGRectMake(TEXT_VIEW_X+8, TEXT_VIEW_Y,
                                  frame.size.width, item.startingFrame.size.height);
    
    UITextView *textView = [[UITextView alloc] initWithFrame:textFrame];
    textView.contentInset = UIEdgeInsetsMake(TEXT_VIEW_INSET_TOP,TEXT_VIEW_INSET_LEFT,0,0);
    textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    
    if (DEBUG_VIEWS) {
        textView.backgroundColor = [UIColor yellowColor];
    } else {
        textView.backgroundColor = [UIColor clearColor];
    }
    
    textView.tag = FULL_TEXT_TAG;
    [textView setEditable:NO];
    [textView setUserInteractionEnabled:NO];
    
    //NSLog(@"AnimationStackVC::textFieldForItem: %@", item.noteEntry.title);
    
    return textView;
}

- (void)collapseStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    StackViewItem *item = [_stackItems objectAtIndex:index];
    
    if (item.isActive) {
        return;
    }
    
    NSLog(@"AnimationStackVC::collapseStackedNoteAtIndex: %i", index);

    NoteEntryCell *cell = (NoteEntryCell *)item.cell;
    
    CGRect destinationFrame = item.destinationFrame;
    CGRect originFrame = item.startingFrame;[(NSValue *)[originFrames objectAtIndex:index] CGRectValue];
    
    CGFloat startY = originFrame.origin.y;
    CGFloat destY = destinationFrame.origin.y;
    
    float diff = -(startY-destY);
    diff = diff*_pinchPercentComplete;
    CGFloat newY;
    
    UITextView *textView = [self makeFullTextForStackItem:item];
    [textView setHidden:YES];
    [cell.subtitleLabel setHidden:NO];
    cell.subtitleLabel.alpha = 1.0;
    if (DEBUG_VIEWS) {
        cell.subtitleLabel.textColor = [UIColor redColor];
    }
    
    if (diff == 0 && _pinchPercentComplete == 1.0) {
        newY = destY;
    } else {
        newY = startY + diff;
    }
    
    [self updateSubviewsForNote:cell scaled:YES];
    
    float newHeight = kCellHeight;
    
    if (item.isLast) {
        [textView setHidden:NO];
        [cell.subtitleLabel setHidden:YES];
        newHeight = kCellHeight + (destinationFrame.size.height - kCellHeight)*_pinchPercentComplete;
        
        UIView *shadow = [cell viewWithTag:SHADOW_TAG];
        [shadow setFrameY:CGRectGetMaxY(self.view.frame)];
    }
    
    CGRect newFrame = CGRectMake(0.0, newY, self.view.bounds.size.width, newHeight);
    [cell setFrame:newFrame];
    //NSLog(@"newFrame::%@", NSStringFromCGRect(newFrame));
    
    if (item.indexPath.row == [[ApplicationModel sharedInstance] currentNoteEntries].count-1) {
        [self.view addSubview:cell];
    }
}

- (void)collapseCurrentNoteWithScale:(CGFloat)scale
{
    NSLog(@"AnimationStackVC::collapseCurrentNoteWithScale %f", scale);
    
    float destHeight = _centerNoteDestinationFrame.size.height;
    
    float diff = self.view.bounds.size.height-destHeight;
    float newHeight = (self.view.bounds.size.height - (_pinchPercentComplete * diff) );
    
    //NSLog(@"animation stack view bounds: %@",NSStringFromCGRect(self.view.bounds));
    //NSLog(@"dest height: %f", destHeight);
    //NSLog(@"diff: %f",diff);
    //NSLog(@"new height: %f", newHeight);
    
    [self updateSubviewsForNote:currentNoteCell scaled:YES];
    
    float centerFactor = currentNoteIsLast ? 1.0 : 0.5;
    float newY = 0.0;
    if (currentNoteIsLast) {
        newY = (self.view.bounds.size.height-newHeight)*centerFactor;
    } else {
        newY = _centerNoteDestinationFrame.origin.y * _pinchPercentComplete;
    }  
    
    //NSLog(@"newY: %f", newY);
    
    if (newY < 0) {
        newY = 0;
    } 
    
    UIView *fullText = [self makeFullTextForStackItem:_activeStackItem];
    
    if (currentNoteIsLast) {
        newHeight = self.view.bounds.size.height - newY;
        [fullText setFrameX:TEXT_VIEW_X];
        [fullText setFrameY:TEXT_VIEW_Y];
    } else {
        // [dm] 3-5-13 removing the alpha fade.  not needed now that text truncation is removed in note list text
        //float factor = 1.0 - ((1.0 - _pinchPercentComplete) * .3);
        //fullText.alpha = 1.0 - (_pinchPercentComplete * factor);
        
        CGRect currentFullTextFrame = fullText.frame;
        CGRect newFrame = CGRectMake(TEXT_VIEW_X,
                                     TEXT_VIEW_Y,
                                     currentFullTextFrame.size.width,
                                     newHeight - currentFullTextFrame.origin.y);
        fullText.frame = newFrame;
        
        //currentNoteCell.subtitleLabel.alpha = _pinchPercentComplete+factor;
        currentNoteCell.subtitleLabel.hidden = YES;
    }
    
    _centerNoteFrame = CGRectMake(0.0, newY, self.view.bounds.size.width, newHeight);
    
    UIView *shadow = [currentNoteCell viewWithTag:SHADOW_TAG];
    float sY = newHeight-7.0;
    [shadow setFrameY:sY];
    
    [currentNoteCell setFrame:_centerNoteFrame];
}

- (void)finishCollapse:(void(^)())complete
{
    NSLog(@"AnimationStackVC::finishCollapse");
    
    _pinchPercentComplete = 0.0;
    [self.view setFrameX:-320.0];
    complete();
}

- (UITextView *)makeFullTextForStackItem:(StackViewItem *)item
{
    NSLog(@"AnimationStackVC::makeFullTextForStackItem row %i", item.indexPath.row);

    UITableViewCell *cell = item.cell;
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:FULL_TEXT_TAG];
    UILabel *subtitle = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
    
    NoteEntry *noteEntry = item.noteEntry;
    
    if (!textView) { // if it doesn't have it, add it and hide title text
        textView = [self textFieldForItem:item];
        [cell.contentView addSubview:textView];
    }
    textView.text = noteEntry.text;
    textView.textColor = subtitle.textColor;
    [textView setHidden:NO];
    
    return textView;
}

- (void)showFullTextForOpeningNote:(StackViewItem *)item animated:(BOOL)animated
{
    //NSLog(@"AnimationStackVC::showFullTextForOpeningNote");
    
    UITextView *textView = [self makeFullTextForStackItem:item];

    UILabel *subtitle = (UILabel *)[item.cell.contentView viewWithTag:LABEL_TAG];
    
    if (_currentDirection==kOpening && !item.isLast) {
        subtitle.alpha = 1.0;
    } else {
        subtitle.alpha = 0.0;
    }
    
    if (animated) {
        textView.alpha = 0.0;
        [UIView animateWithDuration:[self animationDuration]*0.4
                         animations:^{
                             textView.alpha = 1.0;
                             subtitle.alpha = 0.0;
                         }
                         completion:nil];
    } else {
        textView.alpha = 1.0;
        subtitle.alpha = 1.0;
    }
}


- (void)updateNoteText
{
    //NSLog(@"AnimationStackVC::updateNoteText");
    
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
        [noteCell.subtitleLabel setTextColor:[UIColor colorWithHexString:@"CCCCCC"]];
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

- (void)openSingleNoteForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    //NSLog(@"AnimationStackVC::openSingleNoteForIndexPath");
    if (![self updatedStackItemsForIndexPath:selectedIndexPath andDirection:kOpening]) {
        return;
    }
    
    [self showFullTextForOpeningNote:_activeStackItem animated:NO];
        
    UITextView *textView = (UITextView *)[_activeStackItem.cell.contentView viewWithTag:FULL_TEXT_TAG];
    [textView setFrameHeight:_activeStackItem.destinationFrame.size.height];
    
    [_activeStackItem.cell setFrame:_activeStackItem.destinationFrame];
    _activeStackItem.cell.layer.cornerRadius = 6.0;
    
    // transition its subviews
    UILabel *circle = (UILabel *)[_activeStackItem.cell viewWithTag:78];
    [circle setHidden:NO];
    circle.alpha = 1.0;
    
    _animating = NO;
    completeBlock();
    
    [self finishExpansion];
    
}

- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    //NSLog(@"AnimationStackVC::animateOpenForIndexPath: %i", selectedIndexPath.row);
    
    if (![self updatedStackItemsForIndexPath:selectedIndexPath andDirection:kOpening]) {
        return;
    }
    
    if (![self needsAnimation]) {
        completeBlock();
        return;
    }

    [self.view setFrameX:0.0];
    
    _animating = YES;
    
    if (_stackItems.count==1) {
        [self openCurrentNoteWithCompletion:completeBlock];
        return;
    }
    
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
        
        //NSLog(@"%@",item.description);
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
    
    //NSLog(@"%@",_activeStackItem);
    NoteEntryCell *cell = (NoteEntryCell *)_activeStackItem.cell;
    
    //NSLog(@"will animate from %@ to %@",NSStringFromCGRect(cell.frame),NSStringFromCGRect(_activeStackItem.destinationFrame));
    
    UITextView *textView = (UITextView *)[_activeStackItem.cell.contentView viewWithTag:FULL_TEXT_TAG];
    [textView setFrameHeight:_activeStackItem.destinationFrame.size.height];
    [textView setFrameWidth:308];
    [textView setFrameOrigin:CGPointMake(12, 35)];
    
    [UIView animateWithDuration:[self animationDuration]
                     animations:^{
                         
                        [cell setFrame:_centerNoteDestinationFrame];
                         cell.layer.cornerRadius = 6.0;
                         
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
                         }
                         
                         [[currentNoteCell viewWithTag:SHADOW_TAG] setFrameY:CGRectGetMaxY(self.view.bounds)];
                         
                     }
                     completion:^(BOOL finished){
                         [self finishExpansion];
                         completion();
                     }];
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 4.0;
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
    //float finalY = (self.view.bounds.size.height-kCellHeight)*0.5;
    //finalY = _centerNoteDestinationFrame.origin.y;
    //return finalY;
    
    return _centerNoteDestinationFrame.origin.y;
}
 

- (NoteEntry *)currentNoteEntry
{
    return [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];
}

/*
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
 */

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

/*
 - (int)indexOfNoteView:(UIView *)view
 {
 return [_noteViews indexOfObject:view];
 }
 
 - (UIView *)viewAtIndex:(NSInteger)index
 {
 return (NoteEntryCell *)[_noteViews objectAtIndex:index];
 }
 */

- (int)documentCount
{
    return [[ApplicationModel sharedInstance] currentNoteEntries].count;
}

/*
 - (BOOL)currentNoteIsLast
 {
 int viewIndex = [self indexOfNoteView:currentNoteCell];
 
 if (viewIndex == NSNotFound) {
 NSLog(@"wtf");
 }
 
 return [self noteIsLast:currentNoteCell];
 }
 */

/*
 - (BOOL)noteIsLast:(UIView *)noteView
 {
 int viewIndex = [self indexOfNoteView:noteView];
 int lastIndex = _noteViews.count-1;
 
 return viewIndex == lastIndex;
 }
 */

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
