//
//  AltNoteStackViewController.h
//  Noted
//
//  Created by Ben Pilcher on 9/26/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteViewController.h"
#import "NTDOptionsViewController.h"
#import "KeyboardViewController.h"
#import "NoteEntry.h"
#import <Accounts/Accounts.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Twitter/Twitter.h>

typedef void(^TMDismissalBlock)(float);

@class NoteDocument;
@class AnimationStackViewController;

@protocol NoteStackDelegate;

@interface NoteStackViewController : UIViewController <NoteViewControllerDelegate, NTDOptionsViewDelegate, KeyboardDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (nonatomic, copy) TMDismissalBlock dismissBlock;
@property (nonatomic, weak) id <NoteStackDelegate> delegate;
@property(nonatomic,strong) NoteViewController *currentNoteViewController;
@property(nonatomic,strong) NoteViewController *nextNoteViewController;

@property(nonatomic,strong) NoteEntry *nextNoteEntry;
@property(nonatomic,strong) NoteEntry *previousNoteEntry;
@property(nonatomic,strong) NoteDocument *nextNoteDocument;
@property(nonatomic,strong) NoteDocument *previousNoteDocument;

@property(nonatomic,strong) KeyboardViewController *keyboardViewController;
@property(nonatomic,strong) NTDOptionsViewController *optionsViewController;
@property(nonatomic,strong) UIView *overView;

@property(nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) UIView *keyboard;
@property int originalKeyboardY;
@property int originalLocation;

- (id)initWithDismissalBlock:(TMDismissalBlock)dismiss andStackVC:(AnimationStackViewController *)stackVC;

@end

@protocol NoteStackDelegate <NSObject>

- (void)indexDidChange;

@end;
