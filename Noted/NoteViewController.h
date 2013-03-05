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

#define TEXT_VIEW_X             12
#define TEXT_VIEW_Y             35
#define TEXT_VIEW_INSET_TOP     -7
#define TEXT_VIEW_INSET_LEFT    -8

@protocol NoteViewControllerDelegate <NSObject>

@required
- (void)showOptions;
- (void)didUpdateModel;
@end

@interface NoteViewController : UIViewController <UITextViewDelegate, UIGestureRecognizerDelegate>

@property(strong, nonatomic) id<NoteViewControllerDelegate> delegate;
@property(strong, nonatomic) NoteEntry *noteEntry;
@property (strong, nonatomic) NoteDocument *noteDocument;

@property(strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UILabel *relativeTime;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;

@property (nonatomic, assign) BOOL isCurrent;

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (IBAction)optionsSelected:(id)sender;

// helper when swiping to create new notes
- (void)setWithPlaceholderData:(BOOL)val defaultData:(NoteData *)defaultData;
- (void)setWithNoDataTemp:(BOOL)val;
- (void)setShadowForXOffset;
+ (NSString *)optionsDotTextForColor:(UIColor *)color;
+ (UIFont *)optionsDotFontForColor:(UIColor *)color;

@end
