//
//  DetailViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "OptionsViewController.h"

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
    self.colorSchemes= [[NSMutableArray alloc] initWithObjects:[self colorWithHexString:@"FFFFFF"],[self colorWithHexString:@"F3F6E9"], [self colorWithHexString:@"E9F2F6"],[self colorWithHexString:@"FBF6EA"], [self colorWithHexString:@"333333"], [self colorWithHexString:@"1A9FEB"], nil];
    self.headerColorSchemes = [[NSMutableArray alloc] initWithObjects:[self colorWithHexString:@"AAAAAA"], [self colorWithHexString:@"C1D184"],[self colorWithHexString:@"88ACBB"],[self colorWithHexString:@"DAC361"],[self colorWithHexString:@"CCCCCC"], [self colorWithHexString:@"FFFFFF"], nil];
    
    [self addAllGestures];
    
    
    //register for the notification
    self.noteTextView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReloaded:) name:@"noteModified" object:nil];
    
    // Update the user interface for the detail item.
    self.noteTextView.text = self.note.text;
    self.relativeTimeText.text = [self formatRelativeDate:self.note.fileModificationDate];
    self.absoluteTimeText.text = [self formatDate:self.note.fileModificationDate];
    self.noteTextView.frame = CGRectMake(0,20,320,480);
    
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
    self.absoluteTimeText.backgroundColor = color;
    self.relativeTimeText.backgroundColor = color;
    self.colorDot.backgroundColor = color;
    
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
//    OptionsViewController *optionVC = [OptionsViewController new];
//    [self.navigationController pushViewController:optionVC animated:YES];
}



-(UIColor *) colorWithHexString: (NSString *) hex  
{  
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];  
    
    // String should be 6 or 8 characters  
    if ([cString length] < 6) return [UIColor grayColor];  
    
    // strip 0X if it appears  
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];  
    
    if ([cString length] != 6) return  [UIColor grayColor];  
    
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2;  
    NSString *rString = [cString substringWithRange:range];  
    
    range.location = 2;  
    NSString *gString = [cString substringWithRange:range];  
    
    range.location = 4;  
    NSString *bString = [cString substringWithRange:range];  
    
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  
    
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
} 



- (void)dataReloaded:(NSNotification *)notification {
    
    self.note = notification.object;
    self.noteTextView.text = self.note.text;
    
}

- (void)textViewDidChange:(UITextView *)textView {
    
    NSMutableString *content = [[NSMutableString alloc] initWithFormat:self.noteTextView.text];
    NSRange time = [content rangeOfString:@":time"];
    if (time.location != NSNotFound) {
        [content replaceCharactersInRange:time
                               withString:[self getCurrentTime]];
        self.noteTextView.text = content;
        
    }
    self.note.text = self.noteTextView.text;
    [self.note updateChangeCount:UIDocumentChangeDone];
    
}


-(NSString*)getCurrentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *now = [NSDate date];
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate:now] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:now] intValue];
    
    NSString *am_pm = @"AM"; 
    
    if (hour > 12) {
        am_pm = @"PM";
        hour = hour - 12;
    }
    
    NSString *dateString;
    if (minute < 10) {
        dateString = [[NSString alloc] initWithFormat:@"%i:0%i %@",hour,minute,am_pm];
    }else {
        dateString = [[NSString alloc] initWithFormat:@"%i:%i %@",hour,minute,am_pm];
    }
    return dateString;
}

-(NSString*)formatDate:(NSDate*)dateCreated {
    NSArray *months = [[NSArray alloc] initWithObjects:@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August", @"September",@"October",@"November",@"December", nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
    [dateFormatter setDateFormat:@"yyyy"];
    
    [dateFormatter setDateFormat:@"MM"];
    int monthInt = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    NSString *am_pm = @"AM"; 
    
    if (hour > 12) {
        am_pm = @"PM";
        hour = hour - 12;
    }
    
    NSString *month = [months objectAtIndex:monthInt];
    NSString *dateString;
    if (minute < 10) {
        dateString = [[NSString alloc] initWithFormat:@"%@ %i  %i:0%i %@",month,day,hour,minute,am_pm];
    }else {
        dateString = [[NSString alloc] initWithFormat:@"%@ %i  %i:%i %@",month,day,hour,minute,am_pm];
    }
    
    return dateString;
}

-(NSString*)formatRelativeDate:(NSDate*)dateCreated {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *now = [NSDate date];
    
    [dateFormatter setDateFormat:@"yyyy"];
    int year = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowYear = [[dateFormatter stringFromDate:now] intValue];
    [dateFormatter setDateFormat:@"MM"];
    int month = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowMonth = [[dateFormatter stringFromDate:now] intValue];
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowDay = [[dateFormatter stringFromDate:now] intValue];
    
    
    if (month == 1 || month == 2) {
        month += 12;
        year -= 1;
    }
    if (nowMonth == 1 || nowMonth == 2) {
        month+=12;
        year -= 1;
    }
    
    int totalDays = floorf(365.0*year) + floorf(year/4.0) - floorf(year/100.0) + floorf(year/400.0) + day + floorf((153*month+8)/5);
    
    int totalNowDays = floorf(365.0*nowYear) + floorf(nowYear/4.0) - floorf(nowYear/100.0) + floorf(nowYear/400.0) + nowDay + floorf((153*nowMonth+8)/5);
    
    int daysAgo = totalNowDays - totalDays;
    NSString *dateString = [NSString alloc];
    
    if (daysAgo == 0) {
        dateString = [NSString stringWithFormat:@"Today"];
    }else if (daysAgo == 1) {
        dateString = [NSString stringWithFormat:@"Yesterday"];
    }else {
        dateString = [NSString stringWithFormat:@"%i days ago",daysAgo];
    }
    return dateString;
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
