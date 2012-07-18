//
//  DetailViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "OptionsViewController.h"
#import "Utilities.h"
#import "UIColor+HexColor.h"

@interface DetailViewController ()
-(void)configureView;
@end

@implementation DetailViewController
@synthesize mainView;
@synthesize relativeTimeText;
@synthesize absoluteTimeText;
@synthesize colorDotView;
@synthesize colorDot;
@synthesize backgroundImage;


@synthesize noteTextView,note = _note,delegate,colorSchemes,headerColorSchemes;

#pragma mark - Managing the detail item

-(void)setNote:(NoteDocument *)newNote
{
    if (_note != newNote) {
        _note = newNote;
        
        [self configureView];
    }
}

- (void)configureView
{
    //defaults
    
    self.relativeTimeText.frame = CGRectMake(0, -5, 100, 25);
    self.absoluteTimeText.frame = CGRectMake(103, -5, 200, 25);
    self.colorDotView.backgroundColor = [UIColor clearColor];
    self.colorDot.text = @"\u25CB";
    
    self.colorDotView.frame = CGRectMake(280, -5, 40, 45);
    self.colorDot.frame = CGRectMake(15, 0, 25, 25);
    self.colorDot.font = [UIFont systemFontOfSize:10];
    
    //colorSchemes: white,lime,sky,kernal,shadow,tack
    self.colorSchemes= [[NSMutableArray alloc] initWithObjects:[UIColor colorWithHexString:@"FFFFFF"],[UIColor colorWithHexString:@"F3F6E9"], [UIColor colorWithHexString:@"E9F2F6"],[UIColor colorWithHexString:@"FBF6EA"], [UIColor colorWithHexString:@"333333"], [UIColor colorWithHexString:@"1A9FEB"], nil];
    self.headerColorSchemes = [[NSMutableArray alloc] initWithObjects:[UIColor colorWithHexString:@"AAAAAA"], [UIColor colorWithHexString:@"C1D184"],[UIColor colorWithHexString:@"88ACBB"],[UIColor colorWithHexString:@"DAC361"],[UIColor colorWithHexString:@"CCCCCC"], [UIColor colorWithHexString:@"FFFFFF"], nil];
    
    [self addAllGestures];
    
    
    //register for the notification
    self.noteTextView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReloaded:) name:@"noteModified" object:nil];
    
    // Update the user interface for the detail item.
    self.noteTextView.text = self.note.text;
    self.relativeTimeText.text = [Utilities formatRelativeDate:self.note.fileModificationDate];
    self.absoluteTimeText.text = [Utilities formatDate:self.note.fileModificationDate];
    self.noteTextView.frame = CGRectMake(0,10,320,480);
    
    [self setInitialColor];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

					

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.view.layer.shadowOffset = CGSizeMake(2,2 );
        self.view.layer.shadowOpacity = .70;
        self.mainView.layer.bounds = CGRectMake(0, 0, 320, 480);
        self.mainView.layer.cornerRadius = 6.5;
        self.mainView.layer.masksToBounds = YES;
        self.mainView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}


- (void)viewWillAppear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentStateChanged:)
                                                 name:UIDocumentStateChangedNotification 
                                               object:self.note];
    
   // [self configureView];
    
}


- (void)documentStateChanged:(NSNotification *)notification {
    
    [self configureView];
    
}



-(void)setInitialColor {
    if (self.note.color) {
        int i = [self.colorSchemes count];
        int currentColorIndex = [self.colorSchemes indexOfObject:self.note.color];
        int next = currentColorIndex +1;
        if ((next+1) >= i) {
            [self setColors:self.note.color textColor:[UIColor whiteColor]];
        }else if (currentColorIndex == 0){
            [self setColors:self.note.color textColor:nil];
            
        }else{
            [self setColors:self.note.color textColor:nil];
        }
    } else {
        [self setColors:[self.colorSchemes objectAtIndex:0] textColor:nil];
        
    }
}

-(void)setColors:(UIColor*)color textColor:(UIColor*)textColor{
    if (textColor) {
        self.noteTextView.textColor = textColor;
    }else {
        self.noteTextView.textColor = [UIColor blackColor];
    }
    self.note.color = color;
    self.backgroundImage.backgroundColor = color;
    self.absoluteTimeText.backgroundColor = [UIColor clearColor];
    self.relativeTimeText.backgroundColor = [UIColor clearColor];
    self.colorDot.backgroundColor = [UIColor clearColor];
    self.absoluteTimeText.textColor = [self.headerColorSchemes objectAtIndex:[self.colorSchemes indexOfObject:color]];
    self.relativeTimeText.textColor = self.absoluteTimeText.textColor;
    self.colorDot.textColor = self.absoluteTimeText.textColor;
}

-(void)addAllGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openOptions)];
    tap.numberOfTapsRequired = 1;
    [self.colorDotView addGestureRecognizer:tap];
}

-(void)openOptions {
    NSLog(@"Options Dot tap seen");
    [delegate openOptions];
}



- (void)dataReloaded:(NSNotification *)notification {
    
    self.note = notification.object;
    self.noteTextView.text = self.note.text;
    
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    
    NSMutableString *content = [[NSMutableString alloc] initWithFormat:self.noteTextView.text];
    NSRange time = [content rangeOfString:@":time"];
    if (time.location != NSNotFound) {
        [content replaceCharactersInRange:time
                               withString:[Utilities getCurrentTime]];
        self.noteTextView.text = content;
        
    }
    self.note.text = self.noteTextView.text;
    [self.note updateChangeCount:UIDocumentChangeDone];
    
}

#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll: (UIScrollView*)scrollView
{
    float scrollOffset = scrollView.contentOffset.y;
    
    if (scrollOffset <= 5 && !self.noteTextView.isFirstResponder)
    {
        [UIView animateWithDuration:0.15 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut 
                         animations:^{
                             self.relativeTimeText.frame = CGRectMake(0, -5, 100, 25);
                             self.absoluteTimeText.frame = CGRectMake(103, -5, 200, 25); 
                             self.noteTextView.frame = CGRectMake(0,10,320,480);
                         }
                         completion:^(BOOL finished){
                             
                         }];
    }
    else if (scrollOffset > 5 && !self.noteTextView.isFirstResponder)
    {
        // then we are not at the beginning
        [UIView animateWithDuration:0.15 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut 
                         animations:^{
                             self.relativeTimeText.frame = CGRectMake(0, -25, 100, 25);
                             self.absoluteTimeText.frame = CGRectMake(103, -25, 200, 25); 
                             self.noteTextView.frame = CGRectMake(0,0,320,480);
                         }
                         completion:^(BOOL finished){
                             
                         }];
    } else {
        [UIView animateWithDuration:0.15 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut 
                         animations:^{
                             self.relativeTimeText.frame = CGRectMake(0, -25, 100, 25);
                             self.absoluteTimeText.frame = CGRectMake(103, -25, 200, 25); 
                             self.noteTextView.frame = CGRectMake(0,0,320,264);
                         }
                         completion:^(BOOL finished){
                             
                         }];
    }
}




-(void)viewWillDisappear:(BOOL)animated {
    //save and close the note
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setRelativeTimeText:nil];
    [self setAbsoluteTimeText:nil];
    [self setBackgroundImage:nil];
    [self setNote:nil];
    [self setNoteTextView:nil];
    [self setDelegate:nil];
    [self setColorDot:nil];
    [self setColorDotView:nil];
    [self setMainView:nil];
    [super viewDidUnload];
    
    
}






@end
