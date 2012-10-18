//
//  NoteViewController.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteEntry.h"

@class NoteDocument;

@protocol NoteViewControllerDelegate <NSObject>

@required
- (void)showOptions;
- (void)didUpdateModel;
@end

@interface NoteViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property(strong, nonatomic) id<NoteViewControllerDelegate> delegate;
@property(strong, nonatomic) NoteEntry *noteEntry;
@property (strong, nonatomic) NoteDocument *noteDocument;

@property(strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *optionsDot;
@property (strong, nonatomic) IBOutlet UILabel *relativeTime;
@property (strong, nonatomic) IBOutlet UILabel *absoluteTime;

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView;

// helper when swiping to create new notes
- (void)setWithPlaceholderData:(BOOL)val;
- (void)setWithNoDataTemp:(BOOL)val;
- (void)setShadowForXOffset;
+ (NSString *)optionsDotTextForColor:(UIColor *)color;
+ (UIFont *)optionsDotFontForColor:(UIColor *)color;

@end
