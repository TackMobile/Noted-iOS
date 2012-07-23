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

@interface NoteStackViewController () {
    int numberOfTouchesInCurrentPanGesture;
    BOOL optionsShowing;
}
@end

@implementation NoteStackViewController
@synthesize currentNoteViewController, nextNoteViewController, previousNoteViewController, panGestureRecognizer, optionsViewController, overView;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 6.5;
    self.view.layer.masksToBounds = NO;
    
    self.optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
    [self.view addSubview:self.optionsViewController.view];
    
    self.currentNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.nextNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.previousNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    [self.view addSubview:self.currentNoteViewController.view];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    self.currentNoteViewController.delegate = self;
    self.optionsViewController.delegate = self;
}

- (void)viewDidUnload {
    self.currentNoteViewController = nil;
    self.previousNoteViewController = nil;
    self.nextNoteViewController = nil;
    [super viewDidUnload];
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

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark - OptionsDelegate

-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point{
    self.optionsViewController.view.frame = CGRectMake(0, 0, 320, 480);
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

@end
