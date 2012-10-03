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
static const float  kExpandDuration = 0.75;

@interface StackViewController ()
{
    UITableView *_tableView;
    
    NSUInteger _currentIndex;
    
    BOOL _isPinching;
    
    NSMutableArray *_noteViews;
    int _numCells;
}

@end

@implementation StackViewController


- (id)init
{
    self = [super initWithNibName:@"StackView" bundle:nil];
    if (self){
        _isPinching = NO;
        _numCells = 0;
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
    
    self.view.layer.borderColor = [UIColor orangeColor].CGColor;
    self.view.layer.borderWidth = 2.0;
    [self.view setUserInteractionEnabled:NO];
    /*
     NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:nil options:nil];
     NewNoteCell *aView = (NewNoteCell *)[views lastObject];
     [aView setTag:10];
     aView.contentView.backgroundColor = [UIColor whiteColor];
     aView.label.text = @"New Note";
     [self.view addSubview:aView];
     */
}

- (void)generateCells
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    if (_numCells == model.currentNoteEntries.count) {
        return;
    }
    
    _numCells = model.currentNoteEntries.count;
    [_noteViews removeAllObjects];
    
    float y = 44.0;

    _noteViews = [[NSMutableArray alloc] init];
    
    while (y < self.view.bounds.size.height && _noteViews.count<=model.currentNoteEntries.count) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        NoteEntryCell *noteCell = (NoteEntryCell *)[views lastObject];
        [noteCell setFrame:CGRectMake(0.0, y, 320.0, 66.0)];
        
        if (NO) {
            [noteCell.layer setBorderColor:[self randomColor].CGColor];
            [noteCell.layer setBorderWidth:1.0];
        }
        
        [self.view addSubview:noteCell];
        noteCell.contentView.backgroundColor = [UIColor whiteColor];
        [self debugView:noteCell color:[UIColor greenColor]];
        y += noteCell.frame.size.height;
        [_noteViews addObject:noteCell];

    }
}

- (int)indexOfNoteView:(UIView *)view
{
    return [_noteViews indexOfObject:view];
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    // debugging
    view.alpha = 1.0;
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 1.0;
}

- (UIView *)viewAtIndex:(NSInteger)offset
{
    NSLog(@"_currentIndex: %d",_currentIndex);
    int tag = 11+offset;
    NSLog(@"looking for view with index %d",tag);
    
    NoteEntryCell *cell = (NoteEntryCell *)[_noteViews objectAtIndex:offset];
    NSLog(@"%@",cell.subtitleLabel.text);
    
    if (!cell) {
        NSLog(@"\n\n no view!\n\n");
    }
    
    return cell;
}

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)expandRowsForViewController:(NoteListViewController *)noteList selectedIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    _currentIndex = model.selectedNoteIndex;
    _tableView = noteList.tableView;

    NSLog(@"\n\n\nselected index path %@",selectedIndexPath);
    NSLog(@"stack frame: %@",NSStringFromCGRect(self.view.frame));
    for (UIView *view in _noteViews) {
        NSLog(@"frame: %@",NSStringFromCGRect(view.frame));
    }
    NSLog(@"\n\n\n");
    NSAssert(self.view.frame.origin.x>=0, @"Stack must be visible!");
            
    NSArray *cells = _tableView.visibleCells;
    __block int animatedCellCount = 0;
    int index = 0;
    NSAssert(cells.count>0, @"No cells to animate!");
    for (NoteEntryCell *entryCell in cells) {
        NSIndexPath *indexPath = [noteList.tableView indexPathForCell:entryCell];
        
        if (indexPath.section==0) {
            continue;
        } else {
            
            NoteEntryCell *noteCell = [_noteViews objectAtIndex:indexPath.row];
            UIView *shadow = [noteCell viewWithTag:56];
            float shadowHeight = 10.0;
            
            [noteCell setHidden:NO];
            CGRect frame = [_tableView convertRect:entryCell.frame toView:[_tableView superview]];
            noteCell.frame = frame;
            if (indexPath.row == 1) {
                NSLog(@"starting frame for row 2: %@",NSStringFromCGRect(frame));
                NSLog(@"bounds %@",NSStringFromCGRect(self.view.bounds));
                NSLog(@"frame %@",NSStringFromCGRect(self.view.frame));
            }
            
            BOOL isSelectedCell = [selectedIndexPath isEqual:indexPath];
            BOOL isLastCell = indexPath.row == cells.count-2; // minus 2 to account for section 0
            
            [shadow setFrameY:-shadowHeight];
            [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
            
            NoteEntry *noteEntry = [model noteAtIndex:indexPath.row];
            
#warning TODO: this needs to come from model
            UIColor *tempColor = [UIColor colorWithHexString:@"AAAAAA"];
            noteCell.subtitleLabel.textColor = [UIColor blackColor];
            noteCell.relativeTimeText.textColor = tempColor;
            noteCell.absoluteTimeText.textColor = tempColor;
            noteCell.contentView.backgroundColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
            
            [noteCell.subtitleLabel setText:noteEntry.text];
            noteCell.subtitleLabel.text = [self displayTitleForNoteEntry:noteEntry];
            noteCell.relativeTimeText.text = [noteEntry relativeDateString];
            noteCell.absoluteTimeText.text = [noteEntry absoluteDateString];
            
            [noteCell setClipsToBounds:NO];
            
            UILabel *absTimeLabel = noteCell.absoluteTimeText;
            UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
            
            circle.textColor = tempColor;
            circle.text = [NoteViewController optionsDotTextForColor:noteEntry.noteColor];
            circle.font = [NoteViewController optionsDotFontForColor:noteEntry.noteColor];
            [circle setHidden:NO];
            
            BOOL isBelow = indexPath.row > selectedIndexPath.row;
            
            [self.view addSubview:noteCell];
            
            [UIView animateWithDuration:kExpandDuration
                             animations:^{
                                 
                                 if (isSelectedCell) {
                                     
                                     NSLog(@"current frame of note cell: %@",NSStringFromCGRect(noteCell.frame));
                                     NSAssert(!CGRectEqualToRect(noteCell.frame, self.view.bounds), @"Rects are equal, so there's no animation to perform!");;
                                     [noteCell setFrame:self.view.bounds];
                                     noteCell.layer.cornerRadius = 6.0;
                                     
                                 } else {
                                     
                                     if (isLastCell && !isSelectedCell) {
                                         CGRect destinationFrame = CGRectMake(0.0, self.view.bounds.size.height, 320.0, 200.0); // arbitrary height?
                                         NSLog(@"noteCell frame: %@",NSStringFromCGRect(noteCell.frame));
                                         NSAssert(!CGRectEqualToRect(noteCell.frame, destinationFrame), @"You need to reset!");
                                         [noteCell setFrame:destinationFrame];
                                         [noteList.lastRowExtenderView setFrameY:CGRectGetMaxY(self.view.bounds)+66.0];
                                     } else {
                                         float yOrigin = isBelow ? self.view.bounds.size.height : 0.0;
                                         CGRect destinationFrame = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                                         [noteCell setFrame:destinationFrame];
                                     }
                                 }
                                 
                                 // transistion its subviews
                                 [absTimeLabel setFrameX:135];
                                 circle.alpha = 1.0;
                                 [circle setFrameX:285];
                                 
                             }
                             completion:^(BOOL finished){
                                 
                                 // debug
                                 //noteCell.contentView.backgroundColor = [self randomColor];
                                 
                                 NSLog(@"animationCount == %d and cell count: %d",animatedCellCount,cells.count);
                                 if (animatedCellCount==cells.count-2) { // -2 to account for section 0 row 1
                                     completeBlock();
                                 } else {
                                     animatedCellCount ++;
                                 }
                                 
                             }];
        }
        index ++;
    }
    
}

- (void)resetToExpanded
{
    // animate current note back to self.view.bounds
    UIView *current = [_noteViews objectAtIndex:_currentIndex];
    [UIView animateWithDuration:kExpandDuration
                     animations:^{
                         [current setFrame:self.view.bounds];
                     }
                     completion:^(BOOL finished){
                         NSLog(@"finished resetToExpanded");
                         [self.view setFrameX:-320.0];
                     }];
    
    
    
    
#warning TODO needs testing
    NSArray *noteCells = [self noteEntryViews];
    int index = 0;
    for (UIView *noteCell in noteCells) {
        [UIView animateWithDuration:kExpandDuration
                         animations:^{
                             if (index < _currentIndex) {
                                 CGRect destinationFrame = CGRectMake(0.0, 0.0, 320.0, 480.0);
                                 [noteCell setFrame:destinationFrame];
                             } else if (index > _currentIndex) {
                                 CGRect destinationFrame = CGRectMake(0.0, 480.0, 320.0, 480.0);
                                 [noteCell setFrame:destinationFrame];
                             }
                         }
                         completion:^(BOOL finished){
                             NSLog(@"finished animating");
                         }];
        index++;
    }
    
     
}

#warning TODO: this is duplicated in NoteListViewController
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
