//
//  NoteListViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteEntryCell.h"

@interface NoteListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NoteEntryCellDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
