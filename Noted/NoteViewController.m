//
//  NoteViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteViewController.h"

@interface NoteViewController ()

@end

@implementation NoteViewController
@synthesize delegate, textView, noteEntry;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [super viewDidUnload];

}

- (void) setNoteEntry:(NoteEntry *)entry {
    noteEntry = entry;
    self.textView.text = [noteEntry text];
}

- (IBAction)optionsSelected:(id)sender {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0)];
}

@end
