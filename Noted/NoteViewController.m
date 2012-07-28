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
@synthesize scrollView;
@synthesize delegate, textView, noteEntry;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView.contentSize = self.view.frame.size;
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [self setScrollView:nil];
    [super viewDidUnload];

}

- (void) setNoteEntry:(NoteEntry *)entry {
    noteEntry = entry;
    self.textView.text = [noteEntry text];
    [self textViewDidChange:self.textView];
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

-(void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    self.scrollView.contentOffset = aScrollView.contentOffset;
}

- (void)textViewDidChange:(UITextView *)aTextView{
    if (![aTextView.text hasPrefix:@"\n"]) {
        aTextView.text = [NSString stringWithFormat:@"\n%@", aTextView.text];
    }
}

@end
