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
@interface NoteViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate>

@property(strong, nonatomic) id<NoteViewControllerDelegate> delegate;
@property(strong, nonatomic) IBOutlet UITextView *textView;
@property(strong, nonatomic) NoteEntry *noteEntry;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)optionsSelected:(id)sender;
-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView;
@end
