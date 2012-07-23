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
@synthesize delegate;
@synthesize textView;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [super viewDidUnload];

}

- (IBAction)optionsSelected:(id)sender {
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0)];
}
@end
