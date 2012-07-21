//
//  NoteListViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteListViewController.h"
#import "ApplicationModel.h"
#import "NoteEntryCell.h"
#import "NoteEntry.h"
#import "UIColor+HexColor.h"
#import "NoteStackViewController.h"

@interface NoteListViewController ()

@end

@implementation NoteListViewController
@synthesize tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    self.tableView.backgroundView = backgroundView;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight       = 60;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model refreshNotes];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void) noteListChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ApplicationModel *model = [ApplicationModel sharedInstance];
    return [model.currentNoteEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"NoteCellId";
    NoteEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
    UIColor *backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.05 * indexPath.row / [self tableView:tableView numberOfRowsInSection:indexPath.section]];
    
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
        // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
        cell = [topLevelObjects objectAtIndex:0];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.contentView.backgroundColor = backgroundColor;
    cell.subtitleLabel.text = [noteEntry title];
    cell.relativeTimeText.text = [noteEntry relativeDateString];
    cell.absoluteTimeText.text = [noteEntry absoluteDateString];
    
    return cell;
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithNibName:@"NoteStackViewController" bundle:nil];
    [self presentViewController:stackViewController animated:YES completion:NULL];
}


@end
