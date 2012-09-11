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
#import "NoteDocument.h"

@interface NoteViewController ()

@end

@implementation NoteViewController

@synthesize scrollView;
@synthesize optionsDot;
@synthesize relativeTime;
@synthesize absoluteTime;
@synthesize delegate, textView, noteEntry;

- (id)init
{
    self = [super initWithNibName:@"NoteViewController" bundle:nil];
    if (self){
        // init
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

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

-(void)setNote:(NoteDocument *)newNote
{
    if (_note != newNote) {
        _note = newNote;
        
        NSLog(@"%@ [%d]",newNote.debugDescription,__LINE__);
        
        [self setNoteEntry:_note.noteEntry];
        
        //[self configureView];
    }
}

- (void) setNoteEntry:(NoteEntry *)entry {
    if (entry != noteEntry) {
        noteEntry = entry;
        self.textView.text = [noteEntry text];
        self.absoluteTime.text = [noteEntry absoluteDateString];
        self.relativeTime.text = [noteEntry relativeDateString];
        
        UIColor *bgColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
        [self.view setBackgroundColor:bgColor];
        
        [self setTextLabelColorsByBGColor:bgColor];
        
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

- (void)setTextLabelColorsByBGColor:(UIColor *)color
{
    int index = [[UIColor getNoteColorSchemes] indexOfObject:color];
    if (index==NSNotFound) {
        // UICachedDeviceWhiteColor
        NSLog(@"color for note bg not found in NoteColor schemes, setting to white [%d]",__LINE__);
        index = 0;
    }
    if (index >= 4) {
        [self.textView setTextColor:[UIColor whiteColor]];
    } else {
        [self.textView setTextColor:[UIColor blackColor]];
    }
    
    self.absoluteTime.textColor = [[UIColor getHeaderColorSchemes] objectAtIndex:index];
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

- (IBAction)optionsSelected{
    [self.delegate shiftCurrentNoteOriginToPoint:CGPointMake(96, 0)];
}

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor{
    
    if (![self.note.color isEqual:color]) {
        // update the model, but avoid unecessary updates
        [self.note setColor:color];
    }
    
    /*
     if (textColor) {
     self.textView.textColor = textColor;
     } else {
     self.textView.textColor = [UIColor blackColor];
     }
     */
    self.view.backgroundColor = color;
    [self setTextLabelColorsByBGColor:color];
}

-(void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    self.scrollView.contentOffset = aScrollView.contentOffset;
}

- (void)textViewDidChange:(UITextView *)aTextView{
    if (![aTextView.text hasPrefix:@"\n"]) {
        aTextView.text = [NSString stringWithFormat:@"\n%@", aTextView.text];

    }    
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    [self.note setText:aTextView.text];
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
