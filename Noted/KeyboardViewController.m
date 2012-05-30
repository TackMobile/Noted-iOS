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

@interface KeyboardViewController ()

@end

@implementation KeyboardViewController

@synthesize backgroundImage;
@synthesize keyImageView;
@synthesize previousKeyImageView;
@synthesize nextKeyImageView;
@synthesize keyDisplay;
@synthesize allKeyboards;
@synthesize activeKeyboardKey;
@synthesize activeKeyboard;
@synthesize keyboardNames;
@synthesize activeKeyboardName;
@synthesize howManyTouches;
@synthesize firstTouch;
@synthesize delegate;
@synthesize pageIndicator;
@synthesize nextKeyboard;
@synthesize previousKeyboard;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    self.keyDisplay.textColor = [self colorWithHexString:@"EEEEEE"];
    
    
    //add gestureRecognizers 
    [self addAllGestures];
    
    [self setupAllKeyboards];
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    [self resetTapTimer];
    [self resetKeyboard];
    self.keyDisplay.hidden = YES;
    
    
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
    self.previousKeyboard = [NSMutableString new];
    self.nextKeyboard = [NSMutableString new];
    
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
}



-(void)addAllGestures {
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnKeyboardDetected:)];
    [self.view addGestureRecognizer:panRecognizer];
    
}



-(void)verticalPan:(UIPanGestureRecognizer*)pan {
    
    CGPoint point = [pan translationInView:self.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        //   firstTouch = [pan translationInView:self.view];
        if (howManyTouches == 2) {
            shouldCloseKeyboard = YES;
        }
        
    }
    if (pan.state == UIGestureRecognizerStateChanged && pan.numberOfTouches == 2) {
        if (point.y > 0 && fabs(2* point.x) < fabs(point.y)) {
            NSLog(@"recognizing close keyboard pan");
            [self.delegate panKeyboard:point];
            [self fadeKeysOut:point];
        }
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [pan velocityInView:self.view];
        
        if (point.y < 10 && fabs(4*point.x)<fabs(point.y)) {
            NSLog(@"vertical up pan recognized");
            capitalized = YES;
            [self keyHitDetected:firstTouch];
        }
        if ((point.y > 100 && fabs(4*point.x)<fabs(point.y)) || velocity.y > 500) {
            NSLog(@"vertical down pan recognized");
            if (shouldCloseKeyboard)
            {
                [self.delegate closeKeyboard];
            }else {
                returnLine =YES;
                [self keyHitDetected:firstTouch];
            }
        }else {
            [self.delegate snapKeyboardBack];
            [self resetKeyboard];
        }
        shouldCloseKeyboard = NO;
    }
}

-(void)undoPan:(UIPanGestureRecognizer*)pan {
    CGPoint point = [pan translationInView:self.view];
    CGPoint velocity = [pan velocityInView:self.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        firstTouch = [pan locationInView:self.view];
        if (howManyTouches == 2) {
            undo = YES;
        }
        
    }
    
    if (pan.state == UIGestureRecognizerStateChanged) {
        if (undo) {
            if (point.x < -40) {
                [undoTimer invalidate];
                undoTimer = [NSTimer scheduledTimerWithTimeInterval:.75 target:delegate selector:@selector(undoEdit) userInfo:nil  repeats:YES];
            }else if (point.x > 40) {
                [undoTimer invalidate];
                undoTimer = [NSTimer scheduledTimerWithTimeInterval:.75 target:delegate selector:@selector(redoEdit) userInfo:nil  repeats:YES];
            }else {
                [undoTimer invalidate];
            }
        }
    }
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        [undoTimer invalidate];
        if (undo) {
            
            if (point.x < 10 && fabs(4*point.x)>fabs(point.y) && velocity.x < -200) {
                NSLog(@"UNDO");
                [delegate undoEdit];
            }
            if (point.x > 10 && fabs(4*point.x)>fabs(point.y)) {
                NSLog(@"REDO");
                [delegate redoEdit];
            }
            undo = NO;
            
        }
    }
}

//Swipe Detection ***Break this up...way to big method*****
-(void)panOnKeyboardDetected:(UIPanGestureRecognizer*)pan {
    if (pan.state == UIGestureRecognizerStateBegan ) {
        howManyTouches = pan.numberOfTouches;
        self.nextKeyImageView.frame = CGRectMake(320, 0, 320, 216);
        self.previousKeyImageView.frame = CGRectMake(-320, 0, 320, 216);
        self.keyImageView.frame = CGRectMake(0,0,320,216);
    }
    //vertical pan check
    [self verticalPan:pan];
    [self undoPan:pan];
    
    if (howManyTouches == 1) {
        
        //if there is a keyboard to the left (not the first keyboard)
        int k = [self.keyboardNames indexOfObject:self.activeKeyboardName];
        NSLog(@"%i",k);
        int count  = [self.keyboardNames count];
        CGPoint point = [pan translationInView:self.view];
        
        if (pan.state == UIGestureRecognizerStateBegan ) {
            howManyTouches = pan.numberOfTouches;
        }
        
        //if we are at the beginning we circle
        if (k==0) {
            self.nextKeyboard = [self.keyboardNames objectAtIndex:(k+1)];
            self.previousKeyboard = [self.keyboardNames objectAtIndex:(count-1)];
            
            NSString *layoutImage = [NSString stringWithFormat:@"%@.png", nextKeyboard];
            NSString *previousLayoutImage = [NSString stringWithFormat:@"%@.png", previousKeyboard];
            
            
            UIImage *nextImage = [UIImage imageNamed:layoutImage];
            UIImage *previousImage = [UIImage imageNamed:previousLayoutImage];
            
            self.nextKeyImageView.image = nextImage;
            self.previousKeyImageView.image = previousImage;
        }else  if ((k+1) == count) {
            //at the end
            self.nextKeyboard = [self.keyboardNames objectAtIndex:0];
            self.previousKeyboard = [self.keyboardNames objectAtIndex:(k-1)];
            
            NSString *layoutImage = [NSString stringWithFormat:@"%@.png", nextKeyboard];
            NSString *previousLayoutImage = [NSString stringWithFormat:@"%@.png", previousKeyboard];
            
            
            UIImage *nextImage = [UIImage imageNamed:layoutImage];
            UIImage *previousImage = [UIImage imageNamed:previousLayoutImage];
            
            self.nextKeyImageView.image = nextImage;
            self.previousKeyImageView.image = previousImage;
            
        }else {
            self.nextKeyboard = [self.keyboardNames objectAtIndex:(k+1)];
            self.previousKeyboard = [self.keyboardNames objectAtIndex:(k-1)];
            
            NSString *layoutImage = [NSString stringWithFormat:@"%@.png", nextKeyboard];
            NSString *previousLayoutImage = [NSString stringWithFormat:@"%@.png", previousKeyboard];
            
            
            UIImage *nextImage = [UIImage imageNamed:layoutImage];
            UIImage *previousImage = [UIImage imageNamed:previousLayoutImage];
            
            self.nextKeyImageView.image = nextImage;
            self.previousKeyImageView.image = previousImage;
        }
        
        
        
        if (pan.state == UIGestureRecognizerStateChanged) {
            //panning from right to left
            if (point.x <0 && fabs(2* point.x) > fabs(point.y)) {
                NSLog(@"recognizing right to left pan of keyboard");
                
                
                CGRect frame = self.nextKeyImageView.frame;
                frame.origin.x =  320 + point.x;
                if (frame.origin.x > 320) frame.origin.x = 320;
                self.nextKeyImageView.frame = frame;
                
                
                CGRect otherFrame = self.keyImageView.frame;
                otherFrame.origin.x = 0 + point.x;
                if (otherFrame.origin.x <-320) {
                    otherFrame.origin.x = -320;
                }
                self.keyImageView.frame = otherFrame;
            }
            //panning from left to right
            if (point.x > 0 && fabs(2* point.x) > fabs(point.y)) {
                NSLog(@"recognizing left to right pan of keyboard");
                
                
                CGRect frame = self.previousKeyImageView.frame;
                frame.origin.x =  -320 + point.x;
                if (frame.origin.x < -320) frame.origin.x = -320;
                self.previousKeyImageView.frame = frame;
                
                
                CGRect otherFrame = self.keyImageView.frame;
                otherFrame.origin.x = 0 + point.x;
                if (otherFrame.origin.x <-320) {
                    otherFrame.origin.x = -320;
                } else if (otherFrame.origin.x > 320) {
                    otherFrame.origin.x = 320;
                }
                self.keyImageView.frame = otherFrame;
            }
        }
        
        if (pan.state == UIGestureRecognizerStateEnded) {
            NSLog(@"pan ended");
            CGPoint velocity = [pan velocityInView:self.view];
            
            if (self.keyImageView.frame.origin.x >= 160 || velocity.x > 250){
                //panned previous keyboard
                [self animateLayer:self.keyImageView toPoint:320];
                [self animateLayer:self.previousKeyImageView toPoint:0];
                self.activeKeyboardName = self.previousKeyboard;
                NSLog(@"%@",previousKeyboard);
                //self.keyImageView = self.previousKeyImageView;
                
            } else if (self.keyImageView.frame.origin.x <= -160 || velocity.x < -250) {
                
                //panned to next keyboard
                [self animateLayer:self.keyImageView toPoint:-320];
                [self animateLayer:self.nextKeyImageView toPoint:0];
                self.activeKeyboardName = self.nextKeyboard;
                NSLog(@"%@",nextKeyboard);
                // self.keyImageView = self.nextKeyImageView;
                
            } else {
                [self animateLayer:self.keyImageView toPoint:0];
                [self animateLayer:self.previousKeyImageView toPoint:-320];
                [self animateLayer:self.nextKeyImageView toPoint:320];
            }
            NSLog(@"%@",self.activeKeyboardName);
            [self changeActiveKeyboardTo:[self.allKeyboards objectForKey:self.activeKeyboardName]]; 
        }
    }
}


-(void) animateLayer:(UIView*)layer toPoint:(CGFloat)x
{
    [UIView animateWithDuration:0.15 
                          delay:0 
                        options:UIViewAnimationCurveEaseOut 
                     animations:^{
                         CGRect frame = layer.frame;
                         frame.origin.x = x;
                         layer.frame = frame;
                     }
                     completion:^(BOOL finished){
                         
                     }];
}


#pragma mark - 
#pragma mark Touch Events and Hit Detection



-(void)touchesBegan: (NSSet *)touches 
          withEvent: (UIEvent *)event {
    
    tapped = YES;
    [self resetTapTimer];
    
	self.activeKeyboardKey = nil;
    
}

-(void)touchesMoved: (NSSet *)touches 
          withEvent: (UIEvent *)event {
	
    
}

-(void) touchesEnded: (NSSet *)touches 
           withEvent: (UIEvent *)event {
	
	// find the element that is being touched, if any.
    CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
    
    [self keyHitDetected:currentLocation];
	
	// reset the selected and prior selected interface elements
	self.activeKeyboardKey = nil;
    
    
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

-(void)cycleKeyboards {
    
    int k = [self.keyboardNames indexOfObject:self.activeKeyboardName];
    int count  = [self.keyboardNames count];
    
    //make sure we aren't at the end or go to begininning
    if ((k+1) < count) {
        
        self.activeKeyboardName  = [self.keyboardNames objectAtIndex:(k+1)]; 
        [self changeActiveKeyboardTo:[self.allKeyboards objectForKey:self.activeKeyboardName]];
    }else {
        self.activeKeyboardName  = [self.keyboardNames objectAtIndex:(0)]; 
        [self changeActiveKeyboardTo:[self.allKeyboards objectForKey:self.activeKeyboardName]];
    }
    
}


// Selected happens when the finger is removed from the screen when the last touch was on a valid interface element
- (void)keyboardKeySelected:(KeyboardKey*)key {
    NSLog(@"TRIGGER keySelected %@", key);
	if (key) {
        if ([key.label isEqualToString:@"indicator"]) {
            [self cycleKeyboards];
        }
		// This element was selected.  Perform its' action.
		else {
            
            [self performActionForKeyboardKey:key animated:YES];
        }
    }
}



#pragma mark - 
#pragma mark Helper Methods
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

- (void)makeKeyActive:(KeyboardKey*)key {
    //	NSLog(@"-makeElementActive %@", element);
	
	// Set the active interface element to the given element	
	self.activeKeyboardKey = key; 
	
	// Show the visual representation of the interface element if appropriate
    [self.view addSubview:keyDisplay];
	self.keyDisplay.text = key.label;
	
}

- (void)changeActiveKeyboardTo:(NSDictionary*)newActiveKeyboard {
    
    
	self.activeKeyboard = newActiveKeyboard;
    
    [self refreshBackgroundImage];
    
}

- (void)refreshBackgroundImage {
	NSString *layoutImage = [NSString stringWithFormat:@"%@.png", self.activeKeyboardName];
   	UIImage *image = [UIImage imageNamed:layoutImage];
    
	self.keyImageView.image = image;
    self.keyImageView.frame = CGRectMake(0, 0, 320, 216);
    //  self.nextKeyImageView.frame = CGRectMake(320, 0, 320, 216);
    //   self.previousKeyImageView.frame = CGRectMake(-320, 0, 320, 216);
    
    self.pageIndicator.currentPage = [self.keyboardNames indexOfObject:self.activeKeyboardName];
    
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


#pragma mark - 
#pragma mark Keyboard Fade
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
    [delegate closeKeyboard];
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



- (void)viewDidUnload
{
    [self setAllKeyboards:nil];
    [self setActiveKeyboard:nil];
    [self setActiveKeyboardKey:nil];
    [self setBackgroundImage:nil];
    [self setKeyDisplay:nil];
    [self setKeyImageView:nil];
    [self setNextKeyImageView:nil];
    [self setPageIndicator:nil];
    [self setPreviousKeyImageView:nil];
    [self setActiveKeyboardName:nil];
    [self setDelegate:nil];
    [self setPageIndicator:nil];
    
    [self setKeyDisplay:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



@end
