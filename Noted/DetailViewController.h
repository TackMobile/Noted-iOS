//
//  DetailViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardViewController.h"
#import "NoteDocument.h"
#import <QuartzCore/QuartzCore.h>


@protocol SingleNoteDelegate <NSObject>
@optional
-(void)openOptions;
-(void)noteTouched;
@end

@interface DetailViewController : UIViewController <UITextViewDelegate,UIScrollViewDelegate> {
    id < SingleNoteDelegate > delegate;
}
@property (strong, nonatomic) NoteDocument *note;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (strong) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UITextView *relativeTimeText;
@property (weak, nonatomic) IBOutlet UITextView *absoluteTimeText;
@property (weak, nonatomic) IBOutlet UIView *colorDotView;
@property (weak, nonatomic) IBOutlet UITextView *colorDot;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) NSMutableArray *colorSchemes;
@property (strong, nonatomic) NSMutableArray *headerColorSchemes;
@property (nonatomic, retain) id delegate;

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor;
@end