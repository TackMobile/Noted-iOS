//
//  NoteStackViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteViewController.h"
#import "OptionsViewController.h"
#import "KeyboardViewController.h"

@interface NoteStackViewController : UIViewController <NoteViewControllerDelegate,OptionsViewDelegate, KeyboardDelegate>

@property(nonatomic,strong) NoteViewController *currentNoteViewController;
@property(nonatomic,strong) NoteViewController *nextNoteViewController;
@property(nonatomic,strong) NoteViewController *previousNoteViewController;

@property(nonatomic,strong) KeyboardViewController *keyboardViewController;
@property(nonatomic,strong) OptionsViewController *optionsViewController;
@property(nonatomic,strong) UIView *overView;

@property(nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;

@end
