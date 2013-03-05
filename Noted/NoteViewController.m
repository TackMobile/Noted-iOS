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
#import "AnimationStackViewController.h"

@interface NoteViewController ()

@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation NoteViewController

@synthesize relativeTime;
@synthesize delegate, textView;
@synthesize noteEntry=_noteEntry;
@synthesize noteDocument=c;

- (id)init
{
    self = [super initWithNibName:@"NoteViewController" bundle:nil];
    if (self){

    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.cornerRadius = 6.0;
    
    // Remove the edge insets of the text view's scroll view to make the text line up with the
    // corresponding cell's UILabel (which is not inside a scrollview so it has no inset)
    self.textView.contentInset = UIEdgeInsetsMake(TEXT_VIEW_INSET_TOP, TEXT_VIEW_INSET_LEFT, 0, 0);
    self.textView.textAlignment = UITextAlignmentLeft;
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [self setRelativeTime:nil];
    [super viewDidUnload];

}

- (void)setWithNoDataTemp:(BOOL)val
{
    if (_isCurrent) {
        NSLog(@"stop");
    }
    if (val) {
        self.textView.text = @"";
        self.relativeTime.text = @"";
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self setTextLabelColorsByBGColor:self.view.backgroundColor];
        [self setShadowForXOffset];
    } else {
        [self updateUIForCurrentEntry];
    }
}

- (void)setWithPlaceholderData:(BOOL)val defaultData:(NoteData *)defaultData
{
    if (_isCurrent) {
        NSLog(@"stop");
    }
    if (val) {
        NoteData *placeholder = defaultData ? defaultData : [[NoteData alloc] init];
        self.textView.text = [placeholder noteText];
        self.relativeTime.text = [Utilities formatRelativeDate:[NSDate date]];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self setTextLabelColorsByBGColor:self.view.backgroundColor];
        [self setShadowForXOffset];
    } else {
        [self updateUIForCurrentEntry];
    }
}

- (void)setNoteEntry:(NoteEntry *)entry {
    if (_isCurrent) {
        NSLog(@"stop");
    }
    if (_noteEntry != entry) {
        _noteEntry = entry;
        [self updateUIForCurrentEntry];
#ifdef DEBUG
        UILabel *fileURLLabel = (UILabel *)[self.view viewWithTag:889];
        [fileURLLabel setHidden:NO];
        NSString *url = _noteEntry.fileURL.lastPathComponent;
        fileURLLabel.text = [url substringToIndex:15];
#endif
    }
}

- (void)updateUIForCurrentEntry
{
    // prepends a newline for display
    //self.textView.text = [_noteEntry displayText];
    // [dm] 02-28-13 removed this because it seems like a hack...
    self.textView.text = _noteEntry.text;
    
    self.relativeTime.text = [_noteEntry relativeDateString];
    
    UIColor *bgColor = _noteEntry.noteColor ? _noteEntry.noteColor : [UIColor whiteColor];
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
    if (index == NSNotFound) {
        index = 0;
    }
    if (index >= 4) {
        [self.textView setTextColor:[UIColor whiteColor]];
        [self.relativeTime setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        [self.optionsButton setImage:[UIImage imageNamed:@"menu-icon-white"] forState:UIControlStateNormal];
    } else {
        [self.textView setTextColor:[UIColor colorWithHexString:@"333333"]];
        [self.relativeTime setTextColor:[UIColor colorWithWhite:0.2 alpha:0.5]];
        [self.optionsButton setImage:[UIImage imageNamed:@"menu-icon-grey"] forState:UIControlStateNormal];
    }
    if (DEBUG_VIEWS) {
        [self.textView setTextColor:[UIColor redColor]];
        [self.textView setBackgroundColor:[UIColor greenColor]];
        [self.textView setAlpha:0.7f];
    }
}

+ (NSString *)optionsDotTextForColor:(UIColor *)color
{
    NSString *text = @"";
    if ([UIColor isWhiteColor:color] || [UIColor isShadowColor:color]) {
        text = @"\u25CB";
    } else {
        text = @"•";
    }
    
    return text;
}

+ (UIFont *)optionsDotFontForColor:(UIColor *)color
{
    UIFont *font;
    if ([UIColor isWhiteColor:color] || [UIColor isShadowColor:color]) {
        font = [UIFont systemFontOfSize:10];
    } else {
        font = [UIFont systemFontOfSize:40];
    }
    return font;
}

- (IBAction)optionsSelected:(id)sender {
    [self.delegate showOptions];
}

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor{
    
    if (![_noteEntry.noteColor isEqual:color]) {
        // update the model, but avoid unecessary updates
        [self.noteDocument setColor:color];
        [self.noteEntry setNoteData:self.noteDocument.data];
        
        self.view.backgroundColor = color;
        [self setTextLabelColorsByBGColor:color];
        
        [self persistChanges];
    }
}

- (void)persistChanges
{
    [self.delegate didUpdateModel];
    [self.noteDocument updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Helper methods

- (void)checkForShorthand:(NSString *)shorthand withReplacement:(NSString *)replacement
{
    NSUInteger location = [self.textView.text rangeOfString:shorthand].location;
    if (location != NSNotFound) {
        self.textView.text = [self.textView.text stringByReplacingCharactersInRange:NSMakeRange(location, shorthand.length) withString:replacement];
        [self.noteDocument setText:self.textView.text];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    // [dm] I commented this out for now to get the keyboard functioning in a normal state
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    tap.delegate = self;
    self.tapGestureRecognizer = tap;
    
    [keyWindow addGestureRecognizer:self.tapGestureRecognizer];
//
//    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
//    pan.delegate = self;
//    self.panGestureRecognizer = pan;
//    
//    [keyWindow addGestureRecognizer:self.panGestureRecognizer];
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
    // TODO: This should be refactored to enable support for multiple shorthand codes
    // (i.e. :time, :date, :name, etc...)
    
//    NSString *shorthand = @":time";
//    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
//    
//    [self checkForShorthand:shorthand withReplacement:[dateFormatter stringFromDate:[NSDate date]]];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    // Remove the gesture recognizers when the keyboard is dismissed.
    [keyWindow removeGestureRecognizer:self.tapGestureRecognizer];
    [keyWindow removeGestureRecognizer:self.panGestureRecognizer];
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if (self.noteDocument.documentState!=UIDocumentStateNormal ) {
        NSLog(@"couldn't save!");
        return;
    }
    
    NSString *text = aTextView.text;
    NSString *currentText = self.noteDocument.data.noteText;
    if (![currentText isEqualToString:text]) {
        [self.noteDocument setText:text];
        [self.noteEntry setNoteData:self.noteDocument.data];
        
        [self persistChanges];
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

// Gesture handler for when the user touches the options button.
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.optionsButton.frame, location)){
        [self optionsSelected:nil];
    }
}

- (void)handleTapFrom:(UIGestureRecognizer *)recognizer {
    [self.textView resignFirstResponder];
    CGPoint touchPoint = [recognizer locationInView:self.view];
    if (CGRectContainsPoint(self.optionsButton.frame, touchPoint)) {
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
