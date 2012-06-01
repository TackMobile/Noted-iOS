//
//  KeyboardViewController.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardKey.h"

@protocol KeyboardDelegate <NSObject>
@optional
-(void)closeKeyboard;
-(void)printKeySelected:(NSString*)label;
-(void)snapKeyboardBack;
-(void)panKeyboard:(CGPoint)point;
-(void)undoEdit;
-(void)redoEdit;


@end

@interface KeyboardViewController : UIViewController <UIInputViewAudioFeedback>{
    BOOL capitalized;
    BOOL returnLine;
    BOOL tapped;
    BOOL undo;
    
    BOOL shouldCloseKeyboard;
    KeyboardKey *returnKey;
    NSTimer *tapTimer;
    NSTimer *undoTimer;
    NSTimer *keyDisplayTimer;
    
    id < KeyboardDelegate > delegate;
}

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *keyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *previousKeyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *nextKeyImageView;
@property (strong, nonatomic) IBOutlet UITextView *keyDisplay;
@property (nonatomic,retain) NSMutableDictionary *allKeyboards;
@property (nonatomic,retain) KeyboardKey *activeKeyboardKey;
@property (nonatomic,retain) NSDictionary *activeKeyboard;
@property (nonatomic,retain) NSMutableArray *keyboardNames;
@property (nonatomic,retain) NSMutableString *activeKeyboardName;
@property (strong) NSMutableString *nextKeyboard;
@property (strong) NSMutableString *previousKeyboard;
@property (nonatomic) int howManyTouches;
@property (nonatomic) CGPoint firstTouch;
@property (nonatomic, retain) id delegate;
@property (weak, nonatomic) IBOutlet UIPageControl *pageIndicator;


@end