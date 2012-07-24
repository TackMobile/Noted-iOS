//
//  NoteViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteEntry.h"

@protocol NoteViewControllerDelegate <NSObject>
@required
-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point;

@end
@interface NoteViewController : UIViewController

@property(strong, nonatomic) id<NoteViewControllerDelegate> delegate;
@property(strong, nonatomic) IBOutlet UITextView *textView;
@property(strong, nonatomic) NoteEntry *noteEntry;

- (IBAction)optionsSelected:(id)sender;

@end
