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

static const int kFirstView = 10;

@interface StackViewController ()
{
    UITableView *_tableView;
}

@end

@implementation StackViewController

- (id)init
{
    self = [super initWithNibName:@"StackView" bundle:nil];
    if (self){
        //
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
    // Do any additional setup after loading the view from its nib.
    
    [[self.view viewWithTag:kFirstView] setHidden:YES];
    
    float y = 44.0;
    int tag = 11;
    while (y < self.view.bounds.size.height) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        NoteEntryCell *aView = (NoteEntryCell *)[views lastObject];
        [aView setFrame:CGRectMake(0.0, y, 320.0, 66.0)];
        [self.view addSubview:aView];
        aView.contentView.backgroundColor = [UIColor whiteColor];
        [aView setTag:tag];
        y += aView.frame.size.height;
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

- (void)updateForTableView:(UITableView *)tableView selectedIndexPath:(NSIndexPath *)selectedIndexPath completion:(animationCompleteBlock)completeBlock
{
    static int tagOffset = 11;
    _tableView = tableView;
    
    BOOL autoReverse = NO;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    NSArray *cells = _tableView.visibleCells;
    __block NoteEntryCell *prevCell = nil;
    __block int animationCount = 0;
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        
        NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell *)obj];
        
        if (indexPath.section==0) {
            return;
        } else {
            
            NoteEntryCell *entryCell = (NoteEntryCell *)obj;
            int tag = tagOffset+index;
            NoteEntryCell *noteCell = (NoteEntryCell *)[self.view viewWithTag:tag];
            prevCell = (NoteEntryCell *)[self.view viewWithTag:tag-1];
            
            [noteCell setHidden:NO];
            CGRect frame = [tableView convertRect:entryCell.frame toView:[tableView superview]];
            
            BOOL isSelectedCell = [selectedIndexPath isEqual:indexPath];
            
            NoteDocument *document = [model noteDocumentAtIndex:indexPath.row];
            
            UIColor *tempColor = [UIColor colorWithHexString:@"AAAAAA"];
            noteCell.subtitleLabel.textColor = [UIColor blackColor];
            noteCell.relativeTimeText.textColor = tempColor;
            noteCell.absoluteTimeText.textColor = tempColor;
            noteCell.contentView.backgroundColor = document.color;
                        
            [noteCell.subtitleLabel setText:document.text];
            noteCell.subtitleLabel.text = [self displayTitleForNoteEntry:[document noteEntry]];
            NSLog(@"%@ %d",noteCell.subtitleLabel.text,noteCell.subtitleLabel.text.length);
            noteCell.relativeTimeText.text = [[document noteEntry] relativeDateString];
            noteCell.absoluteTimeText.text = [[document noteEntry] absoluteDateString];
            
            [noteCell setClipsToBounds:NO];
            
            CGRect absTimeFrame = noteCell.absoluteTimeText.frame;
            UITextView *absTimeLabel = noteCell.absoluteTimeText;
            UIView *circle = [noteCell viewWithTag:78];
            UIView *shadow = [noteCell viewWithTag:56];
            float shadowHeight = 10.0;
            [circle setHidden:NO];
            
            BOOL isAbove = indexPath.row < selectedIndexPath.row;
            BOOL isBelow = indexPath.row > selectedIndexPath.row;
            // stacking
            if (prevCell && ![prevCell isKindOfClass:[NewNoteCell class]]) {
                if (isAbove) {
                    [self.view insertSubview:noteCell aboveSubview:prevCell];
                } else if (isBelow) {
                    [self.view insertSubview:noteCell belowSubview:prevCell];
                }
            } else {
                [self.view addSubview:noteCell];
            }
            
            [UIView animateWithDuration:0.5
                             animations:^{
                                 if (isSelectedCell) {
                                     [noteCell setFrame:self.view.bounds];
                                     [self.view addSubview:noteCell];

                                 } else {
                                     float yOrigin = isBelow ? self.view.bounds.size.height : 0.0;
                                     CGRect destinationFrame = CGRectMake(0.0, yOrigin, 320.0, 66.0);
                                     [noteCell setFrame:destinationFrame];
                                 }
                                 
                                 // shadow
                                 if (isBelow) {
                                     [shadow setFrameY:66];
                                 } else if (isAbove) {
                                     [shadow setFrameY:-shadowHeight];
                                 }
                                 
                                 // transistion its subviews
                                 [absTimeLabel setFrameX:140];
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
                                     [shadow setFrameY:56];

                                 }
                                 
                                 animationCount ++;
                                 NSLog(@"animationCount == %d and cell count: %d",animationCount,cells.count);
                                 if (animationCount==cells.count-1) {
                                     completeBlock();
                                 }
                             }];
        }
        
    }];
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
