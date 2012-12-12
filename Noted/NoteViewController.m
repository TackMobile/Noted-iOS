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
    self.scrollView.contentSize = self.view.frame.size;
    self.view.layer.cornerRadius = 6.0;
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [self setScrollView:nil];
    [self setOptionsDot:nil];
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
        [self.optionsDot setHidden:YES];
    } else {
        [self updateUIForCurrentEntry];
        [self.optionsDot setHidden:NO];
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

- (void) setNoteEntry:(NoteEntry *)entry {
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
    self.textView.text = [_noteEntry displayText];
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
    
    self.optionsDot.textColor = self.textView.textColor;
    
    [self setOptionsDotForBGColor];
}

- (void)setOptionsDotForBGColor
{
    UIColor *bgColor = _noteEntry.noteColor ? _noteEntry.noteColor : [UIColor whiteColor];
    self.optionsDot.text = [NoteViewController optionsDotTextForColor:bgColor];
    self.optionsDot.font = [NoteViewController optionsDotFontForColor:bgColor];
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

-(void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    self.scrollView.contentOffset = aScrollView.contentOffset;
}

- (void)textViewDidChange:(UITextView *)aTextView {
//    if ([aTextView.text hasPrefix:@"\n"]) {
//        aTextView.text = [NSString stringWithFormat:@"\n%@", aTextView.text];
//
//    }
    
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
        [self.noteDocument setText:self.textView.text];
    }
}

- (NSString *)removeLeadingNewline:(NSString *)text
{
    if ([text hasPrefix:@"\n"]) {
        text = [text substringFromIndex:1];
    }
    
    return text;
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if (self.noteDocument.documentState!=UIDocumentStateNormal ) {
        NSLog(@"couldn't save!");
        return;
    }
    
    NSString *text = [self removeLeadingNewline:aTextView.text];
    NSString *currentText = self.noteDocument.data.noteText;
    if (![currentText isEqualToString:text]) {
        [self.noteDocument setText:text];
        [self.noteEntry setNoteData:self.noteDocument.data];
        
        [self persistChanges];
    }  
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

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
}

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
