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
#import "NoteEntry.h"

typedef void(^DismissalBlock)(NSUInteger);

@class NoteDocument;

@interface NoteStackViewController : UIViewController <NoteViewControllerDelegate,OptionsViewDelegate, KeyboardDelegate>

@property (nonatomic, copy) DismissalBlock dismissBlock;

@property(nonatomic,strong) NoteViewController *currentNoteViewController;
@property(nonatomic,strong) NoteViewController *nextNoteViewController;

@property(nonatomic,strong) NoteEntry *nextNoteEntry;
@property(nonatomic,strong) NoteEntry *previousNoteEntry;
@property(nonatomic,strong) NoteDocument *nextNoteDocument;
@property(nonatomic,strong) NoteDocument *previousNoteDocument;

@property(nonatomic,strong) KeyboardViewController *keyboardViewController;
@property(nonatomic,strong) OptionsViewController *optionsViewController;
@property(nonatomic,strong) UIView *overView;

@property(nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;

- (id)initWithDismissalBlock:(DismissalBlock)dismiss;

@end
