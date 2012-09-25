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
#import "UIView+position.h"

static const int kFirstView = 10;

@interface StackViewController ()

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

- (void)updateForTableView:(UITableView *)tableView selectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    static int tagOffset = 10;
    
    NSArray *cells = tableView.visibleCells;
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        
        
        NoteEntryCell *entryCell = (NoteEntryCell *)obj;
        NSIndexPath *indexPath = [tableView indexPathForCell:entryCell];
        
        int tag = tagOffset+index;
        UIView *cellView = [self.view viewWithTag:tag];
        [cellView setHidden:NO];
        CGRect frame = [tableView convertRect:entryCell.frame toView:[tableView superview]];
        
        if (indexPath.section==0) {
            [[self.view viewWithTag:kFirstView] setHidden:NO];
            return;
        } else {
            
            //[cellView setFrame:frame];
            
            NSLog(@"setting view with tag %d to frame %@ for cell at indexPath %@",tag,NSStringFromCGRect(frame),indexPath);

            [UIView animateWithDuration:0.5
                             animations:^{
                                 if ([selectedIndexPath isEqual:indexPath]) {
                                     [cellView setFrame:self.view.bounds];
                                 } else {
                                     if (indexPath.row > selectedIndexPath.row) {
                                         [cellView setFrameY: 480.0];
                                     } else if (indexPath.row < selectedIndexPath.row){
                                         CGRect destinationFrame = CGRectMake(0.0, 0.0, 320.0, 66.0);
                                         [cellView setFrame:destinationFrame];
                                     }
                                 }
                                 
                             }
                             completion:^(BOOL finished){
                                 [cellView setFrame:frame];
                             }];
        }
        
    }];
}

- (UIImage *)imageRepresentationForView:(UIView *)view
{
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[self.view viewWithTag:kFirstView] setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
