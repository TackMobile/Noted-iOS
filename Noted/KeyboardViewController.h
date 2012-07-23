//
//  KeyboardViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardKey.h"
#import "KeyboardScrollView.h"

@protocol KeyboardDelegate <NSObject>
@required
-(void)closeKeyboard;
-(void)printKeySelected:(NSString*)label;
-(void)snapKeyboardBack;
-(void)panKeyboard:(CGPoint)point;
-(void)undoEdit;
-(void)redoEdit;

@end

@interface KeyboardViewController : UIViewController <UIInputViewAudioFeedback, UIScrollViewDelegate>{
    BOOL capitalized;
    BOOL returnLine;
    BOOL tapped;
    BOOL undo;
    BOOL swipeUp;
    BOOL swipeDown;
    BOOL swipeLeftTwoFinger;
    BOOL swipeRightTwoFinger;
    
    BOOL shouldCloseKeyboard;
    KeyboardKey *returnKey;
    NSTimer *tapTimer;
    NSTimer *undoTimer;
    NSTimer *keyDisplayTimer;
    
    id < KeyboardDelegate > delegate;
}

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *keyImageView;
@property (strong, nonatomic) IBOutlet UITextView *keyDisplay;
@property (nonatomic,retain) NSMutableDictionary *allKeyboards;
@property (nonatomic,retain) KeyboardKey *activeKeyboardKey;
@property (nonatomic,retain) NSDictionary *activeKeyboard;
@property (nonatomic,retain) NSMutableArray *keyboardNames;
@property (nonatomic,retain) NSMutableString *activeKeyboardName;
@property (nonatomic) int howManyTouches;
@property (nonatomic) CGPoint firstTouch;
@property (nonatomic, retain) id delegate;
@property (weak, nonatomic) IBOutlet UIPageControl *pageIndicator;
@property (strong, nonatomic) IBOutlet KeyboardScrollView *scrollView;

@end