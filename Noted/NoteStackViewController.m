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
    
}
@end

@implementation NoteStackViewController
@synthesize currentNoteViewController, nextNoteViewController, previousNoteViewController, panGestureRecognizer;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 6.5;
    self.view.layer.masksToBounds = NO;
    
    self.currentNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.nextNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    self.previousNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil];
    [self.view addSubview:self.currentNoteViewController.view];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
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

@end
