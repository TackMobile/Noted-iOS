//
//  NoteKeyOpViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/29/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteKeyOpViewController.h"
#import "UIColor+HexColor.h"
#import "NoteEntry.h"

@interface NoteKeyOpViewController ()

@end

@implementation NoteKeyOpViewController
@synthesize addNoteMain;
@synthesize addNoteCorners;
@synthesize notes,keyboardVC,optionsVC,mailVC,messageVC,noteVC,nextNoteVC,previousNoteVC,overView,delegate,openedNoteDocuments;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.layer.cornerRadius = 6.5;
        self.view.layer.masksToBounds = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //defaults
    optionsShowing = NO;
    self.openedNoteDocuments = [NSMutableArray new];
    
    self.optionsVC = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
    self.optionsVC.view.frame = CGRectMake(-320, 0, 320, 480);
    self.optionsVC.delegate = self;
    
    
    self.noteVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    self.noteVC.view.frame = CGRectMake(0,0,320,480);
    self.noteVC.delegate = self;
    [self addAllGestures];
    
    self.previousNoteVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    self.previousNoteVC.delegate = self;
    
    self.nextNoteVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    self.nextNoteVC.delegate = self;
    
   // self.trashNoteView.hidden = YES;
    
 //   self.notes = [[NSMutableArray alloc] init];
 //   self.noteCells = [[NSMutableArray alloc] init];
    
    self.overView = [[UIView alloc] initWithFrame:CGRectMake(96, 0, 224, 480)];
    self.overView.backgroundColor = [UIColor clearColor];
    
    
 //   [self.view bringSubviewToFront:self.scrollView];
    
    //make the keyboard view offscreen
    self.keyboardVC = [[KeyboardViewController alloc] initWithNibName:@"KeyboardViewController" bundle:nil];
    self.keyboardVC.delegate = self;
    
    
    self.addNoteMain.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.addNoteMain.layer.shadowOffset = CGSizeMake(2,2);
    self.addNoteMain.layer.shadowOpacity = .50;
    self.addNoteCorners.layer.bounds = self.addNoteMain.bounds;
    self.addNoteCorners.layer.cornerRadius = 6.5;
    self.addNoteCorners.layer.masksToBounds = YES;
    
    UITextView *relativeTime = [[UITextView alloc] init];
    relativeTime.frame = self.noteVC.relativeTimeText.frame;
    relativeTime.font = self.noteVC.relativeTimeText.font;
    relativeTime.textColor = [self.noteVC colorWithHexString:@"AAAAAA"];
    relativeTime.text = @"Today";
    UITextView *absoluteTime = [[UITextView alloc] init];
    absoluteTime.frame = self.noteVC.absoluteTimeText.frame;
    absoluteTime.font = self.noteVC.absoluteTimeText.font;
    absoluteTime.textColor = [self.noteVC colorWithHexString:@"AAAAAA"];
    absoluteTime.text = [self.noteVC formatDate:[NSDate date]];
    
    [self.addNoteCorners addSubview:relativeTime];
    [self.addNoteCorners addSubview:absoluteTime];
    
    //Register for notifications so the keyboard load will push any text into view
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewUpForKeyboard:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewDownAfterKeyboard)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)addAllGestures{
    // set up a two-finger pan recognizer as a dummy to steal two-finger scrolls from the scroll view
    // we initialize without a target or action because we don't want the two-finger pan to be handled
    UIPanGestureRecognizer *twoFingerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panLayer:)];
    twoFingerPan.minimumNumberOfTouches = 2;
    twoFingerPan.maximumNumberOfTouches = 2;
    [self.noteVC.noteTextView addGestureRecognizer:twoFingerPan];
    
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panLayer:)];
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.minimumNumberOfTouches = 1;
    [self.noteVC.view addGestureRecognizer:panRecognizer];
    
    
}

-(void)openTheNote:(NoteDocument*)aNote{
    self.noteVC.note = aNote;
    self.previousNoteVC.view.alpha = 1;
    self.nextNoteVC.view.alpha = 1;
    
    currentNoteIndex = 0;
    for (NoteEntry *entry in self.notes) {
        if (entry.fileURL == aNote.fileURL) {
            currentNoteIndex = [self.notes indexOfObject:entry];
            break;
        }
    }
    int howManyNotes = [self.notes count];

 //   NSUInteger location = [self.notes indexOfObject:aNote];
    if (howManyNotes == 1) {
        self.previousNoteVC.note = aNote;
        self.nextNoteVC.note = aNote;
        self.previousNoteVC.view.alpha = 0;
        self.nextNoteVC.view.alpha = 0;
        
    }else {
        //beginning of list
        if(currentNoteIndex == 0) {
            NoteEntry *previousEntry = [self.notes objectAtIndex:(howManyNotes -1)];
            NoteDocument *previousDocument = [[NoteDocument alloc] initWithFileURL:previousEntry.fileURL];
            NoteEntry *nextEntry = [self.notes objectAtIndex:(currentNoteIndex +1)];
            NoteDocument *nextDocument = [[NoteDocument alloc] initWithFileURL:nextEntry.fileURL];
            [previousDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.previousNoteVC.note = previousDocument;
                    [self.openedNoteDocuments addObject:previousDocument];
                });
            }];
            [nextDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.nextNoteVC.note = nextDocument;
                    [self.openedNoteDocuments addObject:nextDocument];
                });
            }];

        }else if((currentNoteIndex+1)==howManyNotes){
            //end of list
            NoteEntry *previousEntry = [self.notes objectAtIndex:(currentNoteIndex -1)];
            NoteDocument *previousDocument = [[NoteDocument alloc] initWithFileURL:previousEntry.fileURL];
            NoteEntry *nextEntry = [self.notes objectAtIndex:(0)];
            NoteDocument *nextDocument = [[NoteDocument alloc] initWithFileURL:nextEntry.fileURL];
            [previousDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.previousNoteVC.note = previousDocument;
                    [self.openedNoteDocuments addObject:previousDocument];
                });
            }];
            [nextDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.nextNoteVC.note = nextDocument;
                    [self.openedNoteDocuments addObject:nextDocument];
                });
            }];
        }else {
            NoteEntry *previousEntry = [self.notes objectAtIndex:(currentNoteIndex -1)];
            NoteDocument *previousDocument = [[NoteDocument alloc] initWithFileURL:previousEntry.fileURL];
            NoteEntry *nextEntry = [self.notes objectAtIndex:(currentNoteIndex +1)];
            NoteDocument *nextDocument = [[NoteDocument alloc] initWithFileURL:nextEntry.fileURL];
            [previousDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.previousNoteVC.note = previousDocument;
                    [self.openedNoteDocuments addObject:previousDocument];
                });
            }];
            [nextDocument openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.nextNoteVC.note = nextDocument;
                    [self.openedNoteDocuments addObject:nextDocument];
                });
            }];
        }
    }
    [self.noteVC viewWillAppear:YES];
    [self.previousNoteVC viewWillAppear:YES];
    [self.nextNoteVC viewWillAppear:YES];
    self.noteVC.view.frame = CGRectMake(0,0,320,480);
    self.previousNoteVC.view.frame = CGRectMake(320,0,320,480);
    self.nextNoteVC.view.frame = CGRectMake(0,0,320,480);
    self.addNoteMain.frame = CGRectMake(320,0,320,480);
    
    //   self.scrollView.frame = CGRectMake(0, -480, 320, 480);
    
    self.noteVC.noteTextView.inputView = self.keyboardVC.view;
    [self.view addSubview:self.nextNoteVC.view];
    [self.view addSubview:self.optionsVC.view];
    [self.view addSubview:self.noteVC.view];
    [self.view addSubview:self.previousNoteVC.view];
    [self.view addSubview:self.addNoteMain];
    [self.view bringSubviewToFront:self.addNoteMain];
    
}



#pragma mark - 
#pragma mark Pans and Actions


//-(void)trashNote:(Note*)aNote {
//    //animations here
//    [self deleteNote:aNote];
//    self.scrollView.frame = CGRectMake(0, -480, 320, 480);
//}

//-(void)panNote:(CGPoint)point {
//    NSLog(@"panning in list");
//    [self updateNoteList];
//    [self.view bringSubviewToFront:self.scrollView];
//    
//    CGRect frame = self.scrollView.frame;
//    frame.origin.y = -480 + point.y;
//    if (frame.origin.y < (-frame.size.height)) {
//        frame.origin.y = (-frame.size.height);
//    }
//    
//    self.scrollView.frame = frame;
//    
//}

//-(void)panFinish:(BOOL)shouldShow closeNote:(Note *)aNote{
//    NSLog(@"finished pan in list");
//    
//    [self updateNoteList];
//    
//    if (shouldShow) {
//        [self animateLayerY:self.scrollView toPoint:0];
//    }else {
//        [self animateLayerY:self.scrollView toPoint:-480];
//    }
//    
//}

- (IBAction)panLayer:(UIPanGestureRecognizer *)pan {    
    [self.noteVC.noteTextView resignFirstResponder];
    CGPoint point = [pan translationInView:self.view];
    CGPoint velocity = [pan velocityInView:self.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        
        if (pan.numberOfTouches == 1) {
            touchesOnScreen = 1;
        }else if (pan.numberOfTouches == 2) {
            touchesOnScreen =2;
            NSLog(@"twofingers on screen");
        }
        
        //setup all the views
        CGRect frame = self.addNoteMain.frame;
        frame.origin = CGPointMake(320, 0);
        self.addNoteMain.frame = frame;
        
    }
    
    if (touchesOnScreen == 1){
        if (pan.state == UIGestureRecognizerStateChanged) {
            //panning from right to left
            if (point.x <0 && (fabs(4*point.x) >= fabs(point.y)) && velocity.x > -500) {
                NSLog(@"recognizing right to left pan in noteList");
                //if only 1 note
                if(self.previousNoteVC.note == self.noteVC.note) {
                    
                    CGRect otherFrame = self.noteVC.view.frame;
                    otherFrame.origin.x = 0 + point.x;
                    self.noteVC.view.frame = otherFrame;
                    
                }else {                
                    
                    CGRect frame = self.previousNoteVC.view.frame;
                    frame.origin.x =  320 + point.x;
                    if (frame.origin.x > 320) frame.origin.x = 320;
                    self.previousNoteVC.view.frame = frame;
                    
                    //make sure the other layer is offscreen
                    CGRect otherFrame = self.noteVC.view.frame;
                    otherFrame.origin.x = 0;
                    self.noteVC.view.frame = otherFrame;
                }
            }
            //panning from left to right
            else if (point.x >0 && (fabs(4*point.x) >= fabs(point.y)) && velocity.x < 500) {
                NSLog(@"recognizing left to right pan in NoteList");
                
                //if only 1 note
                if(self.previousNoteVC.note == self.noteVC.note) {
                    
                    CGRect otherFrame = self.noteVC.view.frame;
                    otherFrame.origin.x = 0 + point.x;
                    self.noteVC.view.frame = otherFrame;
                    
                }else {
                    CGRect frame = self.noteVC.view.frame;
                    frame.origin.x = point.x;
                    if (frame.origin.x < 0) frame.origin.x = 0;
                    self.noteVC.view.frame = frame;
                    
                    //make sure the other layer is offscreen
                    CGRect otherFrame = self.previousNoteVC.view.frame;
                    otherFrame.origin.x = 320;
                    self.previousNoteVC.view.frame = otherFrame;
                }
            } else {
                NSLog(@"recognizing top to bottom pan");
                // [delegate panNote:point];
                
                // [self animateLayer:topLayerNew toPoint:320];
                // [self animateLayer:mainView toPoint:0];
            }
            
        }
    }
    
    if (touchesOnScreen == 1) {
        if (pan.state == UIGestureRecognizerStateEnded) {
            if (self.previousNoteVC.note == self.noteVC.note) {
                //first and only note
                [self animateLayer:self.noteVC.view toPoint:0 withNote:nil];
                [self animateLayer:self.previousNoteVC.view toPoint:320 withNote:nil];
                
            }else if (self.noteVC.view.frame.origin.x <= 160 && self.previousNoteVC.view.frame.origin.x >= 160 && fabs(velocity.x)<=500) {
                //nothing happens return to original note
                [self animateLayer:self.noteVC.view toPoint:0 withNote:nil];
                [self animateLayer:self.previousNoteVC.view toPoint:320 withNote:nil];
                //Make sure the noteList is handled in this case
                
            } else if (self.noteVC.view.frame.origin.x > 160 || velocity.x >= 500){
                //panned to next Note
                [self animateLayer:self.noteVC.view toPoint:320 withNote:self.nextNoteVC.note];
                [self.noteVC.noteTextView resignFirstResponder];
                NSLog(@"Recognizing next note gesture");
                
                
            } else if (self.previousNoteVC.view.frame.origin.x <= 160 || velocity.x <= -500) {
                
                //panned to a previous note
                [self animateLayer:self.previousNoteVC.view toPoint:0 withNote:self.previousNoteVC.note];
                [self.noteVC.noteTextView resignFirstResponder];
                NSLog(@"Recognizing previous note gesture");
            } 
        }
    }
    
    if (touchesOnScreen == 2){
        if (pan.state == UIGestureRecognizerStateChanged) {
            //panning from right to left
            if (point.x <0 && (fabs(2*point.x) >= fabs(point.y))) {
                NSLog(@"recognizing right to left 2pan");
                CGRect frame = self.addNoteMain.frame;
                frame.origin.x =  320 + point.x;
                if (frame.origin.x > 320) frame.origin.x = 320;
                self.addNoteMain.frame = frame;
                
                //make sure the other layer is offscreen
      //          CGRect otherFrame = self.noteVC.view.frame;
      //          otherFrame.origin.x = 0;
      //          self.noteVC.view.frame = otherFrame;
     //           self.trashNoteView.hidden = YES;
            }
//            //panning from left to right
//            else if (point.x >0 && (fabs(2*point.x) >= fabs(point.y))) {
//                NSLog(@"recognizing left to right 2pan");
//                [self.view bringSubviewToFront:self.trashNoteView];
//                self.trashNoteView.hidden = NO;
//                if (point.x>160) {
//                    self.trashNoteView.text = @"Release to Trash";
//                }
//            } else {
//                NSLog(@"recognizing top to bottom 2pan");
//                [self panNote:point];
//                
//                CGRect otherFrame = self.addNoteMain.frame;
//                otherFrame.origin.x = 320;
//                self.addNoteMain.frame = otherFrame;
//            }
//            
//            if (point.x< 160) {
//                self.trashNoteView.text = @"Trashing note...keep going";
//            }
        }
        
        
        
        if (pan.state == UIGestureRecognizerStateEnded) {
            CGPoint velocity = [pan velocityInView:self.view];
            
            if ( fabs(point.x) <= 160 && fabs(velocity.x) <1000) {
                if (point.y >= 100) {
                    //closing note
                    [self.delegate closeNote];
                    
                }else {
                    //do nothing
                    [self animateLayer:self.addNoteMain toPoint:320 withNote:nil];
                }
            }
            
            else if (point.x <= -160) {
                
                //panned to a new note
                [self animateLayer:self.addNoteMain toPoint:0 withNote:nil];
                [self.noteVC.noteTextView resignFirstResponder];
                NSLog(@"Recognizing add gesture %f  %f",self.addNoteMain.frame.origin.x,point.x);
        //        [self animateLayer:self.addNoteMain toPoint:0 withNote:nil];
                [self addNote];
                
            } 
        }
                //else if (point.x > 160){
//                //panned to trash
//                
//                [self.nvc.noteTextView resignFirstResponder];
//                NSLog(@"Recognizing trash gesture");
//                [self trashNote:self.nvc.note];
//                
//            } 
//            self.trashNoteView.hidden = YES;
//            self.trashNoteView.text = @"Trashing note...keep going";
//        }
//        
    }
}



-(void) animateLayer:(UIView*)layer toPoint:(CGFloat)x withNote:(NoteDocument*)aNote
{
    [UIView animateWithDuration:0.25
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
                         CGRect frame = layer.frame;
                         frame.origin.x = x;
                         layer.frame = frame;
                     }
                     completion:^(BOOL finished){
                         
                         
                         if (aNote) {
                             
                             [self openTheNote:aNote];
                             
                             
                         }
                     }];
}

-(void) animateLayerY:(UIView*)layer toPoint:(CGFloat)y
{
    [UIView animateWithDuration:0.25
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
                         CGRect frame = layer.frame;
                         frame.origin.y = y;
                         layer.frame = frame;
                     }
                     completion:^(BOOL finished){
                     }];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"note is touched");
    if(optionsShowing) {
        // find the element that is being touched, if any.
        CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        CGRect frame = CGRectMake(0, 0, 96, 480);
        if(CGRectContainsPoint(frame, currentLocation)) {
            NSLog(@"touch options panel");
        }else {
            [self closeOptions];
            NSLog(@"touched outside of options");
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark - 
#pragma mark Delegate Events

-(void)addNote {
    
    int index = currentNoteIndex;
    [self.delegate addNoteAtIndex:index];
}



-(void)openOptions {
    self.optionsVC.view.frame = CGRectMake(0, 0, 320, 480);
    [self.view addSubview:self.overView];
    
    if (self.noteVC.noteTextView.isFirstResponder) {
        self.noteVC.noteTextView.editable = NO;
        self.noteVC.view.frame = CGRectMake(0, 0, 320, 216);
    }
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.view.frame = CGRectMake(96, 0, 320, 480);
                         self.keyboardVC.view.frame = CGRectMake(96, 0, 320, 216);;
                     } completion:^(BOOL success){
                         self.overView.frame = self.noteVC.view.frame;
                         optionsShowing = YES;
                     }];
}

-(void)closeOptions {
    [self.overView removeFromSuperview];
    [self.optionsVC returnToOptions];
    CGRect frame = self.keyboardVC.view.frame;
    frame.origin.x = 0;
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.view.frame = CGRectMake(0, 0, 320, 480);
                         self.keyboardVC.view.frame = frame;
                     } completion:^(BOOL success){
                         self.optionsVC.view.frame = CGRectMake(-320,0,320,480);
                         optionsShowing = NO;
                         self.noteVC.noteTextView.editable = YES;
                     }];
}



-(void)closeKeyboard {
    [self shiftViewDownAfterKeyboard];
}

- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.noteTextView.frame = CGRectMake(0, 20, 320, 244);
                     } completion:^(BOOL success){}];
}

- (void) shiftViewDownAfterKeyboard;
{
    [self animateLayerY:self.keyboardVC.view toPoint:216];
    [UIView animateWithDuration:0.15 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.noteTextView.frame = CGRectMake(0, 20, 320, 480);
                     } completion:^(BOOL success){
                         [self.noteVC.noteTextView resignFirstResponder]; 
                     }];
}

//delegate from KeyboardView
-(void)printKeySelected:(NSString *)label {
    //may have to add in the "space" case
    if ([label isEqualToString:@" "]) {
        NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
        BOOL isALetterTwoAgo = [set characterIsMember: [self.noteVC.noteTextView.text characterAtIndex: [self.noteVC.noteTextView.text length]-2]];
        unichar lastCharacterUni = [self.noteVC.noteTextView.text characterAtIndex: [self.noteVC.noteTextView.text length]-1];
        NSString *lastCharacter = [NSString stringWithCharacters:&lastCharacterUni length:1];
        if (isALetterTwoAgo && [lastCharacter isEqualToString:@" "]){
            // code that you use to remove the last character
            [self.noteVC.noteTextView deleteBackward];
            [self.noteVC.noteTextView insertText:@"."];
        }
        
    }
    
    if ([label isEqualToString:@"delete"]) {
        
        //delete the last character out of the textview
        NSUInteger lastCharacterPosition = [self.noteVC.noteTextView.text length];
        
        //not at the beginning of the note
        if(lastCharacterPosition > 0){
            
            [self.noteVC.noteTextView deleteBackward];
        }
    } else if ([label isEqualToString:@"return"]) {
        unichar ch = 0x000A;
        
        NSString *unicodeString = [NSString stringWithCharacters:&ch length:1];
        [self.noteVC.noteTextView insertText:unicodeString];
        
    } else {
        [self.noteVC.noteTextView insertText:label];
    }
    [self.noteVC.noteTextView.delegate textViewDidChange:self.noteVC.noteTextView];
}

-(void)undoEdit {
    [self.noteVC.noteTextView.undoManager undo];
}
-(void)redoEdit {
    [self.noteVC.noteTextView.undoManager redo];
}


-(void)panKeyboard:(CGPoint)point {
    CGRect frame = self.keyboardVC.view.frame;
    frame.origin.y =  0 + point.y;
    if (frame.origin.y < 0) frame.origin.y = 0;
    self.keyboardVC.view.frame = frame;
    
    CGRect otherFrame = self.noteVC.noteTextView.frame;
    otherFrame.size.height = 244 + point.y;
    if (otherFrame.size.height <244) {
        otherFrame.size.height = 244;
    }
    self.noteVC.noteTextView.frame = otherFrame;
}

-(void)snapKeyboardBack {
    [self animateLayerY:self.keyboardVC.view toPoint:0];
    
    [UIView animateWithDuration:0.15 
                          delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ 
                              CGRect otherFrame = self.noteVC.noteTextView.frame;
                              otherFrame.size.height = 244;
                              self.noteVC.noteTextView.frame = otherFrame;}
                     completion:^(BOOL success){}];
}




#pragma mark - 
#pragma mark Messaging (Email/SMS/Tweet)

-(void)sendEmail {
    self.mailVC = [[MFMailComposeViewController alloc] init];
    self.mailVC.mailComposeDelegate = self;
    
    NSArray* lines = [self.noteVC.noteTextView.text componentsSeparatedByString: @"\n"];
    NSString* noteTitle = [lines objectAtIndex:0];
    NSString *body = [[NSString alloc] initWithFormat:@"%@\n\n%@",self.noteVC.noteTextView.text,@"Sent from Noted"];
	[self.mailVC setSubject:noteTitle];
	[self.mailVC setMessageBody:body isHTML:NO];
    [self presentModalViewController:self.mailVC animated:NO];
 //   [self.view addSubview:self.mailVC.view];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
    //[controller.view removeFromSuperview];
}

- (void)sendSMS{
    
    if([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        messageViewController.body = self.noteVC.noteTextView.text;   
        messageViewController.messageComposeDelegate = self;
        messageViewController.wantsFullScreenLayout = NO;
        //SET RECIPIENTS
        [self presentModalViewController:messageViewController animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }  
    else {
        NSString * message = [NSString stringWithFormat:@"This device is currently not configured to send text messages."];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissModalViewControllerAnimated:YES];
    
    if (result == MessageComposeResultCancelled){
        NSLog(@"Message cancelled");
    }else if (result == MessageComposeResultSent){
        NSLog(@"Message sent");
    }else 
        NSLog(@"Message failed");  
}

- (void)sendTweet{
    if([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
        NSString *body = [[NSString alloc] initWithString:self.noteVC.noteTextView.text];
        if ([body length] <= 140) {
            [tweetViewController setInitialText:body];
        }else {
            [tweetViewController setInitialText:[body substringToIndex:140]];
        }
        //       [self.twitterVC setInitialText:body];    
        
        tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) 
        {
            // Dismiss the controller
            [self dismissModalViewControllerAnimated:NO];
        };
        
        [self presentModalViewController:tweetViewController animated:NO];

    }
    
}


#pragma mark - 
#pragma mark OptionsViewController Delegate

-(void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor {
    [self.noteVC setColors:color textColor:textColor];
}

-(void)openShare {
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.view.frame = CGRectMake(120, 0, 320, 480);
                     } completion:^(BOOL success){
                         self.overView.frame = self.noteVC.view.frame;
                     }];
    
}

-(void)openAbout {
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.view.frame = CGRectMake(200, 0, 320, 480);
                     } completion:^(BOOL success){
                         self.overView.frame = self.noteVC.view.frame;
                     }];
}

-(void)returnToOptions {
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.noteVC.view.frame = CGRectMake(96, 0, 320, 480);
                     } completion:^(BOOL success){
                         self.overView.frame = self.noteVC.view.frame;
                     }];
}




- (void)viewDidUnload {
    [self setAddNoteMain:nil];
    [self setAddNoteCorners:nil];
    [super viewDidUnload];
}
@end
