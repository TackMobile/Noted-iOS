//
//  NoteStackViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteStackViewController.h"
#import "ApplicationModel.h"
#import "NoteViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteEntry.h"
#import "NoteDocument.h"
#import "UIImage+Crop.h"
#import "UIView+position.h"

typedef enum {
    kGestureFinished,
    kShouldExit,
    kShouldDelete,
    kShouldCreateNew,
    kStackingPinch,
    kCycle
} NoteStackGestureState;

static const int NEXT_DIRECTION = 0;
static const int PREVIOUS_DIRECTION = 1;
static const float DURATION = 0.3;
static const float FLIP_VELOCITY_THRESHOLD = 500;
static const float kCornerRadius = 6.0;
static const float kTotalHeight = 414.0;
static const float kSectionZeroHeight = 44.0;

@interface NoteStackViewController () {
    
    int numberOfTouchesInCurrentPanGesture;
    BOOL optionsShowing;
    
    NSMutableArray *deletingViews;
    
    NSInteger _currentNoteIndex;
    float adjustedScale;
	float _currentNoteOffsetLocation;
    UIView *_currentNote;
    UIImageView *_shadowView;
    UIImageView *_shadowViewTop;
    
    NSMutableArray *stackingViews;
    
    BOOL shouldMakeNewNote;
    BOOL shouldDeleteNote;
    BOOL shouldExitStack;
    BOOL pinchComplete;
    BOOL _keyboardShowing;
    
    CGRect centerNoteFrame;
    
    NoteStackGestureState _currentGestureState;
    
}

- (void) presentNotes;

@end

@implementation NoteStackViewController

@synthesize dismissBlock;
@synthesize currentNoteViewController;
@synthesize nextNoteViewController;
@synthesize panGestureRecognizer;
@synthesize keyboardViewController;
@synthesize optionsViewController;
@synthesize overView;
@synthesize nextNoteEntry;
@synthesize previousNoteEntry;
@synthesize previousNoteDocument;
@synthesize nextNoteDocument;

- (id)initWithDismissalBlock:(DismissalBlock)dismiss
{
    self = [super initWithNibName:@"NoteStackViewController" bundle:nil];
    if (self){
        self.dismissBlock = dismiss;
        shouldMakeNewNote = shouldDeleteNote = shouldExitStack = NO;
        centerNoteFrame = CGRectZero;
        
        _keyboardShowing = NO;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = kCornerRadius;
    
    [self configureKeyboard];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"keyboardSettingChanged" object:nil queue:nil usingBlock:^(NSNotification *note){
        [self configureKeyboard];
    }];
    

    
    self.currentNoteViewController = [[NoteViewController alloc] init];
    self.currentNoteViewController.delegate = self;
    [self.view addSubview:self.currentNoteViewController.view];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultKeyboard"]) {
        self.currentNoteViewController.textView.inputView = self.keyboardViewController.view;
    }
    
    self.nextNoteViewController = [[NoteViewController alloc] init];
    [self.view insertSubview:self.nextNoteViewController.view belowSubview:self.currentNoteViewController.view];
    
#warning TODO: optimization: lazy instantiation of OptionsViewController
    self.optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
    self.optionsViewController.delegate = self;
    self.optionsViewController.view.frame = CGRectMake(0, 0, 320, 480);
    self.optionsViewController.view.hidden = YES;
    [self.view insertSubview:self.optionsViewController.view belowSubview:self.currentNoteViewController.view];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinch];
    
    _shadowViewTop = [self shadowView];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];

    self.currentNoteViewController.note = [model noteDocumentAtIndex:model.selectedNoteIndex];
    
    
}

- (void)configureKeyboard
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultKeyboard"]) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
        
        self.keyboardViewController = [[KeyboardViewController alloc] initWithNibName:@"KeyboardViewController" bundle:nil];
        self.keyboardViewController.delegate = self;
        //Register for notifications so the keyboard load will push any text into view
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(shiftViewUpForKeyboard:)
                                                     name: UIKeyboardWillShowNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(shiftViewDownAfterKeyboard:)
                                                     name: UIKeyboardWillHideNotification
                                                   object: nil];
    } else {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:self.currentNoteViewController queue:nil usingBlock:^(NSNotification *note){
            _keyboardShowing = YES;
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidHideNotification object:self.currentNoteViewController queue:nil usingBlock:^(NSNotification *note){
            _keyboardShowing = NO;
        }];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self presentNotes];
    
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentNoteViewController = nil;
    self.nextNoteViewController = nil;
    self.optionsViewController = nil;
    self.keyboardViewController = nil;
    self.overView = nil;
    self.nextNoteEntry = nil;
    self.previousNoteEntry = nil;
    [super viewDidUnload];
}

- (void)presentNotes {
    
    //NSLog(@"Current note %@",self.currentNoteViewController.note.text);
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSUInteger currentIndex = model.selectedNoteIndex;
    self.previousNoteEntry = [model previousNoteInStackFromIndex:currentIndex];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:currentIndex];
    
    self.nextNoteDocument = [model nextNoteDocInStackFromIndex:currentIndex];
    self.previousNoteDocument = [model previousNoteDocInStackFromIndex:currentIndex];
    
    [self makeNoteViewStackImages];
  
}

#pragma mark Pinch gesture to collapse notes stack

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    //if ([gesture numberOfTouches] != 2 && _currentGestureState == kGestureFinished)
       // return;
    
    CGFloat scale = gesture.scale;
    adjustedScale = [self adjustedScaleForPinch:scale];
    
    //CGFloat velocity = gesture.velocity;
    //[self logPinch:velocity scale:scale];

   // Get the pinch points.

    /*
     CGPoint p1 = [gesture locationOfTouch:0 inView:self.view];
     CGPoint p2 = [gesture locationOfTouch:1 inView:self.view];
     
     // Compute the new spread distance.
     CGFloat xd = p1.x - p2.x;
     CGFloat yd = p1.y - p2.y;
     CGFloat distance = sqrt(xd*xd + yd*yd);
     
     */
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self setGestureState:kStackingPinch];
        [self.view.layer setCornerRadius:kCornerRadius];
        [self.view setClipsToBounds:YES];
        [self animateCurrentNoteWithScale:scale];
        [self.currentNoteViewController setWithNoDataTemp:YES];
        
        if (stackingViews.count>0) {
            [self arrangeSubNotes];
            [self animateStackedNotesForScale:scale];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        [self animateCurrentNoteWithScale:scale];
        
        if (stackingViews.count>0) {
            [self animateStackedNotesForScale:scale];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        
        if (pinchComplete) {
            self.dismissBlock(_currentNoteIndex);
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            if (stackingViews.count>0) {
                int i = 0;
                for (NSDictionary *noteDict in stackingViews) {
                    [self resetStackedNoteViewAtIndex:i];
                    i++;
                }
            } else {
                NSLog(@"not animating out %d",__LINE__);
            }
            
            if (_currentNote) {
                [self resetCurrentNoteView];
            } else {
                NSLog(@"not animating out %d",__LINE__);
            }

        }
        
                
        [self setGestureState:kGestureFinished];
    }
}

// get a multiplier to speed up scaling
// to account for (kCellHeight + kMinimumDistanceBetweenTouches)
// otherwise we never get near enough to 'zero' scale

- (double)adjustedScaleForPinch:(CGFloat)scale
{
    float multiplier = (1.0-scale) * (kTotalHeight/(kTotalHeight-(kCellHeight+kMinimumDistanceBetweenTouches+kSectionZeroHeight)));
    float newScale = scale-multiplier;
    
    return newScale;
}
 

#pragma mark Stacked notes animations

- (void)animateStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < stackingViews.count; i ++) {
        [self animateStackedNoteAtIndex:i withScale:scale];
    }
}

- (float)sectionZeroOffset
{
    float offset = (1.0-adjustedScale)*kSectionZeroHeight;
    if (offset >= kSectionZeroHeight) {
        offset = kSectionZeroHeight;
    }
    
    return offset;
}

- (void)animateStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    NSDictionary *noteDict = [stackingViews objectAtIndex:index];
    
    int stackingIndex = [[noteDict objectForKey:@"index"] integerValue];
    UIView *note = [noteDict objectForKey:@"noteView"];
    UIView *noteShadow = [noteDict objectForKey:@"shadow"];
    
    float offset = [self indexOffsetForStackedNoteAtIndex:stackingIndex];
    float newY = [self yOriginForStackedNoteForOffset:offset];
    
    float newHeight = 480.0;
    if (index < stackingViews.count-1) {
        newHeight = [self newHeightForScale:scale andDestinationHeight:kCellHeight];
    }
    
    CGRect newFrame = CGRectMake(0.0, floorf(newY), 320.0, newHeight);
    
    CGRect shadowFrame = noteShadow.frame;
    noteShadow.frame = CGRectMake(0.0, CGRectGetMinY(newFrame)-shadowFrame.size.height, shadowFrame.size.width, shadowFrame.size.height);
        
    [note setFrame:newFrame];
}

- (void)animateCurrentNoteWithScale:(CGFloat)scale
{
    //BOOL noteIsFirst = _currentNoteOffsetLocation == 0.0 ? YES : NO;
            
    float newHeight = [self newHeightForScale:scale andDestinationHeight:kCellHeight];
    float sectionZeroOffset = [self sectionZeroOffset];
    float newY = sectionZeroOffset + ((_currentNoteIndex*kSectionZeroHeight)*(1.0-adjustedScale));
    
    float brakeLine = kSectionZeroHeight + (_currentNoteIndex*kCellHeight);
    if (newY >= brakeLine) {
        pinchComplete = YES;
        newY = brakeLine;
        _currentNote.layer.cornerRadius = scale*kCornerRadius;
    } else if (newY <= 0) {
        newY = 0.0;
    }
    
    centerNoteFrame = CGRectMake(0.0, floorf(newY), 320.0, newHeight);
    //if (!noteIsFirst) {
    CGRect shadowFrame = _shadowViewTop.frame;
    _shadowViewTop.frame = CGRectMake(0.0, CGRectGetMinY(centerNoteFrame)-shadowFrame.size.height, shadowFrame.size.width, shadowFrame.size.height);
    //}
    
    [_currentNote setFrame:centerNoteFrame];
}

#pragma mark Stacked note views setup

static const float kCellHeight = 66.0;
static const float kPinchThreshold = 0.41;
static const float kMinimumDistanceBetweenTouches = 20.0;

- (void)makeNoteViewStackImages
{
    if (stackingViews) {
        [stackingViews removeAllObjects];
        _currentNote = nil;
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    _currentNoteIndex = [[model currentNoteEntries] indexOfObject:self.currentNoteViewController.note];
	
    NSRange range = [self stackedNotesRange];
    NSLog(@"Stack notes from %d to %d",range.location,range.length);
    
	_currentNoteOffsetLocation = (float)_currentNoteIndex/range.length;
    
    [self makeCurrentNote];
    
    // make all the snapshots that aren't on top
    stackingViews = [[NSMutableArray alloc] initWithCapacity:range.length];
    int i = 0;
    for (int j = range.location; j < range.length; j++) {
        
        if (model.currentNoteEntries.count > 30) {
            NSLog(@"wtf?!");
        }
        NoteDocument *doc = [[model currentNoteEntries] objectAtIndex:j];
        
        if (j == _currentNoteIndex) {
            // skip the current doc
            i++;
            continue;
        }
        
        // get image from current view
        UIImage *image = [self imageForDocument:doc];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        
        UIView *noteView = [self makeNoteView];
        [noteView addSubview:imageView];
        
        UIImageView *shadow = [[UIImageView alloc] initWithImage:_shadowViewTop.image];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:noteView,@"noteView",shadow,@"shadow",[NSNumber numberWithInt:i],@"index", nil];
        
        [stackingViews addObject:dict];
        i++;
    }
   
}

- (NSRange)stackedNotesRange
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSMutableOrderedSet *allDocuments = [model currentNoteEntries];
    
    int count = allDocuments.count;
    int displayableCellCount = (int)floorf(self.view.bounds.size.height/kCellHeight);
    displayableCellCount = count < displayableCellCount ? count : displayableCellCount;
	int spread = floorf(displayableCellCount/2);
    
    int beginRange = (_currentNoteIndex - spread)+displayableCellCount > displayableCellCount ? 0 : _currentNoteIndex - spread;
    beginRange = beginRange < 0 ? 0 : beginRange;
    
    int endRange = (beginRange + displayableCellCount) > count ? count : (beginRange + displayableCellCount);
    
    _currentNoteOffsetLocation = (float)_currentNoteIndex/(displayableCellCount);
    NSLog(@"_currentNoteOffsetLocation set to: %f",_currentNoteOffsetLocation);
    
    return NSMakeRange(beginRange, endRange);
}

- (void)makeCurrentNote
{
    _currentNote = nil;
    NoteDocument *currentDoc = self.currentNoteViewController.note;
    
    // get image from current view
    UIImage *image = [self imageForDocument:currentDoc];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    //imageView.layer.cornerRadius = kCornerRadius;
    
    _currentNote = [self makeNoteView];
    [_currentNote addSubview:imageView];
    
}

- (void)arrangeSubNotes
{
    __block UIView *previousView = nil;
    ApplicationModel *model = [ApplicationModel sharedInstance];
    int currentNoteIndex = model.selectedNoteIndex;
    if (_currentNoteIndex==0) {
        [self.view addSubview:_currentNote];
        [self.view addSubview:_shadowViewTop];
    }
    for (NSDictionary *dict in stackingViews) {
        
        UIView *noteView = [dict objectForKey:@"noteView"];
        //noteView.alpha = 0.5;
        UIImageView *shadow = (UIImageView *)[dict objectForKey:@"shadow"];

        int stackingIndex = [[dict objectForKey:@"index"] integerValue];
        // 1st doc, just add it
        if (!previousView) {
            [self.view addSubview:noteView];
        } else if (stackingIndex < currentNoteIndex) {
            [self.view insertSubview:noteView belowSubview:_currentNote];
        } else if (stackingIndex > currentNoteIndex) {
            [self.view insertSubview:noteView aboveSubview:previousView];
        }
        
        if (stackingIndex==_currentNoteIndex-1) {
            [self.view insertSubview:_currentNote aboveSubview:noteView];
            [self.view insertSubview:_shadowViewTop aboveSubview:_currentNote];
        }
        [self.view addSubview:shadow];
        
        previousView = noteView;
    }
}

- (UIImage *) flipImageVertically:(UIImage *)originalImage
{
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:originalImage];
    
    UIGraphicsBeginImageContext(tempImageView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, tempImageView.frame.size.height);
    CGContextConcatCTM(context, flipVertical);
    
    [tempImageView.layer renderInContext:context];
    
    UIImage *flippedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return flippedImage;
}

- (void)debugView:(UIView *)view
{
    // debugging
    view.alpha = 1.0;
    view.layer.borderColor = [UIColor redColor].CGColor;
    view.layer.borderWidth = 1.0;
}

- (UIImageView *)shadowView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cellShadow"]];
}

- (UIView *)makeNoteView
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    
    view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    view.layer.shouldRasterize = YES;
    view.userInteractionEnabled = NO;
    view.clipsToBounds = YES;
    
    return view;
}

// use the hidden nextNoteVC's view to create a snapshot of doc
- (UIImage *)imageForDocument:(NoteDocument *)document
{
    NoteDocument *previous = self.currentNoteViewController.note;
    [self.currentNoteViewController setNote:document];
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size,YES,0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.currentNoteViewController.view.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // set back to actual current note
    [self.currentNoteViewController setNote:previous];
    
    return viewImage;
}

#pragma mark Stacking animation helpers


- (float)indexOffsetForStackedNoteAtIndex:(int)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    float offset = -(float)(model.selectedNoteIndex - index);
    
    return offset;
}

- (CGFloat)yOriginForStackedNoteForOffset:(NSInteger)offsetIndex
{
    float sectionZero = [self sectionZeroOffset];
    float newY = sectionZero;
    int absOffset = abs(offsetIndex);
    if (offsetIndex < 0) {
        
        newY += CGRectGetMinY(centerNoteFrame) + (offsetIndex * (100.0*adjustedScale));
        
        if (newY+(kCellHeight*absOffset) >= CGRectGetMinY(centerNoteFrame)){
            newY = CGRectGetMinY(centerNoteFrame)-(kCellHeight*absOffset);
        }
        
    } else {
        
        // pin it to max y of centerNoteFrame + offset for stacking index
        float bottomOffset = kCellHeight*(absOffset-1);
        newY = CGRectGetMaxY(centerNoteFrame) + bottomOffset;
        
    }
    
    return newY;
}

- (CGFloat)newHeightForScale:(CGFloat)scale andDestinationHeight:(CGFloat)destinationHeight
{
    //float adjustedScale = [self adjustedScaleForPinch:scale];
    
    // height we're scaling from varies
    // from (0.0*destinationHeight) + kTotalHeight,
    // to (1.0*destinationHeight) + kTotalHeight,
    // based on how much we've scaled
    float dyamicTotalHeight = (kTotalHeight+((1.0-adjustedScale)*destinationHeight));
    
    float newHeight = adjustedScale*dyamicTotalHeight;
    
    if (newHeight<=destinationHeight) {
        newHeight=destinationHeight;
    }
    
    return newHeight;
}

#pragma mark Cleanup for pinch gesture state ended

- (void)resetCurrentNoteView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         [_currentNote setFrame:self.view.bounds];
                         if (_currentNoteOffsetLocation > 0.0) {
                             [_shadowViewTop setFrameY:(CGRectGetMinY(self.view.bounds))-_shadowViewTop.frame.size.height];
                         }
                         
                         
                     }
                     completion:^(BOOL finished){
                         if (_currentNote) {
                             if (_currentNoteOffsetLocation > 0.0) {
                                 [_shadowViewTop removeFromSuperview];
                             }
                             
                             [_currentNote removeFromSuperview];
                             [self.currentNoteViewController setWithNoDataTemp:NO];
                             [self.view.layer setCornerRadius:0.0];
                         }
                       
                     }];
}

- (void)resetStackedNoteViewAtIndex:(int)index
{
    NSDictionary *dict = [stackingViews objectAtIndex:index];
#warning TODO: calculate this just once and store in dict
    float offsetIndex = [self indexOffsetForStackedNoteAtIndex:[stackingViews indexOfObject:dict]];
    
    float newY = offsetIndex < 0 ? 0.0 : 480.0;

    UIView *view = [dict objectForKey:@"noteView"];
    UIView *shadow = [dict objectForKey:@"shadow"];
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGRect newFrame = CGRectMake(0.0, newY, 320.0, 480.0);
                         view.frame = newFrame;
                         [shadow setFrameY:newY-shadow.frame.size.height];
                     }
                     completion:^(BOOL finished){
                         [view removeFromSuperview];
                         [shadow removeFromSuperview];
                     }];
}

- (void)logPinch:(CGFloat)vel scale:(CGFloat)scale
{
    NSLog(@"pinch velocity: %f, scale: %f",vel,scale);
}

- (void)setGestureState:(NoteStackGestureState)state
{
    _currentGestureState = state;
}

- (BOOL)shouldExitWithVelocity:(CGPoint)velocity
{
    BOOL yVelocityForPop = velocity.y > 500;
    BOOL touchCountForPop = numberOfTouchesInCurrentPanGesture==2 ? YES : NO;
    BOOL xVelocityForPop = abs(velocity.x) < velocity.y;
    return yVelocityForPop && touchCountForPop && xVelocityForPop;
}

- (BOOL)wantsToDeleteWithPoint:(CGPoint)point velocity:(CGPoint)velocity
{
    return velocity.x > 0;
}

- (BOOL)wantsToCreateWithPoint:(CGPoint)point velocity:(CGPoint)velocity
{
    return velocity.x < 0;
}

- (void) panReceived:(UIPanGestureRecognizer *)recognizer {
    
    if (_keyboardShowing && [[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultKeyboard"]) {
        return;
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    CGPoint point = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGRect nextNoteFrame = self.nextNoteViewController.view.frame;
    CGRect viewFrame = self.view.frame;
    
    if (self.currentNoteViewController.view.frame.origin.x < 0) {
        self.optionsViewController.view.hidden = YES;
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        numberOfTouchesInCurrentPanGesture = recognizer.numberOfTouches;
        if (numberOfTouchesInCurrentPanGesture == 1) {
            
            [self setNextNoteDocumentForVelocity:velocity];
            
        } else if (numberOfTouchesInCurrentPanGesture >= 2) {
            // wants to exit
            if ([self shouldExitWithVelocity:velocity]) {
                
                [self setGestureState:kShouldExit];
                
            // wants to delete note
            } else if ([self wantsToDeleteWithPoint:point velocity:velocity]) {
                
                [self setGestureState:kShouldDelete];
                [self createDeletingViews];
                
            // wants to create new note
            } else if ([self wantsToCreateWithPoint:point velocity:velocity]) {

                [self setGestureState:kShouldCreateNew];
                [self.view addSubview:self.nextNoteViewController.view];
                self.nextNoteViewController.view.hidden = NO;
                [self.nextNoteViewController setWithPlaceholderData:YES];
            }
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (numberOfTouchesInCurrentPanGesture==1) {
            [self handleSingleTouchPanEndedForVelocity:velocity];
        }
                
        if (numberOfTouchesInCurrentPanGesture >= 2) {
            
            if (_currentGestureState==kShouldExit){//[self shouldExitWithVelocity:velocity]) {
                // show list
                [self setGestureState:kGestureFinished];
                [self popToNoteList:model.selectedNoteIndex];
                
            } else if (_currentGestureState == kShouldCreateNew) {
                // allow cancelation of new note creation if user lets go before midpoint
                if (nextNoteFrame.origin.x > viewFrame.size.width/2 || abs(velocity.x) < FLIP_VELOCITY_THRESHOLD/2) {

                    [self setGestureState:kGestureFinished];
                    [self snapBackNextNote];
                    // undo the dummy placeholder data
                    [self.nextNoteViewController setWithPlaceholderData:NO];
                    
                } else {
                    
                    [self finishCreatingNewDocument];
                }

            } else if (_currentGestureState == kShouldDelete) {
                
                BOOL shouldCancelDelete = (point.x > 0 && point.x < CGRectGetMidX(viewFrame)) || abs(velocity.x) < FLIP_VELOCITY_THRESHOLD/2;
                if (shouldCancelDelete) {
                    [self cancelDeletingNote];
                } else {
                    [self finishDeletingDocument:point];
                }
            }
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        if (numberOfTouchesInCurrentPanGesture == 1) {

            [self handleSingleTouchPanChangedForPoint:point];
            
        } else if (numberOfTouchesInCurrentPanGesture == 2) {

            // delete the note if panning w/ 2 fingers to the right
            if (_currentGestureState == kShouldDelete) {
                //NSLog(@"should delete: %s",shouldDeleteNote ? "YES" : "NO");
                
                self.currentNoteViewController.view.hidden = YES;
                
                NoteDocument *nextDocument = [model nextNoteDocInStackFromIndex:model.selectedNoteIndex];
                self.nextNoteViewController.note = nextDocument;
                [self animateDeletingViewsForPoint:point];
            }
            // else user is wanting to create a new note
            else if (_currentGestureState == kShouldCreateNew){//point.x < 0 && abs(velocity.y)< 30) {
            
                // move next document in from the far right, on top
                [self updatePositionOfNextDocumentToPoint:point];
            }
        }
    }
}

- (void)setNextNoteDocumentForVelocity:(CGPoint)velocity
{
    int noteCount = [[ApplicationModel sharedInstance].currentNoteEntries count];
    int xDirection = (velocity.x > 0) ? PREVIOUS_DIRECTION : NEXT_DIRECTION;
    
    NoteDocument *entryUnderneath;
    if (noteCount == 1) {
        self.nextNoteViewController.view.hidden = YES;
    } else {
        self.nextNoteViewController.view.hidden = NO;
        if (xDirection == PREVIOUS_DIRECTION) {
            entryUnderneath = self.previousNoteDocument;
        } else {
            entryUnderneath = self.nextNoteDocument;
        }
        self.nextNoteViewController.note = entryUnderneath;
    }
}

- (void)finishDeletingDocument:(CGPoint)point
{
    // shredding animations for deletion
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteDocument *toDelete = currentNoteViewController.note;
    [self setGestureState:kGestureFinished];
    
    NSLog(@"should delete %@",toDelete.text);
    __block int completeCount = 0;
    for (int k = 0; k < [deletingViews count]; k++) {
        
        double middle = deletingViews.count/2.0;
        UIImageView *view = [deletingViews objectAtIndex:k];
        view.hidden = NO;
        CGRect frame = view.frame;
        frame.origin.x = 420.0;
        
        if (k < [deletingViews count]/2.0) {
            frame.origin.y = (480*k/(deletingViews.count)) - point.x*((middle - k)/middle);
        } else {
            frame.origin.y = (480*k/(deletingViews.count)) + point.x*((k-middle)/middle);
        }
        
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView animateWithDuration:0.5
                         animations:^{
                             view.frame = frame;
                         }
                         completion:^(BOOL finished){
                             completeCount ++;
                             [view removeFromSuperview];
                             
                             if (completeCount==deletingViews.count) {
                                 
                                 self.currentNoteViewController.view.hidden = NO;
                                 
                                 [deletingViews removeAllObjects];
                                 
                                 [model setCurrentNoteIndexToNextPriorToDelete];
                                 [[ApplicationModel sharedInstance] deleteNoteEntry:toDelete withCompletionBlock:^{
                                 }];
                                 
                                 [self updateNoteDocumentsForIndex:model.selectedNoteIndex];
                                 
                             }
                         }];
    }

}

- (void)cancelDeletingNote
{
    [self setGestureState:kGestureFinished];
    for (int k = 0; k < [deletingViews count]; k++) {
        UIView *view = [deletingViews objectAtIndex:k];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             CGRect frame = view.frame;
                             frame.origin = CGPointMake(0, (480*k/(deletingViews.count)));
                             view.frame = frame;
                         }
                         completion:^(BOOL finished){
                             self.currentNoteViewController.view.hidden = NO;
                             
                             
                             [view removeFromSuperview];
                             
                         }];
    }

}

- (void)handleSingleTouchPanChangedForPoint:(CGPoint)point
{
    // move the current note vc with the touch location
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    CGRect newFrame = CGRectMake(0 + point.x, 0, currentNoteFrame.size.width, currentNoteFrame.size.height);
    CGRect viewFrame = self.view.frame;
    
    self.currentNoteViewController.view.frame = newFrame;
    NoteDocument *entryUnderneath = nil;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    int noteCount = [model.currentNoteEntries count];
    if (noteCount > 1) {
        
        // if user has moved it far enough to what's behind on the left side
        if (currentNoteFrame.origin.x + currentNoteFrame.size.width > viewFrame.size.width) {
            entryUnderneath = self.previousNoteDocument;
            self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
            self.nextNoteViewController.note = entryUnderneath;
            // else if user has moved it far enough to what's behind on the right side
        } else if (currentNoteFrame.origin.x < viewFrame.origin.x) {
            entryUnderneath = self.nextNoteDocument;
            self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
            self.nextNoteViewController.note = entryUnderneath;
        }
    }
}

- (void)handleSingleTouchPanEndedForVelocity:(CGPoint)velocity
{
    CGRect viewFrame = self.view.frame;
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    if (currentNoteFrame.origin.x > viewFrame.size.width/2 || velocity.x > FLIP_VELOCITY_THRESHOLD) {
        [self animateCurrentOutToRight];
    } else if (currentNoteFrame.origin.x + currentNoteFrame.size.width < viewFrame.size.width/2 || velocity.x < -FLIP_VELOCITY_THRESHOLD) {
        [self animateCurrentOutToLeft];
    } else { // snap back
        [self snapBackCurrentNote];
    }
}

- (void)finishCreatingNewDocument
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model createNoteWithCompletionBlock:^(NoteDocument *doc){
        
    }];
    
    [model setSelectedNoteIndex:0];
    int currentIndex = model.selectedNoteIndex;
    
    [self setGestureState:kGestureFinished];
    self.currentNoteViewController.view.hidden = NO;
    [self makeNoteViewStackImages];
    
    CGRect viewFrame = self.view.frame;
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.nextNoteViewController.view.frame = CGRectMake(0.0, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         [self.view addSubview:self.currentNoteViewController.view];
                         [self updateNoteDocumentsForIndex:currentIndex];
                     }];
}

- (void)animateCurrentOutToLeft
{
    CGRect viewFrame = self.view.frame;
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(-viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         if (success) {
                             
                             [model setCurrentNoteIndexToNext];
                             
                             int currentIndex = model.selectedNoteIndex;
                             [self updateNoteDocumentsForIndex:currentIndex];
                             
                             
                         }
                     }];
}

- (void)animateCurrentOutToRight
{
    CGRect viewFrame = self.view.frame;
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         if (success) {
                             [model setCurrentNoteIndexToPrevious];
                             int currentIndex = model.selectedNoteIndex;
                             [self updateNoteDocumentsForIndex:currentIndex];
                         }
                     }];
}

- (void)updatePositionOfNextDocumentToPoint:(CGPoint)point
{
    // bring 'new'/next note vc in on top of current note vc
    CGRect frame = self.nextNoteViewController.view.frame;
    
    // multiplier to make sure note is aligned left by time fingers reach left side of screen
    float offset = 320.0 - abs(point.x);
    float newXLoc = offset-abs(point.x);
    if (newXLoc<0.0) {
        newXLoc = 0.0;
    }
    CGRect newFrame = CGRectMake(newXLoc, 0, frame.size.width, frame.size.height);
    self.nextNoteViewController.view.frame = newFrame;
}

- (void)createDeletingViews
{
    deletingViews = [NSMutableArray new];
    
    UIImage *viewImage = [self imageForDocument:self.currentNoteViewController.note];
    
    // Create and show the new image from bitmap data
    for (int k = 0; k <= numberOfTouchesInCurrentPanGesture; k++) {
        // Create rectangle that represents a cropped image
        // from the middle of the existing image
        CGRect cropRect = CGRectMake(0, (480*k)/(numberOfTouchesInCurrentPanGesture+1), 320, 480/(numberOfTouchesInCurrentPanGesture+1));
        
        // Create and show the new image from bitmap data
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[viewImage crop:cropRect]];
        imageView.frame = CGRectMake(0, 0, 320, 480/(numberOfTouchesInCurrentPanGesture+1));
        [deletingViews addObject:imageView];
        imageView.hidden = YES;
        
        
        imageView.layer.shadowColor = [[UIColor blackColor] CGColor];
        imageView.layer.shadowOffset = CGSizeMake(-1,-2);
        imageView.layer.shadowOpacity = .70;
        imageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        imageView.layer.shouldRasterize = YES;
        [imageView.layer setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:imageView.bounds cornerRadius:6.5] CGPath]];
        imageView.layer.cornerRadius = 6.5;
        
        [self.view addSubview:imageView];
    }

}

- (void)animateDeletingViewsForPoint:(CGPoint)point
{
    for (int k = 0; k < [deletingViews count]; k++) {
        double middle = deletingViews.count/2.0;
        UIImageView *view = [deletingViews objectAtIndex:k];
        view.hidden = NO;
        CGRect frame = view.frame;
        frame.origin.x = 0 + (point.x);
        if (k < [deletingViews count]/2.0) {
            frame.origin.y = (480*k/(deletingViews.count)) - point.x*((middle - k)/middle);
        }else {
            frame.origin.y = (480*k/(deletingViews.count)) + point.x*((k-middle)/middle);
        }
        if (frame.origin.x < 0) {
            frame.origin.x = 0;
        }
        view.frame = frame;
    }
}

- (void)snapBackCurrentNote
{
    // snap back
    CGRect viewFrame = self.view.frame;
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:NULL];
}

- (void)snapBackNextNote
{
    // snap back
    CGRect viewFrame = self.view.frame;
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.nextNoteViewController.view.frame = CGRectMake(viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL complete){
                         self.nextNoteViewController.view.frame = viewFrame;
                         [self.view addSubview:currentNoteViewController.view];
                     }];
}

- (void)slideOffCurrentNoteToLeftWithCompletion:(void(^)())completion
{
    CGRect viewFrame = self.view.frame;
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(-viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         completion();
                     }];
}

- (void)popToNoteList:(int)index
{
    self.dismissBlock(index);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateNoteDocumentsForIndex:(NSUInteger)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    //self.previousNoteEntry = [model previousNoteInStackFromIndex:index];
    //self.nextNoteEntry = [model nextNoteInStackFromIndex:index];
    
    self.previousNoteDocument = [model previousNoteDocInStackFromIndex:index];
    //NSLog(@"previous doc %@",[self.previousNoteDocument text]);
    
    NoteDocument *docToShow = [model noteDocumentAtIndex:index];
    //NSLog(@"should show doc %@",[docToShow text]);
    
    self.nextNoteDocument = [model nextNoteDocInStackFromIndex:index];
    //NSLog(@"next doc %@",[self.nextNoteDocument text]);
    
    self.currentNoteViewController.note = docToShow;
    [self.currentNoteViewController.view setNeedsDisplay];
    self.currentNoteViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    //NSLog(@"%@ %d",[[self.currentNoteViewController noteEntry] text],__LINE__);
    //NSLog(@"%@ %d",self.currentNoteViewController.textView.text,__LINE__);
    
    [self makeNoteViewStackImages];
}

- (void)showVelocity:(CGPoint)velocity andEntryUnderneath:(NoteDocument *)entryUnderneath
{
    NSLog(@"velocity: %@",NSStringFromCGPoint(velocity));
    NSLog(@"entry underneath: %@",entryUnderneath.text);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"note is touched");
    
    if (_currentGestureState == kStackingPinch) {
        return;
    }
    
    if(!self.optionsViewController.view.hidden) {
        // find the element that is being touched, if any.
        CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        CGRect frame = self.overView.frame;
        if(!CGRectContainsPoint(frame, currentLocation)) {
            NSLog(@"touch options panel");
        }else {
            
            [self shiftCurrentNoteOriginToPoint:CGPointMake(0, 0) completion:^{
                [self.optionsViewController reset];
            }];
            NSLog(@"touched outside of options");
        }
    }
}

#pragma mark OptionsViewController Delegate

-(void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor {
    [self.currentNoteViewController setColors:color textColor:textColor];
}

-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point completion:(void(^)())completionBlock
{
    if (point.x != 0) {
        self.optionsViewController.view.hidden = NO;
    } 
    [self.currentNoteViewController.textView resignFirstResponder];
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(point.x, point.y, 320, 480);
                     } completion:^(BOOL success){
                         if (point.x == 0) {
                             [self.overView removeFromSuperview];
                             self.overView = nil;
                             self.optionsViewController.view.hidden = YES;
                         }else {
                             if (!self.overView) {
                                 self.overView = [UIView new];
                                 [self.view addSubview:self.overView];
                             }
                             self.overView.frame = self.currentNoteViewController.view.frame;
                         }
                         
                         if (completionBlock)
                             completionBlock();
                     }];
}

#pragma mark - Keyboard notifications

- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    // Step 1: Get the size of the keyboard.
    CGSize keyboardSize = [[[theNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Step 2: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.currentNoteViewController.textView.contentInset = contentInsets;
    self.currentNoteViewController.textView.scrollIndicatorInsets = contentInsets;
}

- (void) shiftViewDownAfterKeyboard:(NSNotification*)theNotification;
{
    // Step 1: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.currentNoteViewController.textView.contentInset = contentInsets;
    self.currentNoteViewController.textView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Keyboard Delegate
//TODO error checking isALetterTwoAgo

//This might want to be changed so that the NoteViewController handles all of this.
-(void)printKeySelected:(NSString *)label {
    //may have to add in the "space" case
    if ([label isEqualToString:@" "]) {
        NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
        BOOL isALetterTwoAgo = [set characterIsMember: [self.currentNoteViewController.textView.text characterAtIndex:self.currentNoteViewController.textView.selectedRange.location-2]];
        unichar lastCharacterUni = [self.currentNoteViewController.textView.text characterAtIndex:self.currentNoteViewController.textView.selectedRange.location-1];
        NSString *lastCharacter = [NSString stringWithCharacters:&lastCharacterUni length:1];
        if (isALetterTwoAgo && [lastCharacter isEqualToString:@" "]){
            // code that you use to remove the last character
            [self.currentNoteViewController.textView deleteBackward];
            [self.currentNoteViewController.textView insertText:@"."];
        }
    }
    if ([label isEqualToString:@"delete"]) {
        
        //delete the last character out of the textview
        NSUInteger lastCharacterPosition = [self.currentNoteViewController.textView.text length];
        
        //not at the beginning of the note
        if(lastCharacterPosition > 0){
            [self.currentNoteViewController.textView deleteBackward];
        }
    } else if ([label isEqualToString:@"return"]) {
        unichar ch = 0x000A;
        NSString *unicodeString = [NSString stringWithCharacters:&ch length:1];
        [self.currentNoteViewController.textView insertText:unicodeString];
    } else {
        [self.currentNoteViewController.textView insertText:label];
    }
    [self.currentNoteViewController.textView.delegate textViewDidChange:self.currentNoteViewController.textView];
}

-(void)closeKeyboard {
    [self.currentNoteViewController.textView resignFirstResponder];
}

-(void)undoEdit {
    [self.currentNoteViewController.textView.undoManager undo];
    NSLog(@"Undo Detected");
}
-(void)redoEdit {
    [self.currentNoteViewController.textView.undoManager redo];
    NSLog(@"Redo Detected");
}


-(void)panKeyboard:(CGPoint)point {
    CGRect frame = self.keyboardViewController.view.frame;
    frame.origin.y =  0 + point.y;
    if (frame.origin.y < 0) frame.origin.y = 0;
    self.keyboardViewController.view.frame = frame;
}

-(void)snapKeyboardBack {
    CGRect frame = self.keyboardViewController.view.frame;
    frame.origin = CGPointMake(0, 0);
    self.keyboardViewController.view.frame = frame;
}

@end
