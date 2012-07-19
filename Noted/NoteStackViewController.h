//
//  NoteStackViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteViewController.h"

@interface NoteStackViewController : UIViewController

@property(nonatomic,strong) NoteViewController *currentNoteViewController;
@property(nonatomic,strong) NoteViewController *nextNoteViewController;
@property(nonatomic,strong) NoteViewController *previousNoteViewController;

@property(nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;

@end
