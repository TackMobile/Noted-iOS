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

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor{
    if (textColor) {
        self.textView.textColor = textColor;
    }else {
        self.textView.textColor = [UIColor blackColor];
    }
    self.view.backgroundColor = color;
}

@end
