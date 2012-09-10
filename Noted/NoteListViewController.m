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
#import "NoteDocument.h"
#import "UIColor+HexColor.h"
#import "NoteStackViewController.h"
#import "NewNoteCell.h"
#import "FileStorageState.h"
#import "CloudManager.h"

@interface NoteListViewController ()
{
    NoteEntryCell *_deletedCell;
}

@end

@implementation NoteListViewController

@synthesize tableView;

static inline BOOL IsEmpty(id thing) {
    return thing == nil
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

- (id)init
{
    self = [super initWithNibName:@"NoteListViewController" bundle:nil];
    if (self){
        //
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note){
        
        ApplicationModel *model = [ApplicationModel sharedInstance];
        [model refreshNotes];
    }];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
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
        
        NoteDocument *document = [model.currentNoteEntries objectAtIndex:indexPath.row];
        NoteEntry *noteEntry = [document noteEntry];
        
        if (noteEntryCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:self options:nil];
            noteEntryCell = [topLevelObjects objectAtIndex:0];
            noteEntryCell.delegate = self;
        }
        
        if (noteEntry.adding) {
            noteEntryCell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else {
            noteEntryCell.contentView.backgroundColor = [UIColor colorWithRed:0.05f green:0.54f blue:0.82f alpha:1.00f];
        }
        
        noteEntryCell.subtitleLabel.text = [self displayTitleForNoteEntry:noteEntry];
        noteEntryCell.relativeTimeText.text = [noteEntry relativeDateString];
        noteEntryCell.absoluteTimeText.text = [noteEntry absoluteDateString];
        
        return noteEntryCell;
    }
}

- (NSString *)displayTitleForNoteEntry:(NoteEntry *)entry
{
    NSString *title = nil;
    if (!IsEmpty([entry text]) && ![entry.text isEqualToString:@"\n"]){
        title = [entry text];
    } else {
        title = @"...";
    }
    
    return title;
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    if (indexPath.section == 0) {
        [model createNote];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        
        NoteDocument *doc = [model noteDocumentAtIndex:indexPath.row];
        NoteEntry *entry = [doc noteEntry];
        
        if (!entry.adding) {
            model.selectedNoteIndex = indexPath.row;
            
            NoteStackViewController *stackViewController = [[NoteStackViewController alloc] init];
            [self presentViewController:stackViewController animated:YES completion:NULL];
        }
    }
}


- (void)didSwipeToDeleteCellWithIndexPath:(NoteEntryCell *)cell
{
    CGPoint correctedPoint = [cell convertPoint:cell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:correctedPoint];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:indexPath.row withCompletionBlock:^{
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }];
}


@end
