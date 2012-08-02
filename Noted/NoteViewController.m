//
//  NoteViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteViewController.h"
#import "UIColor+HexColor.h"
#import <QuartzCore/QuartzCore.h>

@interface NoteViewController ()

@end

@implementation NoteViewController
@synthesize scrollView;
@synthesize optionsDot;
@synthesize relativeTime;
@synthesize absoluteTime;
@synthesize delegate, textView, noteEntry;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView.contentSize = self.view.frame.size;
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [self setScrollView:nil];
    [self setOptionsDot:nil];
    [self setRelativeTime:nil];
    [self setAbsoluteTime:nil];
    [super viewDidUnload];

}

- (void) setNoteEntry:(NoteEntry *)entry {
    if (entry != noteEntry) {
        noteEntry = entry;
        self.textView.text = [noteEntry text];
        self.absoluteTime.text = [noteEntry absoluteDateString];
        self.relativeTime.text = [noteEntry relativeDateString];
        [self textViewDidChange:self.textView];
        self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.view.layer.shadowOffset = CGSizeMake(-1,0);
        self.view.layer.shadowOpacity = .70;
        self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.view.layer.shouldRasterize = YES;
        [self.view.layer setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:self.view.bounds cornerRadius:6.5] CGPath]];
        self.view.layer.cornerRadius = 6.5;
    }
}

- (IBAction)optionsSelected{
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0)];
}

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor{
    if (textColor) {
        self.textView.textColor = textColor;
    }else {
        self.textView.textColor = [UIColor blackColor];
    }
    self.view.backgroundColor = color;
    self.absoluteTime.textColor = [[UIColor getHeaderColorSchemes] objectAtIndex:[[UIColor getNoteColorSchemes] indexOfObject:color]];
    self.relativeTime.textColor = self.absoluteTime.textColor;
    self.optionsDot.textColor = self.absoluteTime.textColor;
    if ([UIColor isWhiteColor:color] || [UIColor isShadowColor:color]) {
        self.optionsDot.text = @"\u25CB";
        self.optionsDot.font = [UIFont systemFontOfSize:10];
    } else {
        self.optionsDot.text = @"•";
        self.optionsDot.font = [UIFont systemFontOfSize:40];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    self.scrollView.contentOffset = aScrollView.contentOffset;
}

- (void)textViewDidChange:(UITextView *)aTextView{
    if (![aTextView.text hasPrefix:@"\n"]) {
        aTextView.text = [NSString stringWithFormat:@"\n%@", aTextView.text];
    }
}

#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.optionsDot.frame, location)){
        [self optionsSelected];
    }
}

@end
