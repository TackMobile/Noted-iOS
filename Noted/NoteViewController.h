//
//  NoteViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoteViewControllerDelegate <NSObject>
@required
-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point;

@end
@interface NoteViewController : UIViewController
@property (strong, nonatomic) id<NoteViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextView *textView;
- (IBAction)optionsSelected:(id)sender;

@end
