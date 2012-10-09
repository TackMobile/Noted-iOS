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

static const int    kFirstView = 10;
static const float  kExpandDuration = 1.3;
static const float  kCellHeight = 66.0;

@interface StackViewController ()
{
    UITableView *_tableView;
    
    NSUInteger _currentIndex;
    
    BOOL _isPinching;
    
    NSMutableArray *_noteViews;
    int _numCells;
    UITextView *placeholderText;
    CGRect centerNoteFrame;
    
    float pinchPercentComplete;
    
    NSInteger _currentNoteIndex;
    NSMutableArray *stackingViews;
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
        centerNoteFrame = CGRectZero;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (NSArray *)noteEntryViews
{
    return [_noteViews copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[self.view viewWithTag:kFirstView] setHidden:YES];
    
    [self.view setUserInteractionEnabled:NO];
    
    placeholderText = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)];
    placeholderText.text = @"piecemeal beats oatmeal";
    placeholderText.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    placeholderText.backgroundColor = [UIColor clearColor];
}

- (void)finishExpansion
{
    [self.view setFrameX:-320.0];
}

- (void)finishCollapse
{
    [self.view setFrameX:-320.0];
}

- (int)indexOfNoteView:(UIView *)view
{
    return [_noteViews indexOfObject:view];
}

- (void)animateStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < stackingViews.count; i ++) {
        [self animateStackedNoteAtIndex:i withScale:scale];
    }
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    view.alpha = 1.0;
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 1.0;
}

- (UIView *)viewAtIndex:(NSInteger)index
{
    return (NoteEntryCell *)[_noteViews objectAtIndex:index];
}

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)animateCollapseForScale:(float)scale percentComplete:(float)pinchPercent
{
    pinchPercentComplete = pinchPercent;
    if (self.view.frame.origin.x != 0.0) {
        [self.view setFrameX:0.0];
    }
    
    [self animateCurrentNoteWithScale:scale];
    [self animateStackedNotesForScale:scale];
}

- (void)animateCurrentNoteWithScale:(CGFloat)scale
{
    NSLog(@"self.view.bounds.height: %@",NSStringFromCGRect(self.view.bounds));
    float minusAmount = self.view.bounds.size.height-kCellHeight;
    float newHeight = self.view.bounds.size.height-(minusAmount*pinchPercentComplete);
    
    NSLog(@"pinchPercentComplete: %f",pinchPercentComplete);
    
    BOOL isLast = [self indexOfNoteView:[self currentNote]] == _noteViews.count-1;
    NSLog(@"is last: %s",isLast ? "yes" : "no");
    
    [self updateSubviewsForNote:[self currentNote] scaled:YES];
    
    float newY = (self.view.bounds.size.height-newHeight)*0.5;
    if (newY < 0) {
        newY = 0;
    }
    
    centerNoteFrame = CGRectMake(0.0, newY, 320.0, newHeight);
    NSLog(@"centerNoteFrame: %@",NSStringFromCGRect(centerNoteFrame));
    float safety = 3.0;
    self.bottomExtender.frame = CGRectMake(0.0, CGRectGetMaxY(centerNoteFrame)-safety, self.view.bounds.size.width, self.view.bounds.size.height-CGRectGetMaxY(centerNoteFrame)+safety);
    
    [[self currentNote] setFrame:centerNoteFrame];
}

- (int)documentCount
{
    return [[ApplicationModel sharedInstance] currentNoteEntries].count;
}

- (UIView *)currentNote
{
    return [self viewAtIndex:[ApplicationModel sharedInstance].selectedNoteIndex];
}

- (void)finishCollapse:(void(^)())complete
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         //float currentNoteY = (self.view.bounds.size.height-kCellHeight)*0.5;
                         centerNoteFrame = self.view.bounds;
                         //CGRectMake(0.0, currentNoteY, 320.0, kCellHeight);
                         [[self currentNote] setFrame:centerNoteFrame];
                         
                         for (int i = 0; i < stackingViews.count; i ++) {
                             NSDictionary *noteDict = [stackingViews objectAtIndex:i];
                             
                             UIView *note = [noteDict objectForKey:@"noteView"];
                             int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
                             
                             int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - stackingIndex);
                             
                             float newHeight = kCellHeight;
                             float newY = 0.0;
                             if (offset < 0) {
                                 float finalCY = [self finalYOriginForCurrentNote];
                                 float balh = offset*kCellHeight;
                                 newY = finalCY + balh;
                                 
                             } else if (offset>0) {
                                 newHeight = self.view.bounds.size.height-CGRectGetMaxY([self currentNote].frame);
                                 newY = (CGRectGetMaxY(centerNoteFrame))+((offset-1)*kCellHeight);
                             }
                             
                             CGRect newFrame = CGRectMake(0.0, newY, 320.0, newHeight);
                             [note setFrame:newFrame];
                         }
                     }
                     completion:^(BOOL finished){
                         [self finishCollapse];
                         complete();
                         
                     }];
}

- (float)finalYOriginForCurrentNote
{
    float finalY = (self.view.bounds.size.height-kCellHeight)*0.5;
    
    return finalY;
}

- (void)animateStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    NSDictionary *noteDict = [stackingViews objectAtIndex:index];
    
    UIView *note = [noteDict objectForKey:@"noteView"];
    BOOL isLast = [self indexOfNoteView:note]==[self documentCount]-1;
    BOOL isFirst = [self indexOfNoteView:note]==0;
    //NSLog(@"Is first: %s, is last: %s",isFirst ? "YES" : "NO",isLast ? "YES" : "NO");
    
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

- (void)prepareForCollapseAnimationForView:(UIView *)view
{
    [self setUpRangeForStacking];

    if (![[self.view superview] isEqual:view]) {
        [view addSubview:self.view];
    }
    
    NSLog(@"%@",NSStringFromCGRect([self currentNote].frame));
    NSLog(@"\n");
}

- (void)prepareForExpandAnimationForView:(UIView *)view
{
    
}

- (void)setUpRangeForStacking
{
    if (stackingViews) {
        [stackingViews removeAllObjects];
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    _currentNoteIndex = model.selectedNoteIndex;
	
    NSRange range = [self stackedNotesRange];
    NSLog(@"Stack notes from %d to %d",range.location,range.length);
    
    stackingViews = [[NSMutableArray alloc] initWithCapacity:range.length];
    int stackingIndex = 0;
    for (int i = range.location; i < range.length; i++) {
        
        if (i == _currentNoteIndex) {
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

- (void)updateSubviewsForNote:(UIView *)note scaled:(BOOL)scaled
{
    UIView *littleCircle = [note viewWithTag:78];
    if (!scaled) {
        littleCircle.alpha = 0.0;
        return;
    }
    
    littleCircle.alpha = 1.0-(pinchPercentComplete*1.1);
}

- (void)animateOpenForController:(NoteListViewController *)noteList indexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    _currentIndex = model.selectedNoteIndex;
    _tableView = noteList.tableView;

    /*
     NSLog(@"\n\n\nselected index path %@",selectedIndexPath);
     NSLog(@"stack frame: %@",NSStringFromCGRect(self.view.frame));
     for (UIView *view in _noteViews) {
     NSLog(@"frame: %@",NSStringFromCGRect(view.frame));
     }
     NSLog(@"\n\n\n");
     */
            
    NSArray *cells = _tableView.visibleCells;
    __block int animatedCellCount = 0;
    int index = 0;

    for (NoteEntryCell *entryCell in cells) {
        NSIndexPath *indexPath = [noteList.tableView indexPathForCell:entryCell];
        
        if (indexPath.section==0) {
            continue;
        } else {
            
            NoteEntryCell *noteCell = [_noteViews objectAtIndex:indexPath.row];
            UIView *shadow = [noteCell viewWithTag:56];
            float shadowHeight = 7.0;
            
            [noteCell setHidden:NO];
            CGRect frame = [_tableView convertRect:entryCell.frame toView:[_tableView superview]];
            noteCell.frame = frame;
            /*
             if (indexPath.row == 1) {
             NSLog(@"starting frame for row 2: %@",NSStringFromCGRect(frame));
             NSLog(@"bounds %@",NSStringFromCGRect(self.view.bounds));
             NSLog(@"frame %@",NSStringFromCGRect(self.view.frame));
             }
             */
            
            BOOL isSelectedCell = [selectedIndexPath isEqual:indexPath];
            if (isSelectedCell) {
                [noteCell.contentView addSubview:placeholderText];
                [placeholderText setHidden:NO];
                [noteCell.subtitleLabel setHidden:YES];
                NSLog(@"%@",model.noteAtSelectedNoteIndex.text);
                placeholderText.text = model.noteAtSelectedNoteIndex.text;
            }
        
            BOOL isLastCell = indexPath.row == cells.count-2; // minus 2 to account for section 0
            
            [shadow setFrameY:-shadowHeight];
            [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];

            [noteCell setClipsToBounds:NO];
            
            UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
            [circle setHidden:NO];
            
            BOOL isBelow = indexPath.row > selectedIndexPath.row;
            
            [self.view addSubview:noteCell];
            
            __block int numComplete = 0;
            [UIView animateWithDuration:kExpandDuration
                             animations:^{
                                 
                                 if (isSelectedCell) {
                                     
                                    // NSLog(@"current frame of note cell: %@",NSStringFromCGRect(noteCell.frame));
                                     CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
                                     appFrame.origin.y = 0.0;
                                     NSAssert(!CGRectEqualToRect(noteCell.frame, self.view.bounds), @"Rects are equal, so there's no animation to perform!");;
                                     [noteCell setFrame:appFrame];
                                     noteCell.layer.cornerRadius = 6.0;
                                     
                                 } else {
                                     
                                     if (isLastCell && !isSelectedCell) {
                                         CGRect destinationFrame = CGRectMake(0.0, self.view.bounds.size.height, 320.0, 200.0); // arbitrary height?
                                         
                                         [noteCell setFrame:destinationFrame];
                                         [noteList.lastRowExtenderView setFrameY:CGRectGetMaxY(self.view.bounds)+66.0];
                                     } else {
                                         float yOrigin = isBelow ? self.view.bounds.size.height : 0.0;
                                         CGRect destinationFrame = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                                         [noteCell setFrame:destinationFrame];
                                     }
                                 }
                                 
                                 // transistion its subviews
                                 circle.alpha = 1.0;
                                 
                             }
                             completion:^(BOOL finished){
                                 
                                 // debug
                                 //noteCell.contentView.backgroundColor = [self randomColor];
                                                                  
                                 if (isSelectedCell) {
                                     [placeholderText setHidden:YES];
                                     [placeholderText removeFromSuperview];
                                     [noteCell.subtitleLabel setHidden:NO];
                                 }
                                 
                                 NSLog(@"animationCount == %d and cell count: %d",animatedCellCount,cells.count);
                                 if (animatedCellCount==cells.count-2) { // -2 to account for section 0 row 1
                                     completeBlock();
                                 } else {
                                     animatedCellCount ++;
                                 }
                                 
                                 numComplete ++;
                                 if (numComplete == _noteViews.count) {
                                     [self finishExpansion];
                                 }
                                 
                             }];
        }
        
        index ++;
    }
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
    NSArray *noteCells = [self noteEntryViews];
    int index = 0;
    for (UIView *noteCell in noteCells) {
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

#pragma mark Data source

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
            [noteCell.layer setBorderWidth:1.0];
        }
        
        [noteCell setClipsToBounds:NO];
        
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
    
    NSLog(@"Count of model objects: %d",model.currentNoteEntries.count);
    
    for (int i = 0; i<model.currentNoteEntries.count; i++) {
        NoteEntry *noteEntry = [model noteAtIndex:i];
        NoteEntryCell *noteCell = [[self noteEntryViews] objectAtIndex:i];
        
        if (i == model.selectedNoteIndex) {
            placeholderText.textColor = noteCell.subtitleLabel.textColor;
            if (YES) {
                placeholderText.textColor = [UIColor redColor];
                CGRect frame = placeholderText.frame;
                frame.origin.x += 5.0;
                placeholderText.frame = frame;
            }
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
        noteCell.relativeTimeText.text = [noteEntry relativeDateString];
        
        UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
        
        circle.textColor = noteCell.subtitleLabel.textColor;
        circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
        circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
        
    }
    
    NoteEntryCell *lastCell = [[self noteEntryViews] lastObject];
    UIColor *color = lastCell.contentView.backgroundColor;
    [self.bottomExtender setBackgroundColor:color];
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (NSRange)stackedNotesRange
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSMutableOrderedSet *allDocuments = [model currentNoteEntries];
    
    int count = allDocuments.count;
    int displayableCellCount = (int)ceilf((self.view.bounds.size.height/kCellHeight));
    displayableCellCount = displayableCellCount > count ? count : displayableCellCount;
    
    int beginRange = _currentNoteIndex;
    int endRange = _currentNoteIndex;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
