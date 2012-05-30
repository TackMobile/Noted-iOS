//
//  NoteKeyOpViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/29/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardViewController.h"
#import "OptionsViewController.h"
#import "DetailViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Twitter/Twitter.h>

@protocol NoteKeyOpViewControllerDelegate <NSObject>

-(void)closeNote;

@end

@interface NoteKeyOpViewController : UIViewController <SingleNoteDelegate,KeyboardDelegate,OptionsViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate> {
    int touchesOnScreen;
    BOOL optionsShowing;
}

@property (strong,nonatomic)NSMutableArray *notes;
@property (strong,nonatomic)KeyboardViewController *keyboardVC;
@property (strong,nonatomic)OptionsViewController *optionsVC;
@property (strong,nonatomic)MFMailComposeViewController *mailVC;
@property (strong,nonatomic)MFMessageComposeViewController *messageVC;
@property (strong,nonatomic)DetailViewController *noteVC;
@property (strong,nonatomic)DetailViewController *nextNoteVC;
@property (strong,nonatomic)DetailViewController *previousNoteVC;
@property (strong,nonatomic)UIView *overView;
@property (strong,nonatomic)id delegate;

-(void)openTheNote:(NoteDocument*)note;

@end
