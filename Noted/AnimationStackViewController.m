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

#define FULL_TEXT_TAG       190
#define LABEL_TAG           200
#define DEBUG_ANIMATIONS    0

static const float  kAnimationDuration      = 0.5;
static const float  kDebugAnimationDuration = 2.5;
static const float  kCellHeight             = 66.0;

@interface AnimationStackViewController ()
{
    UITableView *_tableView;
    UITextView *_placeholderText;
    
    StackState _state;
    
    NSRange _noteViewRange;
    NSRange _noteModelRange;
    NSMutableArray *_noteEntryModels;
    
    BOOL _shouldOffset;
    BOOL _isPinching;
    BOOL _animating;
    float _pinchPercentComplete;
    int _selectedViewIndex;
    
    CGRect _centerNoteFrame;
    
    NSMutableArray *stackingViews;
    NSMutableArray *_noteViews;
}

@property (weak, nonatomic) IBOutlet UIView *bottomExtender;

@end

@implementation AnimationStackViewController

@synthesize noteViews=_noteViews;
@synthesize tableView=_tableView;

- (id)init
{
    self = [super initWithNibName:@"AnimationStackView" bundle:nil];
    if (self){
        _isPinching = NO;

        _noteViews = [[NSMutableArray alloc] init];
        _centerNoteFrame = CGRectZero;
        _animating = NO;
        
        _state = kNoteStack;
        _noteEntryModels = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setUserInteractionEnabled:NO];
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)prepareForAnimationState:(StackState)state withParentView:(UIView *)view
{
    _state = state;
    if (!_animating) {
        [self.view setFrameX:-self.view.bounds.size.width];
    }
    
    if (_state==kTableView) {
        _selectedViewIndex = [_tableView indexPathForSelectedRow].row;
    } else if (_state==kNoteStack) {
        _selectedViewIndex = [ApplicationModel sharedInstance].selectedNoteIndex;
        
        UIColor *bottomColor = [(UIView *)[[stackingViews lastObject] objectForKey:@"noteView"] backgroundColor];
        [self.view setBackgroundColor:bottomColor];
    }
    
    _noteModelRange = [self rangeForNoteModels];
    NSLog(@"from index %d to, but not including, %d+%d",_noteModelRange.location,_noteModelRange.location,_noteModelRange.length);
    NSLog(@"First note model at index %d and last note at index %d",_noteModelRange.location,_noteModelRange.location+_noteModelRange.length-1);
    int max = _noteModelRange.location + _noteModelRange.length;
    [_noteEntryModels removeAllObjects];
    NSArray *allEntries = [[[ApplicationModel sharedInstance] currentNoteEntries] array];
    for (int i = _noteModelRange.location; i < max; i ++) {
        [_noteEntryModels addObject:[allEntries objectAtIndex:i]];
    }
    
    NSAssert(_noteModelRange.length>0, @"_noteModelRange length should be non-zero");
    NSAssert(_noteEntryModels.count>0, @"_noteEntryModels should be positive");
    
    [self trimCellViews];
    [self updateCellsWithModels];
    // use this range anytime we're accessong note entrie models

    // use this range anytime we're accessing note views
    _noteViewRange = [self rangeForNoteViews];
    
    NSLog(@"from %d to, but not including, %d+%d",_noteViewRange.location,_noteViewRange.location,_noteViewRange.length);
    NSLog(@"State: %@ >>>> First note view at index %d and last note view at index %d",_state==kTableView ? @"tableview" : @"notestack",_noteViewRange.location,(_noteViewRange.location+_noteViewRange.length)-1);
        
    if (![[self.view superview] isEqual:view]) {
        [view addSubview:self.view];
    }

    
    NSLog(@"views ready");
}

#pragma mark Pinch to collapse animation



- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    _pinchPercentComplete = pinchPercent;
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
        [[[self currentNote] viewWithTag:FULL_TEXT_TAG] setHidden:NO];
    }
    
    [self collapseCurrentNoteWithScale:scale];
    [self collapseStackedNotesForScale:scale];
}

- (void)collapseStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < _noteViews.count; i ++) {
        if (i != _selectedViewIndex) {
            [self collapseStackedNoteAtIndex:i withScale:scale];
        }
    }
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
    //NSDictionary *noteDict = [stackingViews objectAtIndex:index];
    
    NoteEntryCell *noteView = [_noteViews objectAtIndex:index];
    
    //int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
    int offset = -(_selectedViewIndex - index);
    float currentNoteOffset = 0.0;
    
    float newHeight = kCellHeight;
    float newY = 0.0;
    if (offset<0) {
        currentNoteOffset = offset*kCellHeight;
        newY = CGRectGetMinY([self currentNote].frame) + currentNoteOffset;
        
    } else if (offset>0) {
        currentNoteOffset = CGRectGetMaxY([self currentNote].frame) + (offset-1)*kCellHeight;
        newY = currentNoteOffset;
        newHeight = self.view.bounds.size.height-CGRectGetMaxY([self currentNote].frame);
    }
    
    if ([self noteIsLast:[self indexOfNoteView:noteView]]) {
        
        UITextView *textView = (UITextView *)[noteView.contentView viewWithTag:FULL_TEXT_TAG];
        UILabel *subtitle = (UILabel *)[noteView.contentView viewWithTag:LABEL_TAG];
        
        NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtIndex:[self indexOfNoteView:noteView]];;
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
    
    CGRect newFrame = CGRectMake(0.0, floorf(newY), 320.0, newHeight);
    
    [self updateSubviewsForNote:noteView scaled:YES];
    
    [noteView setFrame:newFrame];
}

- (void)collapseCurrentNoteWithScale:(CGFloat)scale
{
    float minusAmount = self.view.bounds.size.height-kCellHeight;
    float newHeight = self.view.bounds.size.height-(minusAmount*_pinchPercentComplete);
    
    NoteEntryCell *currentNoteCell = (NoteEntryCell *)[self currentNote];
    [self updateSubviewsForNote:currentNoteCell scaled:YES];
    
    float newY = (self.view.bounds.size.height-newHeight)*0.5;
    if (newY < 0) {
        newY = 0;
    }
    
    
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
    
    float safety = 0.0;
    self.bottomExtender.frame = CGRectMake(0.0, CGRectGetMaxY(_centerNoteFrame)-safety, self.view.bounds.size.width, self.view.bounds.size.height-CGRectGetMaxY(_centerNoteFrame)+safety);
    
    [currentNoteCell setFrame:_centerNoteFrame];
}

- (void)finishCollapse:(void(^)())complete
{
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
                             // skip the current view
                             if (i == _selectedViewIndex) {
                                 i++; 
                             }
                             
                             UIView *note = [_noteViews objectAtIndex:i];//[noteDict objectForKey:@"noteView"];
                             
                             int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - i);
                             
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
    
    noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
    
    noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
    NSLog(@"Note cell subtitle was: %@, now it's: %@:",noteCell.subtitleLabel.text,noteEntry.title);
}


#pragma mark Tap to open animation

/*
 - (void)prepareForExpandAnimationForView:(UIView *)view offsetForSectionZero:(BOOL)offset
 {
 NSArray *visible = [self visibleNoteSectionRows];
 if (visible.count==0) {
 return;
 }
 
 _shouldOffset = offset;
 [self update];
 
 
 // this can be called any time when iCloud updates
 // so let's not hide it if it's currently animating
 if (!_animating) {
 [self.view setFrameX:-320.0];
 }
 }
 */

- (NSRange)rangeForNoteViews
{
    return NSMakeRange(0,_noteViews.count);
}

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
        
        range = NSMakeRange(beginRange, (endRange-beginRange)+1);
    }
    
    return range;
}

- (NSArray *)visibleNoteSectionRows
{
    NSArray *allVisibleRows = [_tableView indexPathsForVisibleRows];
    NSMutableArray *visibleNoteRows = [[NSMutableArray alloc] initWithCapacity:allVisibleRows.count];
    for (NSIndexPath *indexPath in allVisibleRows) {
        if (indexPath.section!=0) {
            [visibleNoteRows addObject:indexPath];
        }
    }
    
    return visibleNoteRows;
}

- (void)animateOpenForIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    
    [self.view setFrameX:0.0];
    _selectedViewIndex = selectedIndexPath.row;
    _animating = YES;
    
    NSLog(@"count of cells: %d",_noteViews.count);
    
    int j = _noteViewRange.location;
    for (NoteEntryCell *noteCell in _noteViews) {
        int noteViewIndex = [_noteViews indexOfObject:noteCell];
        
        NoteEntryCell *entryCell = (NoteEntryCell* )[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:1]];
        NSLog(@"%@",entryCell.relativeTimeText.text);
        
        BOOL isLastCell = [self noteIsLast:noteViewIndex];
        BOOL isSelectedCell = _selectedViewIndex == j;
        if (isSelectedCell) {
            //_selectedViewIndex = noteViewIndex;
            NSLog(@"selected view is at index %d",_selectedViewIndex);
        }
        
        UIView *shadow = [noteCell viewWithTag:56];
        float shadowHeight = 7.0;
        [shadow setFrameY:-shadowHeight];
        [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect frame = [_tableView convertRect:entryCell.frame toView:[_tableView superview]];
        noteCell.frame = frame;
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        [circle setHidden:NO];
        
        BOOL isBelow = j > _selectedViewIndex;
        
        if (isSelectedCell) {
            [self openCurrentNoteWithCompletion:completeBlock];
        } else {
            [self openNote:noteCell isLast:isLastCell isBelow:isBelow];
        }
        
        j ++;
    }
    
    /*
     for (int i = range.location; i < range.length; i++) {
     
     NoteEntryCell *entryCell = (NoteEntryCell* )[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
     
     NoteEntryCell *noteCell = [_noteViews objectAtIndex:index];
     BOOL isLastCell = [self noteIsLast:i];
     BOOL isSelectedCell = selectedIndexPath.row == i;
     
     UIView *shadow = [noteCell viewWithTag:56];
     float shadowHeight = 7.0;
     [shadow setFrameY:-shadowHeight];
     [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
     
     CGRect frame = [_tableView convertRect:entryCell.frame toView:[_tableView superview]];
     noteCell.frame = frame;
     
     UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
     [circle setHidden:NO];
     
     BOOL isBelow = i > selectedIndexPath.row;
     
     if (isSelectedCell) {
     [self openCurrentNoteWithCompletion:completeBlock];
     } else {
     [self openNote:noteCell isLast:isLastCell isBelow:isBelow];
     }
     
     [UIView animateWithDuration:[self animationDuration]
     animations:^{
     if ([self currentNoteIsLast]) {
     [noteList.lastRowExtenderView setFrameY:CGRectGetMaxY([self currentNote].frame)];
     } else {
     [noteList.lastRowExtenderView setFrameY:CGRectGetMaxY([self lastNote].frame)];
     }
     
     }
     completion:nil];
     //}
     
     index ++;
     }
     
     */
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
    // animate current note back to self.view.bounds
    //int selected = [ApplicationModel sharedInstance].selectedNoteIndex;
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

    int index = 0;
    for (UIView *noteCell in _noteViews) {
        if (index==_selectedViewIndex) {
            index++;
            continue;
        }
        [UIView animateWithDuration:0.5
                         animations:^{
                             if (index < _selectedViewIndex) {
                                 CGRect destinationFrame = CGRectMake(0.0, 0.0, 320.0, 480.0);
                                 [noteCell setFrame:destinationFrame];
                             } else if (index > _selectedViewIndex) {
                                 CGRect destinationFrame = CGRectMake(0.0, 480.0, 320.0, 480.0);
                                 [noteCell setFrame:destinationFrame];
                             }
                         }
                         completion:^(BOOL finished){
                             //NSLog(@"finished animating");
                         }];
        index++;
    }
    
}

/*
 - (void)setUpRangeForStackingForTableView:(BOOL)forTableview
 {
 if (stackingViews) {
 [stackingViews removeAllObjects];
 }
 
 stackingViews = [[NSMutableArray alloc] initWithCapacity:_noteViewRange.length];
 int stackingIndex = 0;
 //int limit = range.length+range.location;
 
 for (NoteEntryCell *noteView in _noteViews) {
 
 if (stackingIndex == _selectedViewIndex) {
 // skip the current doc
 stackingIndex++;
 continue;
 }
 
 //UIView *noteView = [_noteViews objectAtIndex:stackingIndex];
 NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:noteView,@"noteView",[NSNumber numberWithInt:stackingIndex],@"index", nil];
 
 [stackingViews addObject:dict];
 stackingIndex++;
 }
 
 UIColor *bottomColor = [(UIView *)[[stackingViews lastObject] objectForKey:@"noteView"] backgroundColor];
 [self.view setBackgroundColor:bottomColor];
 }
 */

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

// trim the array of views so they
// reflect the number of notes currently in range
// either the visible cells in the tableview, or if
// viewing the ntoestack vc, the range of views to left or right
// 
- (void)trimCellViews
{
    int numTrimmed = 0;
    for (int i = 0; i < _noteViews.count; i++) {
        if (i>_noteEntryModels.count-1) {
            [[_noteViews objectAtIndex:i] removeFromSuperview];
            [_noteViews removeObjectAtIndex:i];
            numTrimmed++;
        }
    }
    NSLog(@"after trimming: count is %d",_noteViews.count);
    NSLog(@"trimmed %d",numTrimmed);
    
    float y = _shouldOffset ? 44.0 : 0.0;
    int numCells = _noteViews.count;
    while (y < self.view.bounds.size.height && numCells<_noteEntryModels.count) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        NoteEntryCell *noteCell = (NoteEntryCell *)[views lastObject];
        [noteCell setFrame:CGRectMake(0.0, y, 320.0, 66.0)];
        
        if (NO) {
            [noteCell.layer setBorderColor:[self randomColor].CGColor];
            [noteCell.layer setBorderWidth:3.0];
        }
        
        [noteCell setClipsToBounds:NO];
        //[self debugView:noteCell.subtitleLabel color:[UIColor greenColor]];
        
        [self.view addSubview:noteCell];
        noteCell.contentView.backgroundColor = [UIColor whiteColor];
        y += noteCell.frame.size.height;
        [_noteViews addObject:noteCell];
        numCells++;
    }
    NSLog(@"Num views: %d Num models %d",_noteViews.count,_noteEntryModels.count);
    if (_noteViews.count != _noteEntryModels.count) {
        NSLog(@"sectionZeroVisible: %s",[self sectionZeroVisible] ? "yes" : "no");
    }
    NSAssert(_noteViews.count==_noteEntryModels.count, @"Display and model objects should have equal count");
}

// this fine for matching cells with models for the main list, when content offset
// is zero, but what about later??
- (void)updateCellsWithModels
{
    int i = 0;
    for (NoteEntry *noteEntry in _noteEntryModels) {
        NoteEntryCell *noteCell = [_noteViews objectAtIndex:i];
        
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
        noteCell.relativeTimeText.text = [noteEntry relativeDateString];
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        
        circle.textColor = noteCell.subtitleLabel.textColor;
        circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
        circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
        
        i++;
    }
    
    NoteEntryCell *lastCell = [_noteViews lastObject];
    UIColor *color = lastCell.contentView.backgroundColor;
    [self.bottomExtender setBackgroundColor:color];
    if (DEBUG_ANIMATIONS) {
        [self.bottomExtender setBackgroundColor:[UIColor redColor]];
        CGRect frame = self.bottomExtender.frame;
        UILabel *label = (UILabel *)[self.bottomExtender viewWithTag:567];
        if (!label) {
            label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, frame.size.height-40.0, 320.0, 40.0)];
            label.text = @"bottom extender view";
            label.tag = 567;
            label.backgroundColor = [UIColor clearColor];
        }
        
        [self.bottomExtender addSubview:label];
    }
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

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
    int viewIndex = [self indexOfNoteView:[self currentNote]];
    return viewIndex == _noteViews.count-1;
}

- (BOOL)noteIsLast:(int)index
{
    BOOL yeppers = index == _noteViews.count-1;
    if (yeppers) {
        NSLog(@"reporting that index %d is last",index);
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
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
    cellRect = [_tableView convertRect:cellRect toView:self.tableView.superview];
    BOOL completelyVisible = CGRectIntersectsRect(self.tableView.frame, cellRect);
    
    return completelyVisible;
}

@end
