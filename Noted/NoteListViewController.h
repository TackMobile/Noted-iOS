//
//  NoteListViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteEntryCell.h"
#import "NoteStackViewController.h"
#import "AnimationStackViewController.h"
#import "DragToCreateViewController.h"

@interface NoteListViewController : UIViewController <UITableViewDelegate,
                                                NoteEntryCellDelegate,
                                                UITableViewDataSource,
                                                UIGestureRecognizerDelegate,
                                                NoteStackDelegate,
                                                AnimationStackDelegate> {
    DragToCreateViewController *dragToCreateController;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIView *lastRowExtenderView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (assign, nonatomic) BOOL hasData;

@end
