//
//  MasterViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteKeyOpViewController.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <UITextFieldDelegate,NoteKeyOpViewControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NoteKeyOpViewController *noteKeyOpVC;

@end
