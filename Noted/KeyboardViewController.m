//
//  KeyboardViewController.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "KeyboardViewController.h"
#import "KeyboardKey.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+HexColor.h"

@interface KeyboardViewController()

@property (nonatomic) CGPoint firstTouch;
@property (nonatomic) CGPoint secondTouch;

@end

@interface KeyboardViewController () {
    int currentPageLocation;
}
@end

@implementation KeyboardViewController

@synthesize backgroundImage;
@synthesize keyImageView;
@synthesize keyDisplay;
@synthesize allKeyboards;
@synthesize activeKeyboardKey;
@synthesize activeKeyboard;
@synthesize keyboardNames;
@synthesize activeKeyboardName;
@synthesize howManyTouches;
@synthesize firstTouch;
@synthesize secondTouch;
@synthesize delegate;
@synthesize pageIndicator;
@synthesize scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //defaults
    shouldCloseKeyboard = NO;
    capitalized = NO;
    returnLine = NO;
    tapped = YES;
    returnKey = [[KeyboardKey alloc] init];
    tapTimer = [[NSTimer alloc] init];
    self.view.backgroundColor = [UIColor clearColor];
    
    NSString *layoutImage = [NSString stringWithFormat:@"keyboard-base.png"];
   	UIImage *image = [UIImage imageNamed:layoutImage];
	self.backgroundImage.image = image;
    
    self.pageIndicator.frame = CGRectMake(0, 162, 90, 54);
    
    self.keyDisplay.frame = CGRectMake(0, 0, 32, 60);
    self.keyDisplay.layer.cornerRadius = 6.0;
    self.keyDisplay.layer.opacity = 0.95;
    self.keyDisplay.backgroundColor = [UIColor blackColor];
    self.keyDisplay.textColor = [UIColor colorWithHexString:@"EEEEEE"];
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    
    //add gestureRecognizers 
 //   [self addAllGestures];
    [self.view setMultipleTouchEnabled:YES];
    [self setupAllKeyboards];
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    [self resetTapTimer];
    [self resetKeyboard];
    self.keyDisplay.hidden = YES;
    
    
}

- (void)viewDidUnload
{
    [self setAllKeyboards:nil];
    [self setActiveKeyboard:nil];
    [self setActiveKeyboardKey:nil];
    [self setBackgroundImage:nil];
    [self setKeyDisplay:nil];
    [self setKeyImageView:nil];
    [self setPageIndicator:nil];
    [self setActiveKeyboardName:nil];
    [self setDelegate:nil];
    [self setPageIndicator:nil];
    
    [self setKeyDisplay:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

//possibly pass in what language of keyboard for localization
-(void)setupAllKeyboards {
    
    NSLog(@"creating the keyboard");
    
    //make the object's arrays/dictionary
    self.keyboardNames = [[NSMutableArray alloc] init];
    self.allKeyboards = [[NSMutableDictionary alloc] init];
    self.activeKeyboardKey = [[KeyboardKey alloc] init];
    self.activeKeyboard = [[NSMutableDictionary alloc] init];
    self.activeKeyboardName = [[NSMutableString alloc] init];
    
    //loads the order of the keyboards from a plist
    NSString *path = [[NSBundle mainBundle] bundlePath];
    
    
    //loads data from plist ***this is temporary and will be sent the actual plist via constants.h
    
    NSString *keyboardFilename = [NSString stringWithFormat:@"EnglishKeyboard.plist"];
    NSString *finalPath = [path stringByAppendingPathComponent:keyboardFilename];
    
    NSDictionary *keyboards = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    int keyboardCount = [keyboards count];
    self.allKeyboards = [[NSMutableDictionary alloc] initWithCapacity:keyboardCount];
    NSEnumerator *keyboardsEnumerator = [keyboards keyEnumerator];
    NSMutableString *aSingleKeyboard;
    while (aSingleKeyboard = [keyboardsEnumerator nextObject])
    {
        NSMutableDictionary *keyboardKeys = [keyboards valueForKey:aSingleKeyboard];
        NSEnumerator *keyboardKeyEnumerator = [keyboardKeys keyEnumerator];
        NSMutableString *aSingleKey;
        
        //get location
        NSString *loc = [keyboardKeys valueForKey:@"location"];
        int location = [loc intValue];
        
        
        //Dictionary that will carry all the keys for this Keyboard
        NSMutableDictionary *keyElements = [[NSMutableDictionary alloc] init];
        
        while (aSingleKey = [keyboardKeyEnumerator nextObject]) 
        {
            if ([aSingleKey isEqualToString:@"location"]) {
                continue;
            }
            NSDictionary *keyInfo = [keyboardKeys valueForKey:aSingleKey];           
            NSString *label = [keyInfo valueForKey:@"label"];            
            NSString *frameString = [keyInfo valueForKey:@"frame"];            
            CGRect frame = CGRectFromString(frameString);            
            KeyboardKey* aKey = [[KeyboardKey alloc] initWithLabel:label frame:frame];
            //adjust any view specs here
            aKey.alpha = 0.4;
            aKey.backgroundColor = [UIColor yellowColor];
            
            [keyElements setObject:aKey forKey:label];
            
        }
        //a single keyboardElement is a keyboard with all the views attached
        NSMutableDictionary *keyboardElements = [[NSMutableDictionary alloc] init];
        [keyboardElements setObject:keyElements forKey:@"keys"];
        
        //now add dictionary to the viewcontroller
        //add an array of all the keyboard names (for pulling images)
        if ([self.keyboardNames count] >= location +1) {
            [self.keyboardNames insertObject:aSingleKeyboard atIndex:location];
            NSLog(@"%@",aSingleKeyboard);
        }else {
            [self.keyboardNames addObject:aSingleKeyboard];
            NSLog(@"%@",aSingleKeyboard);
        }
        
        
        
        for (NSString *name in self.keyboardNames) {
        }
        
        [self.allKeyboards setObject:keyboardElements forKey:aSingleKeyboard];
        
        
        //for loop purposes
        keyElements = nil;
    }
    
    self.pageIndicator.numberOfPages = [self.keyboardNames count];
    self.activeKeyboardName = [self.keyboardNames objectAtIndex:1];
    self.activeKeyboard = [self.allKeyboards objectForKey:self.activeKeyboardName];
    [self changeActiveKeyboardTo:self.activeKeyboard];
    
    //Add buffer page at beginning to fake "wrapping" of keyboards
    int panels = 0;
    if (self.keyboardNames.count > 1) {
        NSString *keyboardName = [self.keyboardNames objectAtIndex:(self.keyboardNames.count - 1)];
        NSString *layoutImage = [NSString stringWithFormat:@"%@.png", keyboardName];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:layoutImage]];
        imageView.frame = CGRectMake(0, 0, 320, 216);
        [self.scrollView addSubview:imageView];
        panels ++;
    }
    //Add regular panels
    for (int i = 0; i < self.keyboardNames.count; i++) {
        NSString *keyboardName = [self.keyboardNames objectAtIndex:i];
        NSString *layoutImage = [NSString stringWithFormat:@"%@.png", keyboardName];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:layoutImage]];
        imageView.frame = CGRectMake(320*panels, 0, 320, 216);
        [self.scrollView addSubview:imageView];
        panels++;
    }
    //Add buffer page at end to fake "wrapping" of keyboards
    if (self.keyboardNames.count > 1) {
        NSString *keyboardName = [self.keyboardNames objectAtIndex:0];
        NSString *layoutImage = [NSString stringWithFormat:@"%@.png", keyboardName];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:layoutImage]];
        imageView.frame = CGRectMake(320*panels, 0, 320, 216);
        [self.scrollView addSubview:imageView];
        panels++;
    }
    self.scrollView.contentSize = CGSizeMake(320*panels, 162);
    CGRect frame = CGRectMake(320*floor((self.keyboardNames.count+1)/2), 0, 320, self.scrollView.frame.size.height);
    [self.scrollView scrollRectToVisible:frame animated:NO];
}



-(void)addAllGestures {
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnKeyboardDetected:)];
    [self.view addGestureRecognizer:panRecognizer];
    
}


#pragma mark - 
#pragma mark Touch Events and Hit Detection

-(void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event {
    NSLog(@"Num touches %d [%d]",[touches allObjects].count,__LINE__);
    CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        
    tapped = YES;
    swipeUp = NO;
    swipeDown = NO;
    swipeLeftTwoFinger = NO;
    swipeRightTwoFinger = NO;
    [self resetTapTimer];
    firstTouch = currentLocation;
    NSLog(@"First touch location = %f, %f", firstTouch.x, firstTouch.y);
	self.activeKeyboardKey = nil;
}

-(void)touchesMoved: (NSSet *)touches withEvent: (UIEvent *)event {
    
	NSSet *allTouches= [event allTouches];
    CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
    CGFloat netXChange = currentLocation.x - firstTouch.x;
    CGFloat netYChange = abs(currentLocation.y - firstTouch.y);
    
    NSLog(@"Net X,Y change = %f, %f", netXChange, netYChange);
    
    if (allTouches.count == 2) {
        //Undo & Redo
        if (netXChange < -80 && !swipeLeftTwoFinger && netYChange < 5) {
            NSLog(@"Two finger swipe left detected");
            [undoTimer invalidate];
            undoTimer = [NSTimer scheduledTimerWithTimeInterval:.75 target:delegate selector:@selector(undoEdit) userInfo:nil  repeats:YES];
            [self.delegate undoEdit];
            swipeLeftTwoFinger = YES;
        } else if (netXChange > 80 &&!swipeRightTwoFinger) {
            NSLog(@"Two finger swipe right detected");
            [undoTimer invalidate];
            undoTimer = [NSTimer scheduledTimerWithTimeInterval:.75 target:delegate selector:@selector(redoEdit) userInfo:nil  repeats:YES];
            [self.delegate redoEdit];
            swipeRightTwoFinger = YES;
        } else if (netXChange >= -40 && netXChange <= 40) {
            [undoTimer invalidate];
        }
        if (netYChange > 5) {
            swipeDownTwoFinger = YES;
            [self fadeKeyboard];
        }
    } else {
        if (netYChange < -5) {
            NSLog(@"vertical up swipe recognized");
            if (!swipeUp) {
                capitalized = YES;
                [self keyHitDetected:firstTouch];
                swipeUp = YES;
            }
        } else if (netYChange > 5) {
            NSLog(@"vertical down swipe recognized");
            if (!swipeDown) {
                returnLine = YES;
                [self keyHitDetected:firstTouch];
                swipeDown = YES;
            }
            
        }
    }
}

-(void) touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event {
	
	// find the element that is being touched, if any.
    
    CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
    if (swipeDownTwoFinger) {
        [self.delegate closeKeyboard];
    } else if (!swipeUp && !swipeDown && !swipeLeftTwoFinger && !swipeRightTwoFinger) {
        [self keyHitDetected:currentLocation];
    }
	
	// reset the selected and prior selected interface elements
    
	self.activeKeyboardKey = nil;
    [undoTimer invalidate];
    
}

-(void)keyHitDetected:(CGPoint)currentLocation {
    
    NSLog(@"current location: x=%f, y=%f", currentLocation.x, currentLocation.y);
	
	// Loop through every key in the given keyboard to find the first one being touched.
	// It is possible that no elements in this section are being touched.
    
	NSDictionary *keyboardKeys = [self.activeKeyboard objectForKey:@"keys"];
	NSEnumerator *enumerator = [keyboardKeys keyEnumerator];
	NSMutableString *aSingleKey;
	
	while ((aSingleKey = [enumerator nextObject])) {
		
		KeyboardKey *theKey = [keyboardKeys objectForKey:aSingleKey];
        
		// There are instances when an interface element is corrupt.  Make sure it has a name before proceeding.
		if (aSingleKey) {		
			// The bread and butter of this routine.  Does the frame of the interface element contain the point we are touching?
			if ( CGRectContainsPoint(theKey.frame, currentLocation) ) {
				
                
                [self keyboardKeySelected:theKey];
            }
        }
    }
}





#pragma mark - 
#pragma mark Action Triggers

// Selected happens when the finger is removed from the screen when the last touch was on a valid interface element
- (void)keyboardKeySelected:(KeyboardKey*)key {
    NSLog(@"TRIGGER keySelected %@", key);
	if (key) {
        if ([key.label isEqualToString:@"indicator"]) {
            [self changePageFromIndicator];
        }
		// This element was selected.  Perform its' action.
		else {
            
            [self performActionForKeyboardKey:key animated:YES];
        }
    }
}


- (void)makeKeyActive:(KeyboardKey*)key {	
	// Set the active interface element to the given element	
	self.activeKeyboardKey = key; 
	
	// Show the visual representation of the interface element if appropriate
    [self.view addSubview:keyDisplay];
	self.keyDisplay.text = key.label;
	
}

- (void)changeActiveKeyboardTo:(NSDictionary*)newActiveKeyboard {
	self.activeKeyboard = newActiveKeyboard;
}

#pragma mark - 
#pragma mark Process Triggers
-(void)hideKeyDisplay {
    self.keyDisplay.hidden = YES;
}

- (KeyboardKey*)performActionForKeyboardKey:(KeyboardKey*)key animated:(BOOL)animated  {
	// Default selected key text to nothing.
	//play annoying sound
    [[UIDevice currentDevice] playInputClick];
    //Is there a delegate listening?
    if ([delegate respondsToSelector:@selector(printKeySelected:)]) {
        // Only process the key press if a key was pressed.
        if (key) {
            if(capitalized){
                //need to handle special case like delete&shift&space (let the Editing/Note VC handle that)
                if([key.label isEqualToString:@"delete"]){
                    [delegate  printKeySelected:key.label];
                    capitalized = NO;
                }else if ([key.label isEqualToString:@"shift"]) {
                    capitalized = YES;
                }else if ([key.label isEqualToString:@" "]) {
                    [delegate printKeySelected:key.label];
                    capitalized = NO;
                }else {
                    NSString *newLabel = [key.label uppercaseString];
                    [delegate  printKeySelected:newLabel];
                    self.keyDisplay.text = newLabel;
                    CGRect frame = key.frame;
                    frame.origin.y = frame.origin.y - 54;
                    self.keyDisplay.frame = frame;
                    self.keyDisplay.hidden = NO;
                    [keyDisplayTimer invalidate];
                    keyDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(hideKeyDisplay) userInfo:nil repeats:NO];
                    capitalized = NO;
                }
                
            }
            else if(returnLine) {
                [delegate printKeySelected:@"return"];
                returnLine = NO;
                capitalized = NO;
            }else if ([key.label isEqualToString:@"delete"] || [key.label isEqualToString:@" "] || [key.label isEqualToString:@"return"]) {
                [delegate printKeySelected:key.label];
            }else if ([key.label isEqualToString:@"shift"]) {
                capitalized = YES;
            }else {
                [delegate printKeySelected:key.label];
                self.keyDisplay.text = key.label;
                CGRect frame = key.frame;
                frame.origin.y = frame.origin.y - 54;
                self.keyDisplay.frame = frame;
                self.keyDisplay.hidden = NO;
                [keyDisplayTimer invalidate];
                keyDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(hideKeyDisplay) userInfo:nil repeats:NO];
            } 
        }
    }
    return key;
}


#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    //Subtract the extra panels
    if (self.keyboardNames.count > 1) {
        page -= 1; 
    }
    self.pageIndicator.currentPage = page;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / (self.keyboardNames.count+2)) / self.scrollView.frame.size.width) + 1;
    if (currentPage==0) {
        //go last but 1 page
        [self.scrollView scrollRectToVisible:CGRectMake(320 * self.keyboardNames.count,0,self.view.frame.size.width,self.view.frame.size.height) animated:NO];
    } else if (currentPage==(self.keyboardNames.count+1)) {
        [self.scrollView scrollRectToVisible:CGRectMake(320,0,320,self.view.frame.size.height) animated:NO];
    }

    self.activeKeyboardName  = [self.keyboardNames objectAtIndex:(self.pageIndicator.currentPage)];
    NSLog(@"Current Page = %i", self.pageIndicator.currentPage);
    [self changeActiveKeyboardTo:[self.allKeyboards objectForKey:self.activeKeyboardName]];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)theScrollView {
    [self scrollViewDidEndDecelerating:theScrollView];
}


#pragma mark - Keyboard Fade
-(void) resetTapTimer {
    self.view.alpha = 1.0;
    [tapTimer invalidate];
    tapped = YES;
    tapTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(noKeysTapped) userInfo:nil  repeats:NO];
    
}

-(void) resetKeyboard {
    self.keyImageView.alpha = 1.0;
}

-(void)noKeysTapped {
//    [delegate closeKeyboard];
    //   tapped = NO;
    //   [self fadeKeyboard];
}

-(void)fadeKeyboard {
    NSTimer *fadeTimer = nil;
    if (!tapped) {
        if(self.view.alpha > .005){
            self.view.alpha = self.view.alpha - 0.01;
            fadeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fadeKeyboard) userInfo:nil repeats:NO];
        }else {
            [delegate closeKeyboard];
        }
    }else{
        //tapped so resetTapTimer
        [fadeTimer invalidate];
        [self resetTapTimer];
    }
}

-(void)fadeKeysOut:(CGPoint)point {
    float panned = point.y;
    NSLog(@"%f",panned);
    self.keyImageView.alpha = 1 - panned/150;
}


- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

- (void)changePageFromIndicator{
    // update the scroll view to the appropriate page
    int currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / (self.keyboardNames.count+2)) / self.scrollView.frame.size.width) + 1;
    if (self.keyboardNames.count > 1) {
        currentPage += 1;
        [self.scrollView scrollRectToVisible:CGRectMake(320 * currentPage,0,320,self.view.frame.size.height) animated:YES];
    }
}

@end
