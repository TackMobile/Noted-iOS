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
#import "UIImage+Crop.h"

@interface NoteStackViewController () {
    int numberOfTouchesInCurrentPanGesture;
    BOOL optionsShowing;
    NSMutableArray *deletingViews;
}

- (void) presentNotes;

@end

@implementation NoteStackViewController

@synthesize dismissBlock;
@synthesize currentNoteViewController;
@synthesize nextNoteViewController;
@synthesize panGestureRecognizer;
@synthesize keyboardViewController;
@synthesize optionsViewController, overView, nextNoteEntry, previousNoteEntry;
@synthesize previousNoteDocument;
@synthesize nextNoteDocument;

- (id)initWithDismissalBlock:(DismissalBlock)dismiss
{
    self = [super initWithNibName:@"NoteStackViewController" bundle:nil];
    if (self){
        self.dismissBlock = dismiss;
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 6.5;
    
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
    self.optionsViewController.view.frame = CGRectMake(0, 0, 320, 480);
    self.optionsViewController.view.hidden = YES;
    
    self.currentNoteViewController = [[NoteViewController alloc] init];
    self.currentNoteViewController.delegate = self;
    [self.view addSubview:self.currentNoteViewController.view];
    self.currentNoteViewController.textView.inputView = self.keyboardViewController.view;
    
    self.nextNoteViewController = [[NoteViewController alloc] init];
    [self.view insertSubview:self.nextNoteViewController.view belowSubview:self.currentNoteViewController.view];
    
    [self.view insertSubview:self.optionsViewController.view belowSubview:self.currentNoteViewController.view];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    /*
     UISwipeGestureRecognizer *twoFingerSwipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoSwipeDown:)];
     [twoFingerSwipeDown setNumberOfTouchesRequired:2];
     [twoFingerSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
     [self.view addGestureRecognizer:twoFingerSwipeDown];
     
     UISwipeGestureRecognizer *twoFingerSwipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoSwipeLeft:)];
     [twoFingerSwipeLeft setNumberOfTouchesRequired:2];
     [twoFingerSwipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
     [self.view addGestureRecognizer:twoFingerSwipeLeft];
     */
    
       
}

- (void)handleTwoSwipeLeft:(UIGestureRecognizer *)gesture
{
    NSLog(@"did two swipe left");
}

- (void)handleTwoSwipeDown:(UIGestureRecognizer *)gesture
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self presentNotes];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentNotes];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentNoteViewController = nil;
    self.nextNoteViewController = nil;
    self.optionsViewController = nil;
    self.keyboardViewController = nil;
    self.overView = nil;
    self.nextNoteEntry = nil;
    self.previousNoteEntry = nil;
    [super viewDidUnload];
}

/*
 - (void)viewWillDisappear:(BOOL)animated
 {
 [super viewWillDisappear:animated];
 
 NoteDocument *doc = self.currentNoteViewController.note;
 }
 */

- (void)presentNotes {
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    NSUInteger currentIndex = model.selectedNoteIndex;
    
    //self.currentNoteViewController.noteEntry = [model noteAtSelectedNoteIndex];
    self.currentNoteViewController.note = [model noteDocumentAtIndex:model.selectedNoteIndex];
    
    self.previousNoteEntry = [model previousNoteInStackFromIndex:currentIndex];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:currentIndex];
    
    self.nextNoteDocument = [model previousNoteDocInStackFromIndex:currentIndex];
    self.previousNoteDocument = [model nextNoteDocInStackFromIndex:currentIndex];
}

static const int NEXT_DIRECTION = 0;
static const int PREVIOUS_DIRECTION = 1;
static const float DURATION = 0.3;
static const float FLIP_VELOCITY_THRESHOLD = 500;

- (void) panReceived:(UIPanGestureRecognizer *)recognizer {
    ApplicationModel *model = [ApplicationModel sharedInstance];
    CGPoint point = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    CGRect viewFrame = self.view.frame;
    int noteCount = [model.currentNoteEntries count];
    NoteDocument *entryUnderneath;
    
    if (self.currentNoteViewController.view.frame.origin.x < 0) {
        self.optionsViewController.view.hidden = YES;
    }
    
    int xDirection = (velocity.x < 0) ? PREVIOUS_DIRECTION : NEXT_DIRECTION;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        numberOfTouchesInCurrentPanGesture = recognizer.numberOfTouches;
        if (numberOfTouchesInCurrentPanGesture == 1) {
            if (noteCount == 1) {
                self.nextNoteViewController.view.hidden = YES;
            } else {
                self.nextNoteViewController.view.hidden = NO;
                if (xDirection == PREVIOUS_DIRECTION) {
                    entryUnderneath = previousNoteDocument;
                } else {
                    entryUnderneath = nextNoteDocument;
                }
                self.nextNoteViewController.note = entryUnderneath;
            }
        } else if (numberOfTouchesInCurrentPanGesture >= 2) {
            
            BOOL popToList = (velocity.y > 0) && numberOfTouchesInCurrentPanGesture==2 ? YES : NO;
            if (popToList) {
                [self popToNoteList:model.selectedNoteIndex];
            } else {
                
                deletingViews = [NSMutableArray new];
                CGRect rect = CGRectMake(0, 0, 320, 480);
                UIGraphicsBeginImageContextWithOptions(rect.size,YES,0.0f);
                CGContextRef context = UIGraphicsGetCurrentContext();
                [self.currentNoteViewController.view.layer renderInContext:context];
                UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // Create and show the new image from bitmap data
                for (int k = 0; k <= numberOfTouchesInCurrentPanGesture; k++) {
                    // Create rectangle that represents a cropped image
                    // from the middle of the existing image
                    CGRect cropRect = CGRectMake(0, (480*k)/(numberOfTouchesInCurrentPanGesture+1), 320, 480/(numberOfTouchesInCurrentPanGesture+1));
                    
                    // Create and show the new image from bitmap data
                    UIImageView *imageView = [[UIImageView alloc] initWithImage:[viewImage crop:cropRect]];
                    imageView.frame = CGRectMake(0, 0, 320, 480/(numberOfTouchesInCurrentPanGesture+1));
                    [deletingViews addObject:imageView];
                    imageView.hidden = YES;
                    [self.view addSubview:imageView];
                }

            }
                        
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (currentNoteFrame.origin.x > viewFrame.size.width/2 || velocity.x > FLIP_VELOCITY_THRESHOLD) {
            [UIView animateWithDuration:DURATION
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.currentNoteViewController.view.frame = CGRectMake(viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                             }
                             completion:^(BOOL success) {
                                 if (success) {
                                     [model setCurrentNoteIndexToPrevious];
                                     int currentIndex = model.selectedNoteIndex;
                                     [self updateNoteDocumentsForIndex:currentIndex];
                                 }
                             }];
        } else if (currentNoteFrame.origin.x + currentNoteFrame.size.width < viewFrame.size.width/2 || velocity.x < -FLIP_VELOCITY_THRESHOLD) {
            [UIView animateWithDuration:DURATION
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.currentNoteViewController.view.frame = CGRectMake(-viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                             }
                             completion:^(BOOL success) {
                                 if (success) {
                                     [model setCurrentNoteIndexToNext];
                                     
                                     int currentIndex = model.selectedNoteIndex;
                                     [self updateNoteDocumentsForIndex:currentIndex];
                                     
                                 }
                             }];
        } else {
            [UIView animateWithDuration:DURATION
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.currentNoteViewController.view.frame = CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height);
                             }
                             completion:NULL];
        }
        
                
        if (numberOfTouchesInCurrentPanGesture >= 2) {            
            for (int k = 0; k < [deletingViews count]; k++) {
                UIView *view = [deletingViews objectAtIndex:k];
                [UIView animateWithDuration:0.25
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     CGRect frame = view.frame;
                                     frame.origin = CGPointMake(0, (480*k/(deletingViews.count)));
                                     view.frame = frame;
                                 }
                                 completion:^(BOOL finished){
                                     self.currentNoteViewController.view.hidden = NO;
                                     [view removeFromSuperview];
                                 }];
            }
            [deletingViews removeAllObjects];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (numberOfTouchesInCurrentPanGesture == 1) {
            CGRect frame = self.currentNoteViewController.view.frame;
            CGRect newFrame;
            newFrame = CGRectMake(0 + point.x, 0, frame.size.width, frame.size.height);
            self.currentNoteViewController.view.frame = newFrame;
            if (noteCount > 1) {
                if (currentNoteFrame.origin.x + currentNoteFrame.size.width > viewFrame.size.width) {
                    entryUnderneath = previousNoteDocument;
                    self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
                    self.nextNoteViewController.note = entryUnderneath;
                } else if (currentNoteFrame.origin.x < viewFrame.origin.x) {
                    entryUnderneath = nextNoteDocument;
                    self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
                    self.nextNoteViewController.note = entryUnderneath;
                }
            }
        } else if (numberOfTouchesInCurrentPanGesture == 2) {
            if (point.x > 0) {
                self.currentNoteViewController.view.hidden = YES;
                for (int k = 0; k < [deletingViews count]; k++) {
                    double middle = deletingViews.count/2.0;
                    UIImageView *view = [deletingViews objectAtIndex:k];
                    view.hidden = NO;
                    CGRect frame = view.frame;
                    frame.origin.x = 0 + (point.x);
                    if (k < [deletingViews count]/2.0) {
                        frame.origin.y = (480*k/(deletingViews.count)) - point.x*((middle - k)/middle);
                    }else {
                        frame.origin.y = (480*k/(deletingViews.count)) + point.x*((k-middle)/middle);
                    }
                    if (frame.origin.x < 0) {
                        frame.origin.x = 0;
                    }
                    view.frame = frame;
                }
            }
        }
    }
}

- (void)popToNoteList:(int)index
{
    self.dismissBlock(index);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateNoteDocumentsForIndex:(NSUInteger)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    self.previousNoteEntry = [model previousNoteInStackFromIndex:index];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:index];
    
    self.previousNoteDocument = [model previousNoteDocInStackFromIndex:index];
    self.nextNoteDocument = [model nextNoteDocInStackFromIndex:index];
    
    self.currentNoteViewController.note = [model noteDocumentAtIndex:index];
    self.currentNoteViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"note is touched");
    if(!self.optionsViewController.view.hidden) {
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
    if (point.x != 0) {
        self.optionsViewController.view.hidden = NO;
    } 
    [self.currentNoteViewController.textView resignFirstResponder];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(point.x, point.y, 320, 480);
                     } completion:^(BOOL success){
                         if (point.x == 0) {
                             [self.overView removeFromSuperview];
                             self.overView = nil;
                             self.optionsViewController.view.hidden = YES;
                         }else {
                             if (!self.overView) {
                                 self.overView = [UIView new];
                                 [self.view addSubview:self.overView];
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
//TODO error checking isALetterTwoAgo

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
