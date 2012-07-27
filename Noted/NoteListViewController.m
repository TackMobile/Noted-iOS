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
#import "NewNoteCell.h"

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 44;
    } else {
        return 66;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        ApplicationModel *model = [ApplicationModel sharedInstance];
        return [model.currentNoteEntries count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"NoteCellId";
    static NSString *NewNoteCellId = @"NewNoteCellId";
    UIColor *backgroundColor = [[UIColor colorWithHexString:@"1A9FEB"] colorWithHueOffset:0.05 * indexPath.section / [self tableView:tableView numberOfRowsInSection:indexPath.section]];
    if (indexPath.section == 0) {
        NewNoteCell *newNoteCell = [tableView dequeueReusableCellWithIdentifier:NewNoteCellId];
        if (newNoteCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:self options:nil];
            newNoteCell = [topLevelObjects objectAtIndex:0];
            newNoteCell.textLabel.adjustsFontSizeToFitWidth = YES;
            newNoteCell.textLabel.backgroundColor = [UIColor clearColor];
            newNoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            newNoteCell.contentView.backgroundColor = backgroundColor;
        }
        
        newNoteCell.label.text = NSLocalizedString(@"New Note", @"New Note");
        return newNoteCell;
        
    } else {
        NoteEntryCell *noteEntryCell = [tableView dequeueReusableCellWithIdentifier:CellId];
        ApplicationModel *model = [ApplicationModel sharedInstance];
        NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:indexPath.row];
        
        if (noteEntryCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
            noteEntryCell = [topLevelObjects objectAtIndex:0];
            noteEntryCell.textLabel.adjustsFontSizeToFitWidth = YES;
            noteEntryCell.textLabel.backgroundColor = [UIColor clearColor];
            noteEntryCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        noteEntryCell.contentView.backgroundColor = backgroundColor;
        noteEntryCell.subtitleLabel.text = [noteEntry title];
        noteEntryCell.relativeTimeText.text = [noteEntry relativeDateString];
        noteEntryCell.absoluteTimeText.text = [noteEntry absoluteDateString];
        
        return noteEntryCell;
    }
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (indexPath.section == 0) {
        [model createNote];
    } else {
        model.selectedNoteIndex = indexPath.row;
        NoteStackViewController *stackViewController = [[NoteStackViewController alloc] initWithNibName:@"NoteStackViewController" bundle:nil];
        [self presentViewController:stackViewController animated:YES completion:NULL];
    }
}


@end
