//
//  StackViewController.m
//  Noted
//
//  Created by Ben Pilcher on 9/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "StackViewController.h"
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

#define DEBUG_ANIMATIONS 0

static const float  kAnimationDuration      = 0.5;
static const float  kDebugAnimationDuration = 2.5;
static const float  kCellHeight             = 66.0;

@interface StackViewController ()
{
    UITableView *_tableView;
    UITextView *_placeholderText;
    
    BOOL _isPinching;
    BOOL _animating;
    float _pinchPercentComplete;
    int _numCells;
    
    CGRect _centerNoteFrame;
    
    NSMutableArray *stackingViews;
    NSMutableArray *_noteViews;
}

@property (weak, nonatomic) IBOutlet UIView *bottomExtender;

@end

@implementation StackViewController

@synthesize noteViews=_noteViews;

- (id)init
{
    self = [super initWithNibName:@"StackView" bundle:nil];
    if (self){
        _isPinching = NO;
        _numCells = 0;
        _noteViews = [[NSMutableArray alloc] init];
        _centerNoteFrame = CGRectZero;
        _animating = NO;
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
    
    /*
     _placeholderText = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)];
     _placeholderText.text = @"piecemeal beats oatmeal";
     _placeholderText.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
     _placeholderText.backgroundColor = [UIColor clearColor];
     */
}

#pragma mark Pinch to collapse animation

- (void)prepareForCollapseAnimationForView:(UIView *)view
{
    [self setUpRangeForStacking];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    if (![[self.view superview] isEqual:view]) {
        [view addSubview:self.view];
    }
}

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    _pinchPercentComplete = pinchPercent;
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
        [self toggleFullNoteText:[self currentNoteEntry].text inCell:(UITableViewCell *)[self currentNote]];
    }
    
    [self animateCurrentNoteWithScale:scale];
    [self animateStackedNotesForScale:scale];
}

- (void)animateStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < stackingViews.count; i ++) {
        [self animateStackedNoteAtIndex:i withScale:scale];
    }
}

- (void)animateStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    NSDictionary *noteDict = [stackingViews objectAtIndex:index];
    
    UIView *note = [noteDict objectForKey:@"noteView"];
    
    int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
    int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - stackingIndex);
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
        NSLog(@"Note with offset %d getting set to y Origin of %f (%f + (%d-1)*kCellHeight)",offset,newY,CGRectGetMaxY([self currentNote].frame),offset);
    }
    
    CGRect newFrame = CGRectMake(0.0, floorf(newY), 320.0, newHeight);
    
    [self updateSubviewsForNote:note scaled:YES];
    
    [note setFrame:newFrame];
}

- (void)animateCurrentNoteWithScale:(CGFloat)scale
{
    float minusAmount = self.view.bounds.size.height-kCellHeight;
    float newHeight = self.view.bounds.size.height-(minusAmount*_pinchPercentComplete);
    
    [self updateSubviewsForNote:[self currentNote] scaled:YES];
    
    float newY = (self.view.bounds.size.height-newHeight)*0.5;
    if (newY < 0) {
        newY = 0;
    }
    
    if ([self currentNoteIsLast]) {
        newHeight = self.view.bounds.size.height - newY;
    }
    
    _centerNoteFrame = CGRectMake(0.0, newY, 320.0, newHeight);
    
    float safety = 3.0;
    self.bottomExtender.frame = CGRectMake(0.0, CGRectGetMaxY(_centerNoteFrame)-safety, self.view.bounds.size.width, self.view.bounds.size.height-CGRectGetMaxY(_centerNoteFrame)+safety);
    
    [[self currentNote] setFrame:_centerNoteFrame];
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
                         
                         for (int i = 0; i < stackingViews.count; i ++) {
                             NSDictionary *noteDict = [stackingViews objectAtIndex:i];
                             
                             UIView *note = [noteDict objectForKey:@"noteView"];
                             int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
                             
                             int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - stackingIndex);
                             
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
                         [self toggleFullNoteText:@"" inCell:(UITableViewCell *)[self currentNote]];

                     }];
}

#define FULL_TEXT_TAG   190
#define LABEL_TAG       200

- (void)toggleFullNoteText:(NSString *)text inCell:(UITableViewCell *)cell
{
    UITextView *textView = (UITextView *)[cell viewWithTag:FULL_TEXT_TAG];
    UIView *subtitle = [cell.contentView viewWithTag:LABEL_TAG];
    
    if (!textView) { // if it doesn't have it, add it and hide title text
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 250.0)];
        textView.text = text;
        textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        textView.backgroundColor = [UIColor clearColor];
        textView.tag = FULL_TEXT_TAG;
        [cell.contentView addSubview:textView];
        
        [subtitle setHidden:YES];

    } else { // if it has it, hide it and show title text
        
        [textView removeFromSuperview];
        textView = nil;
        [subtitle setHidden:NO];
    }
    
    //[self debugView:textView color:[UIColor redColor]];
}

#pragma mark Tap to open animation

- (void)prepareForExpandAnimationForView:(UIView *)view
{
    [self update];
    
    if (![[self.view superview] isEqual:view]) {
        [view addSubview:self.view];
    }
    
    // this can be called any time when iCloud updates
    // so let's not hide it if it's currently animating
    if (!_animating) {
        [self.view setFrameX:-320.0];
    }
}

- (void)animateOpenForController:(NoteListViewController *)noteList indexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    
    [self.view setFrameX:0.0];
    _animating = YES;
    
    _tableView = noteList.tableView;
    NSArray *cells = _tableView.visibleCells;

    int index = 0;
    for (NoteEntryCell *entryCell in cells) {
        NSIndexPath *indexPath = [noteList.tableView indexPathForCell:entryCell];
        
        if (indexPath.section==0) {
            continue;
        } else {
            
            NoteEntryCell *noteCell = [_noteViews objectAtIndex:indexPath.row];
            BOOL isLastCell = [self noteIsLast:indexPath.row]; // minus 2 to account for section 0
            BOOL isSelectedCell = [selectedIndexPath isEqual:indexPath];
            
            UIView *shadow = [noteCell viewWithTag:56];
            float shadowHeight = 7.0;
            [shadow setFrameY:-shadowHeight];
            [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
            
            CGRect frame = [_tableView convertRect:entryCell.frame toView:[_tableView superview]];
            noteCell.frame = frame;
            
            UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
            [circle setHidden:NO];
            
            BOOL isBelow = indexPath.row > selectedIndexPath.row;
            
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
        }
        
        index ++;
    }
}

- (float)animationDuration
{
    return DEBUG_ANIMATIONS ? kDebugAnimationDuration : kAnimationDuration;
}

- (void)openCurrentNoteWithCompletion:(animationCompleteBlock)completeBlock
{
    NoteEntryCell *noteCell = (NoteEntryCell *)[self currentNote];
    
    NSString *text = [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex].displayText;
    [self toggleFullNoteText:text inCell:noteCell];
    
    [UIView animateWithDuration:[self animationDuration]
                     animations:^{
                         
                         // NSLog(@"current frame of note cell: %@",NSStringFromCGRect(noteCell.frame));
                         CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
                         appFrame.origin.y = 0.0;
                         NSLog(@"cell label frame %@",NSStringFromCGRect(noteCell.subtitleLabel.frame));
                         NSLog(@"subtitleLabel is hidden: %s",noteCell.subtitleLabel.isHidden ? "yes" : "no");
                         NSLog(@"subtitleLabel text: %@",noteCell.subtitleLabel.text);
                         
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
                         [self toggleFullNoteText:@"" inCell:noteCell];
                         
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
    int selected = [ApplicationModel sharedInstance].selectedNoteIndex;
    UIView *current = [_noteViews objectAtIndex:selected];
    [UIView animateWithDuration:0.5
                     animations:^{
                         [current setFrame:self.view.bounds];
                     }
                     completion:^(BOOL finished){
                         [self finishExpansion];
                         completion();
                     }];    

    int index = 0;
    for (UIView *noteCell in _noteViews) {
        if (index==selected) {
            index++;
            continue;
        }
        [UIView animateWithDuration:0.5
                         animations:^{
                             if (index < selected) {
                                 CGRect destinationFrame = CGRectMake(0.0, 0.0, 320.0, 480.0);
                                 [noteCell setFrame:destinationFrame];
                             } else if (index > selected) {
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

- (void)setUpRangeForStacking
{
    if (stackingViews) {
        [stackingViews removeAllObjects];
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
	
    NSRange range = [self stackedNotesRange];
    NSLog(@"Stack notes from %d to %d",range.location,range.length);
    
    stackingViews = [[NSMutableArray alloc] initWithCapacity:range.length];
    int stackingIndex = 0;
    for (int i = range.location; i < range.length; i++) {
        
        if (i == model.selectedNoteIndex) {
            // skip the current doc
            stackingIndex++;
            continue;
        }
        
        UIView *noteView = [_noteViews objectAtIndex:stackingIndex];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:noteView,@"noteView",[NSNumber numberWithInt:stackingIndex],@"index", nil];
        
        [stackingViews addObject:dict];
        stackingIndex++;
    }
    
    UIColor *bottomColor = [(UIView *)[[stackingViews lastObject] objectForKey:@"noteView"] backgroundColor];
    [self.view setBackgroundColor:bottomColor];
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
    return [self viewAtIndex:[ApplicationModel sharedInstance].selectedNoteIndex];
}

- (UIView *)lastNote
{
    return (UIView *)[_noteViews lastObject];
}

- (NoteEntry *)currentNoteEntry
{
    return [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex];
}

- (void)update
{
    [self prepareCellViews];
    [self updateCellsWithModels];
}

- (void)prepareCellViews
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (_numCells == model.currentNoteEntries.count) {
        return;
    }
    
    _numCells = model.currentNoteEntries.count;
    
    for (int i = 0; i < _noteViews.count; i++) {
        if (i>model.currentNoteEntries.count-1) {
            [[_noteViews objectAtIndex:i] removeFromSuperview];
            [_noteViews removeObjectAtIndex:i];
        }
    }
    
    float y = 44.0;
    int numcreated = 0;
    while (y < self.view.bounds.size.height && _noteViews.count<model.currentNoteEntries.count) {
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
        numcreated++;
    }
    
}

- (void)updateCellsWithModels
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
        
    for (int i = 0; i<model.currentNoteEntries.count; i++) {
        NoteEntry *noteEntry = [model noteAtIndex:i];
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
        
        /*
         if (i == model.selectedNoteIndex) {
         _placeholderText.textColor = noteCell.subtitleLabel.textColor;
         }
         */
                
        noteCell.relativeTimeText.textColor = noteCell.subtitleLabel.textColor;
        
        noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
        NSLog(@"Note cell subtitle was: %@, now it's: %@:",noteCell.subtitleLabel.text,noteEntry.title);
        [noteCell.subtitleLabel setText:noteEntry.title];
        noteCell.relativeTimeText.text = [noteEntry relativeDateString];
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        
        circle.textColor = noteCell.subtitleLabel.textColor;
        circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
        circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
        
    }
    
    NoteEntryCell *lastCell = [_noteViews lastObject];
    UIColor *color = lastCell.contentView.backgroundColor;
    [self.bottomExtender setBackgroundColor:color];
    if (DEBUG_ANIMATIONS) {
        [self.bottomExtender setBackgroundColor:[UIColor redColor]];
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
    return index == _noteViews.count-1;
}

- (NSRange)stackedNotesRange
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSMutableOrderedSet *allDocuments = [model currentNoteEntries];
    
    int count = allDocuments.count;
    int displayableCellCount = (int)ceilf((self.view.bounds.size.height/kCellHeight));
    displayableCellCount = displayableCellCount > count ? count : displayableCellCount;
    
    int beginRange = model.selectedNoteIndex;
    int endRange = model.selectedNoteIndex;
    while (endRange-beginRange<=displayableCellCount) {
        beginRange--;
        endRange++;
    }
    
    beginRange = beginRange < 0 ? 0 : beginRange;
    endRange = endRange > count ? count : endRange;
    
    while (endRange-beginRange<displayableCellCount && beginRange>0) {
        beginRange--;
    }
    
    NSLog(@"begin: %d, end: %d",beginRange,endRange);
    
    return NSMakeRange(beginRange, endRange);
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

@end
