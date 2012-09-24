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
#import "NoteData.h"
#import "Utilities.h"

@interface NoteViewController ()

@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;

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
        
        [self setNoteEntry:_note.noteEntry];
    }
}

- (void)setWithNoDataTemp:(BOOL)val
{
    if (val) {
        self.textView.text = @"";
        self.absoluteTime.text = @"";
        self.relativeTime.text = @"";
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self setTextLabelColorsByBGColor:self.view.backgroundColor];
        [self setShadowForXOffset];
        [self.optionsDot setHidden:YES];
    } else {
        [self updateUIForCurrentEntry];
        [self.optionsDot setHidden:NO];
    }
}

- (void)setWithPlaceholderData:(BOOL)val
{
    if (val) {
        NoteData *placeholder = [[NoteData alloc] init];
        self.textView.text = [placeholder noteText];
        self.absoluteTime.text = [Utilities formatDate:[NSDate date]];
        self.relativeTime.text = [Utilities formatRelativeDate:[NSDate date]];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self setTextLabelColorsByBGColor:self.view.backgroundColor];
        [self setShadowForXOffset];
    } else {
        [self updateUIForCurrentEntry];
    }
}

- (void) setNoteEntry:(NoteEntry *)entry {
    if (entry != noteEntry) {
        noteEntry = entry;
        [self updateUIForCurrentEntry];
    }
}

- (void)updateUIForCurrentEntry
{
    self.textView.text = [noteEntry text];
    self.absoluteTime.text = [noteEntry absoluteDateString];
    self.relativeTime.text = [noteEntry relativeDateString];
    
    UIColor *bgColor = noteEntry.noteColor ? noteEntry.noteColor : [UIColor whiteColor];
    [self.view setBackgroundColor:bgColor];
    
    [self setTextLabelColorsByBGColor:bgColor];
    
    [self setShadowForXOffset];
}

- (void)setShadowForXOffset
{
    self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.view.layer.shadowOffset = CGSizeMake(-1.0,0);
    self.view.layer.shadowOpacity = .70;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.view.layer.shouldRasterize = YES;
    [self.view.layer setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:self.view.bounds cornerRadius:6.5] CGPath]];
    self.view.layer.cornerRadius = 6.5;
    
    [self.view setNeedsDisplay];
}

- (void)setTextLabelColorsByBGColor:(UIColor *)color
{
    int index = [[UIColor getNoteColorSchemes] indexOfObject:color];
    if (index==NSNotFound) {
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
    [self.delegate showOptions];
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
    
    NSString *shorthand = @":time";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    
    [self checkForShorthand:shorthand withReplacement:[dateFormatter stringFromDate:[NSDate date]]];
}

- (void)checkForShorthand:(NSString *)shorthand withReplacement:(NSString *)replacement
{
    NSUInteger location = [self.textView.text rangeOfString:shorthand].location;
    if (location != NSNotFound) {
        self.textView.text = [self.textView.text stringByReplacingCharactersInRange:NSMakeRange(location, shorthand.length) withString:replacement];
        [self.note setText:self.textView.text];
    }
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    [self.note setText:aTextView.text];
}

- (BOOL)usingDefaultKeyboard
{
    BOOL using = [[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultKeyboard"];
    return using;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (![self usingDefaultKeyboard]) {
        return YES;
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    tap.delegate = self;
    self.tapGestureRecognizer = tap;
    
    [keyWindow addGestureRecognizer:self.tapGestureRecognizer];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    pan.delegate = self;
    self.panGestureRecognizer = pan;
    
    [keyWindow addGestureRecognizer:self.panGestureRecognizer];
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (![self usingDefaultKeyboard]) {
        return YES;
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    // Remove the gesture recognizers when the keyboard is dismissed.
    [keyWindow removeGestureRecognizer:self.tapGestureRecognizer];
    [keyWindow removeGestureRecognizer:self.panGestureRecognizer];
    
    return YES;
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

- (void)handleTapFrom:(UIGestureRecognizer *)recognizer {
    [self.textView resignFirstResponder];
    CGPoint touchPoint = [recognizer locationInView:self.view];
    if (CGRectContainsPoint(self.optionsDot.frame, touchPoint)) {
        [self.delegate showOptions];
    } 
}

- (void)handlePanFrom:(UIGestureRecognizer *)recognizer {
    // It's not likely the user will pan in the search bar, but we can capture that too.
    //CGPoint touchPoint = [recognizer locationInView:self.view];
    //if (!CGRectContainsPoint(self.textView.frame, touchPoint)) {
    [self.textView resignFirstResponder];
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"closeIt" object:nil userInfo:nil];
    //}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Return YES to prevent this gesture from interfering with, say, a pan on a map or table view, or a tap on a button in the tool bar.
    return YES;
}

@end
