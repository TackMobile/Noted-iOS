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
#import "StorageSettingsDefaults.h"

@interface NoteListViewController ()

@end

@implementation NoteListViewController
@synthesize tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    self.tableView.backgroundView  = backgroundView;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight       = 60;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model.noteFileManager checkICloudAvailabilityWithCompletionBlock:^(BOOL available){
        [StorageSettingsDefaults setiCloudOn:available];
    }];
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

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section != 0);
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"NoteCellId";
    static NSString *NewNoteCellId = @"NewNoteCellId";
    if (indexPath.section == 0) {
        NewNoteCell *newNoteCell = [tableView dequeueReusableCellWithIdentifier:NewNoteCellId];
        if (newNoteCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NewNoteCell" owner:self options:nil];
            newNoteCell = [topLevelObjects objectAtIndex:0];
            newNoteCell.textLabel.adjustsFontSizeToFitWidth = YES;
            newNoteCell.textLabel.backgroundColor = [UIColor clearColor];
            newNoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            newNoteCell.contentView.backgroundColor = [UIColor colorWithHexString:@"1A9FEB"];
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
        
        if (noteEntry.adding) {
            noteEntryCell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else {
            noteEntryCell.contentView.backgroundColor = [UIColor colorWithRed:0.05f green:0.54f blue:0.82f alpha:1.00f];
        }
        
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
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        NoteEntry *entry = [model.currentNoteEntries objectAtIndex:indexPath.row];
        if (!entry.adding) {
            model.selectedNoteIndex = indexPath.row;
            NoteStackViewController *stackViewController = [[NoteStackViewController alloc] init];
            [self presentViewController:stackViewController animated:YES completion:NULL];
        }
    }
}

- (void) tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0 && editingStyle == UITableViewCellEditingStyleDelete) {
        ApplicationModel *model = [ApplicationModel sharedInstance];
        [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:NULL];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


@end
