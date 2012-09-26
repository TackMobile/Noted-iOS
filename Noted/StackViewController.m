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

static const int    kFirstView = 10;
static const float  kExpandDuration = 0.5;

@interface StackViewController ()
{
    UITableView *_tableView;
    
    NSUInteger _topViewTag;
    
    BOOL _isPinching;
}

@end

@implementation StackViewController


- (id)init
{
    self = [super initWithNibName:@"StackView" bundle:nil];
    if (self){
        _isPinching = NO;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (NSArray *)noteEntryViews
{
    NSMutableArray *cells = [[NSMutableArray alloc] initWithCapacity:self.view.subviews.count];
    for (UIView *noteCell in self.view.subviews) {
        if ([noteCell isKindOfClass:[NoteEntryCell class]]) {
            [cells addObject:noteCell];
        }
    }
    
    return [cells copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[self.view viewWithTag:kFirstView] setHidden:YES];
    
    float y = 44.0;
    int tag = 11;
    while (y < self.view.bounds.size.height) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        NoteEntryCell *noteCell = (NoteEntryCell *)[views lastObject];
        [noteCell setFrame:CGRectMake(0.0, y, 320.0, 66.0)];
        
        if (NO) {
            [noteCell.layer setBorderColor:[self randomColor].CGColor];
            [noteCell.layer setBorderWidth:1.0];
        }
        
        [self.view addSubview:noteCell];
        noteCell.contentView.backgroundColor = [UIColor whiteColor];
        [noteCell setTag:tag];
        y += noteCell.frame.size.height;
        tag ++;
    }
    
    /*
     NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:nil options:nil];
     NewNoteCell *aView = (NewNoteCell *)[views lastObject];
     [aView setTag:10];
     aView.contentView.backgroundColor = [UIColor whiteColor];
     aView.label.text = @"New Note";
     [self.view addSubview:aView];
     */
}

- (void)setShadowsOnHighNotes
{
    
}
- (NSArray *)notesHigherThanOffset:(NSInteger)offset
{
    NSArray *allNotes = [self noteEntryViews];
    NSMutableArray *cells = [[NSMutableArray alloc] initWithCapacity:self.view.subviews.count];
    for (UIView *view in allNotes) {
        int tag = view.tag;
        if (tag < _topViewTag) {
            [cells addObject:view];
        }
    }
    
    return [cells copy];
}

- (UIView *)viewForIndexOffsetFromTop:(NSInteger)offset
{
    int offsetTag = _topViewTag;
    int tag = offsetTag+offset;
    
    //NoteEntryCell *cell = [self.view viewWithTag:tag];
    //NSLog(@"%@",cell.subtitleLabel.text);
    
    return [self.view viewWithTag:tag];
}

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)updateForTableView:(UITableView *)tableView selectedIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    static int tagOffset = 11;
    _tableView = tableView;
    
        NSLog(@"selected index path %@",selectedIndexPath);
    
    BOOL autoReverse = NO;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    NSArray *cells = _tableView.visibleCells;
    __block NoteEntryCell *prevCell = nil;
    __block NoteEntryCell *nextCell = nil;
    __block int animatedCellCount = 0;
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        
        NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell *)obj];
        
        if (indexPath.section==0) {
            return;
        } else {
            
            NoteEntryCell *entryCell = (NoteEntryCell *)obj;
            int tag = tagOffset+(index-1);
            NoteEntryCell *noteCell = (NoteEntryCell *)[self.view viewWithTag:tag];
            prevCell = (NoteEntryCell *)[self.view viewWithTag:tag-1];
            nextCell = (NoteEntryCell *)[self.view viewWithTag:tag+1];
            
            [noteCell setHidden:NO];
            CGRect frame = [tableView convertRect:entryCell.frame toView:[tableView superview]];
            noteCell.frame = frame;
            if (indexPath.row == 2) {
                NSLog(@"starting frame for row 2: %@",NSStringFromCGRect(frame));
                NSLog(@"bounds %@",NSStringFromCGRect(self.view.bounds));
                NSLog(@"frame %@",NSStringFromCGRect(self.view.frame));
            }
            
            BOOL isSelectedCell = [selectedIndexPath isEqual:indexPath];
            if (isSelectedCell) {
                [self.view addSubview:noteCell];
            }
            
            NoteDocument *document = [model noteDocumentAtIndex:indexPath.row];
            
#warning TODO: this needs to come from model
            UIColor *tempColor = [UIColor colorWithHexString:@"AAAAAA"];
            noteCell.subtitleLabel.textColor = [UIColor blackColor];
            noteCell.relativeTimeText.textColor = tempColor;
            noteCell.absoluteTimeText.textColor = tempColor;
            noteCell.contentView.backgroundColor = document.color;
                        
            [noteCell.subtitleLabel setText:document.text];
            noteCell.subtitleLabel.text = [self displayTitleForNoteEntry:[document noteEntry]];
            noteCell.relativeTimeText.text = [[document noteEntry] relativeDateString];
            noteCell.absoluteTimeText.text = [[document noteEntry] absoluteDateString];
            
            [noteCell setClipsToBounds:NO];
            
            CGRect absTimeFrame = noteCell.absoluteTimeText.frame;
            UILabel *absTimeLabel = noteCell.absoluteTimeText;
            UILabel *circle = (UILabel *)[noteCell viewWithTag:78];
            
            circle.textColor = tempColor;
            circle.text = [NoteViewController optionsDotTextForColor:document.color];
            circle.font = [NoteViewController optionsDotFontForColor:document.color];
            
            UIView *shadow = [noteCell viewWithTag:56];
            float shadowHeight = 10.0;
            [circle setHidden:NO];
            
            BOOL isAbove = indexPath.row < selectedIndexPath.row;
            BOOL isBelow = indexPath.row > selectedIndexPath.row;
            if (!isAbove && !isBelow) {
                _topViewTag = tag;
            }
            // stacking
            if (!prevCell) {
                [self.view addSubview:noteCell];
            } else {
                if (isAbove) {
                    [self.view insertSubview:noteCell aboveSubview:prevCell];
                } 
            }
        
            [UIView animateWithDuration:kExpandDuration
                             animations:^{
                                 if (isSelectedCell) {
                                     [noteCell setFrame:self.view.bounds];
                                     noteCell.layer.cornerRadius = 6.0;

                                 } else {
                                     float yOrigin = isBelow ? self.view.bounds.size.height : 0.0;
                                     CGRect destinationFrame = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                                     [noteCell setFrame:destinationFrame];
                                     
                                     [shadow setFrameY:-shadowHeight];
                                     [shadow setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
                                     
                                     if (tag==11) {
                                         [noteCell setClipsToBounds:NO];
                                     }
                                 }

                                 // transistion its subviews
                                 [absTimeLabel setFrameX:135];
                                 circle.alpha = 1.0;
                                 [circle setFrameX:285];
                                 
                             }
                             completion:^(BOOL finished){
                                 
                                 if (autoReverse) {
                                     [noteCell setFrame:frame];
                                     [absTimeLabel setFrame:absTimeFrame];
                                     circle.alpha = 0.0;
                                     [circle setFrameX:305];
                                     [noteCell setClipsToBounds:YES];

                                 }
                                 
                                 // debug
                                 //noteCell.contentView.backgroundColor = [self randomColor];
                                 
                                 animatedCellCount ++;
                                 NSLog(@"animationCount == %d and cell count: %d",animatedCellCount,cells.count);
                                 if (animatedCellCount==cells.count-1) {
                                     completeBlock();
                                 }
                             }];
        }
        
    }];
}

- (void)resetToExpanded
{
    // animate current note back to self.view.bounds
    UIView *current = [self.view viewWithTag:_topViewTag];
    [UIView animateWithDuration:kExpandDuration
                     animations:^{
                         [current setFrame:self.view.bounds];
                     }
                     completion:^(BOOL finished){
                         NSLog(@"finished animating");
                     }];
    
    
    
    /*
     NSArray *noteCells = [self noteEntryViews];
     for (UIView *noteCell in noteCells) {
     [UIView animateWithDuration:kExpandDuration
     animations:^{
     if (noteCell.tag < _topViewTag) {
     CGRect destinationFrame = CGRectMake(0.0, 0.0, 320.0, 480.0);
     [noteCell setFrame:destinationFrame];
     } else if (noteCell.tag > _topViewTag) {
     CGRect destinationFrame = CGRectMake(0.0, 480.0, 320.0, 480.0);
     [noteCell setFrame:destinationFrame];
     }
     }
     completion:^(BOOL finished){
     NSLog(@"finished animating");
     }];
     }
     
     */
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
