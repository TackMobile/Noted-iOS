//
//  NoteStackViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteStackViewController.h"
#import "ApplicationModel.h"
#import "NoteViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteEntry.h"

@interface NoteStackViewController () {
    int numberOfTouchesInCurrentPanGesture;
    BOOL optionsShowing;
}

- (void) presentNotes;

@end

@implementation NoteStackViewController
@synthesize currentNoteViewController, nextNoteViewController, previousNoteViewController, panGestureRecognizer, keyboardViewController,optionsViewController, overView;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 6.5;
    self.view.layer.masksToBounds = NO;
    
    self.keyboardViewController = [[KeyboardViewController alloc] initWithNibName:@"KeyboardViewController" bundle:nil];
    self.keyboardViewController.delegate = self;
    //Register for notifications so the keyboard load will push any text into view
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewUpForKeyboard:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewDownAfterKeyboard:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    
    self.optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
    self.optionsViewController.delegate = self;
    [self.view addSubview:self.optionsViewController.view];
    
    self.currentNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.currentNoteViewController.delegate = self;
    [self.view addSubview:self.currentNoteViewController.view];
    self.currentNoteViewController.textView.inputView = self.keyboardViewController.view;
    
    self.nextNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.previousNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentNotes];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentNoteViewController = nil;
    self.previousNoteViewController = nil;
    self.nextNoteViewController = nil;
    self.optionsViewController = nil;
    self.keyboardViewController = nil;
    self.overView = nil;
    [super viewDidUnload];
}

- (void)presentNotes {
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *noteEntry = [model.currentNoteEntries objectAtIndex:model.selectedNoteIndex];
    self.currentNoteViewController.noteEntry = noteEntry;
}

static const int NEXT_DIRECTION = 0;
static const int PREVIOUS_DIRECTION = 1;

- (void) panReceived:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    // TODO This is a bit simplified for now...
    int xDirection = (velocity.x < 0) ? PREVIOUS_DIRECTION : NEXT_DIRECTION;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        numberOfTouchesInCurrentPanGesture = recognizer.numberOfTouches;
        if (numberOfTouchesInCurrentPanGesture == 1) {
            if (xDirection == PREVIOUS_DIRECTION) {
                [self.view insertSubview:self.previousNoteViewController.view belowSubview:self.currentNoteViewController.view];
            } else {
                [self.view insertSubview:self.nextNoteViewController.view belowSubview:self.currentNoteViewController.view];
            }
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // CLEANUP
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (numberOfTouchesInCurrentPanGesture == 1) {
            CGRect frame = self.currentNoteViewController.view.frame;
            CGRect newFrame;
            newFrame = CGRectMake(0 + point.x, 0, frame.size.width, frame.size.height);
            self.currentNoteViewController.view.frame = newFrame;
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"note is touched");
    if(optionsShowing) {
        // find the element that is being touched, if any.
        CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        CGRect frame = self.overView.frame;
        if(!CGRectContainsPoint(frame, currentLocation)) {
            NSLog(@"touch options panel");
        }else {
            [self shiftCurrentNoteOriginToPoint:CGPointMake(0, 0)];
            NSLog(@"touched outside of options");
        }
    }
}

#pragma mark OptionsViewController Delegate

-(void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor {
    [self.currentNoteViewController setColors:color textColor:textColor];
}

-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point{
    self.optionsViewController.view.frame = CGRectMake(0, 0, 320, 480);
    [self.currentNoteViewController.textView resignFirstResponder];
    [self.view insertSubview:self.optionsViewController.view belowSubview:self.currentNoteViewController.view];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(point.x, point.y, 320, 480);
                     } completion:^(BOOL success){
                         if (point.x == 0) {
                             [self.overView removeFromSuperview];
                             self.overView = nil;
                             self.optionsViewController.view.frame = CGRectMake(-320,0,320,480);
                             optionsShowing = NO;
                         }else {
                             if (!self.overView) {
                                 self.overView = [UIView new];
                                 [self.view addSubview:self.overView];
                                 optionsShowing = YES;
                             }
                             self.overView.frame = self.currentNoteViewController.view.frame;
                         }
                     }];
}

#pragma mark - Keyboard notifications

- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    // Step 1: Get the size of the keyboard.
    CGSize keyboardSize = [[[theNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Step 2: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.currentNoteViewController.textView.contentInset = contentInsets;
    self.currentNoteViewController.textView.scrollIndicatorInsets = contentInsets;
}

- (void) shiftViewDownAfterKeyboard:(NSNotification*)theNotification;
{
    // Step 1: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.currentNoteViewController.textView.contentInset = contentInsets;
    self.currentNoteViewController.textView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Keyboard Delegate

//This might want to be changed so that the NoteViewController handles all of this.
-(void)printKeySelected:(NSString *)label {
    //may have to add in the "space" case
    if ([label isEqualToString:@" "]) {
        NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
        BOOL isALetterTwoAgo = [set characterIsMember: [self.currentNoteViewController.textView.text characterAtIndex:self.currentNoteViewController.textView.selectedRange.location-2]];
        unichar lastCharacterUni = [self.currentNoteViewController.textView.text characterAtIndex:self.currentNoteViewController.textView.selectedRange.location-1];
        NSString *lastCharacter = [NSString stringWithCharacters:&lastCharacterUni length:1];
        if (isALetterTwoAgo && [lastCharacter isEqualToString:@" "]){
            // code that you use to remove the last character
            [self.currentNoteViewController.textView deleteBackward];
            [self.currentNoteViewController.textView insertText:@"."];
        }
    }
    if ([label isEqualToString:@"delete"]) {
        
        //delete the last character out of the textview
        NSUInteger lastCharacterPosition = [self.currentNoteViewController.textView.text length];
        
        //not at the beginning of the note
        if(lastCharacterPosition > 0){
            [self.currentNoteViewController.textView deleteBackward];
        }
    } else if ([label isEqualToString:@"return"]) {
        unichar ch = 0x000A;
        NSString *unicodeString = [NSString stringWithCharacters:&ch length:1];
        [self.currentNoteViewController.textView insertText:unicodeString];
    } else {
        [self.currentNoteViewController.textView insertText:label];
    }
    [self.currentNoteViewController.textView.delegate textViewDidChange:self.currentNoteViewController.textView];
}

-(void)closeKeyboard {
    [self.currentNoteViewController.textView resignFirstResponder];
}

-(void)undoEdit {
    [self.currentNoteViewController.textView.undoManager undo];
    NSLog(@"Undo Detected");
}
-(void)redoEdit {
    [self.currentNoteViewController.textView.undoManager redo];
    NSLog(@"Redo Detected");
}


-(void)panKeyboard:(CGPoint)point {
    CGRect frame = self.keyboardViewController.view.frame;
    frame.origin.y =  0 + point.y;
    if (frame.origin.y < 0) frame.origin.y = 0;
    self.keyboardViewController.view.frame = frame;
}

-(void)snapKeyboardBack {
    CGRect frame = self.keyboardViewController.view.frame;
    frame.origin = CGPointMake(0, 0);
    self.keyboardViewController.view.frame = frame;
}

@end
