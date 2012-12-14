//
//  NoteStackViewController.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteStackViewController.h"
#import "AppDelegate.h"
#import "ApplicationModel.h"
#import "NoteViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteEntry.h"
#import "NoteDocument.h"
#import "UIImage+Crop.h"
#import "UIView+position.h"
#import "AnimationStackViewController.h"
#import "NoteEntryCell.h"
#import "WalkThroughViewController.h"
#import "UIColor+HexColor.h"

typedef enum {
    kGestureFinished,
    kShouldDelete,
    kShouldCreateNew,
    kStackingPinch,
    kCycle
} NoteStackGestureState;

#define kFingerTipsTag 576

static const int NEXT_DIRECTION = 0;
static const int PREVIOUS_DIRECTION = 1;
static const float DURATION = 0.3;
static const float FLIP_VELOCITY_THRESHOLD = 500;
static const float CREATE_NEW_VELOCITY_THRESHOLD = 125;

static const float kCornerRadius = 6.0;
static const float kSectionZeroHeight = 44.0;
static const float kPinchDistanceCompleteThreshold = 130.0;

@interface NoteStackViewController () {
    
    int numberOfTouchesInCurrentPanGesture;
    float NUMBER_OF_SLICES;
    BOOL optionsShowing;
    BOOL creatingNewNote;
    
    NSMutableArray *deletingViews;
    
    UIView *_currentNote;
    UIImageView *_shadowView;
    UIImageView *_shadowViewTop;
    
    NSMutableArray *stackingViews;
    
    TTAlertView *_alertView;
    
    BOOL shouldMakeNewNote;
    BOOL shouldDeleteNote;
    BOOL shouldExitStack;
    BOOL pinchComplete;
    
    CGRect centerNoteFrame;
    
    NoteStackGestureState _currentGestureState;
    AnimationStackViewController *_stackVC;
    
    CGFloat pinchYTarget;
    CGFloat pinchDistance;
    CGFloat pinchVelocity;
    
    float pinchPercentComplete;
    CGFloat initialPinchDistance;
    
    NSDictionary *_currentTourStep;
    NSTimer *walkthroughGestureTimer;
}

@property (strong,nonatomic)MFMailComposeViewController *mailVC;
@property (strong,nonatomic)MFMessageComposeViewController *messageVC;
@property (nonatomic, strong) UIView *sliceView;
@property (nonatomic, strong) UIImageView *screenShot;
@property (nonatomic, strong) UIImageView *slicedNoteScreenShot;
@property (nonatomic, strong) NSMutableArray *slicedNoteArray;

@property (weak, nonatomic) IBOutlet UIView *addNoteView;
@property (weak, nonatomic) IBOutlet UILabel *addNoteLabel;

- (void) presentNotes;

@end

@implementation NoteStackViewController

@synthesize dismissBlock=_dismissBlock;
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
@synthesize mailVC,messageVC;
@synthesize delegate;
@synthesize keyboard, originalLocation, originalKeyboardY, sliceView, screenShot, slicedNoteScreenShot, slicedNoteArray;
@synthesize addNoteView, addNoteLabel;

- (id)initWithDismissalBlock:(TMDismissalBlock)dismiss andStackVC:(AnimationStackViewController *)stackVC
{
    self = [super initWithNibName:@"NoteStackViewController" bundle:nil];
    if (self){
        _dismissBlock = dismiss;
        _stackVC = stackVC;
        shouldMakeNewNote = shouldDeleteNote = shouldExitStack = NO;
        creatingNewNote = NO;
        centerNoteFrame = CGRectZero;
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
    
    self.slicedNoteArray = [NSMutableArray new];
    self.slicedNoteScreenShot = [UIImageView new];
    
    [self.view.layer setCornerRadius:kCornerRadius];
    [self.view setClipsToBounds:YES];
    [self.view setBackgroundColor:[UIColor colorWithHexString:@"F0F0F0"]];

    initialPinchDistance = 0.0;
    self.view.layer.cornerRadius = kCornerRadius;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNoteListChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        // if user changes storage settings while viewing this screen
        [self presentNotes];
    
    }];
    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    frame.origin = CGPointMake(0.0, 0.0);
    
    self.sliceView = [[UIView alloc] initWithFrame:CGRectMake(-320, 0, frame.size.width, frame.size.height)];
    self.screenShot = [UIImageView new];
    
    self.currentNoteViewController = [[NoteViewController alloc] init];
    [self.currentNoteViewController setIsCurrent:YES];
    self.currentNoteViewController.delegate = self;
    self.currentNoteViewController.view.frame = frame;
    [self.view addSubview:self.currentNoteViewController.view];
    
    [self configureKeyboard];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"keyboardSettingChanged" object:nil queue:nil usingBlock:^(NSNotification *note){
        [self configureKeyboard];
    }];
  
    self.nextNoteViewController = [[NoteViewController alloc] init];
    [self.view insertSubview:self.nextNoteViewController.view belowSubview:self.currentNoteViewController.view]; //stacking view controllers
    
    self.optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil]; //settings screen
    self.optionsViewController.delegate = self;
    self.optionsViewController.view.frame = frame;
    NSLog(@"%@",NSStringFromCGRect(self.optionsViewController.view.frame));
    self.optionsViewController.view.hidden = YES;
    [self.view insertSubview:self.optionsViewController.view belowSubview:self.currentNoteViewController.view]; //stacking options view underneath the current note view
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceived:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinch];
      
    [self setCurrentNoteToModel];
    
    [self handleNotifications];
    
    NSArray *slicesArray = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"strip-one"], [UIImage imageNamed:@"strip-two"], [UIImage imageNamed:@"strip-three"], nil];
    
    for (int i = 0; i < frame.size.height/30; i++) { //have to add the images here because when i tried to add it to deletePan: the images didn't appear correctly. I don't know why
        UIImageView *sliceImageView = [[UIImageView alloc] initWithImage:[slicesArray objectAtIndex:arc4random()%3]];
        sliceImageView.frame = CGRectMake(0, (frame.size.height*i)/(frame.size.height/sliceImageView.image.size.height), sliceImageView.image.size.width, sliceImageView.image.size.height);
        [self.sliceView addSubview:sliceImageView];
        
        NUMBER_OF_SLICES = frame.size.height/sliceImageView.image.size.height;
    }
    
    [self.view addSubview:self.sliceView];
}

- (void)handleNotifications
{
    [[NSNotificationCenter defaultCenter] addObserverForName:@"didToggleStatusBar" object:nil queue:nil usingBlock:^(NSNotification *note){
        
        CGRect newFrame =  [[UIScreen mainScreen] applicationFrame];
        newFrame.origin.x = self.currentNoteViewController.view.frame.origin.x;
        [UIView animateWithDuration:0.5
                         animations:^{
                             [self.view setFrameY:newFrame.origin.y];
                             NSLog(@"from %@ to %@",NSStringFromCGRect(self.currentNoteViewController.view.frame),NSStringFromCGRect(newFrame));
                             //[self debugView:self.currentNoteViewController.view color:[UIColor redColor]];
                             //self.nextNoteViewController.view.frame = newFrame;
                         }
                         completion:nil];
        //[_stackVC.view setFrame:newFrame];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kWalkThroughStepBegun object:nil queue:nil usingBlock:^(NSNotification *note){
        if ([[note.userInfo objectForKey:kStepViewControllerClass] isEqual:NSStringFromClass([self class])]) {
            _currentTourStep = note.userInfo;
            
            if ([[_currentTourStep objectForKey:@"index"] intValue] != -1) {
                [self performSelector:@selector(beginTouchDemoAnimation) withObject:nil afterDelay:1.2];
            }
            
        } else {
            _currentTourStep = nil;
            [self endTouchDemoAnimation];
        }
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kWalkThroughExited object:nil queue:nil usingBlock:^(NSNotification *note){
        _currentTourStep = nil;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDocumentStateChangedNotification object:self.currentNoteViewController.noteDocument queue:nil usingBlock:^(NSNotification *note){
        NoteDocument *doc = self.currentNoteViewController.noteDocument;
        NSLog(@"State of doc %i",doc.documentState);
        NSLog(@"%i",__LINE__);
    }];
}

// on first view of note as well as right after creating note by pan getsure
- (void)setCurrentNoteToModel
{
    NoteDocument *previousDoc = self.currentNoteViewController.noteDocument;
    [previousDoc closeWithCompletionHandler:^(BOOL success){
        NSLog(@"closed doc %@",previousDoc.fileURL.lastPathComponent);
    }];
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [self.currentNoteViewController setNoteEntry:[model noteAtSelectedNoteIndex]];
    [model noteDocumentAtIndex:model.selectedNoteIndex completion:^(NoteDocument *doc){
        self.currentNoteViewController.noteDocument = doc;
        NSLog(@"\n\nOpened and set as current %@",self.currentNoteViewController.noteDocument.fileURL.lastPathComponent);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self presentNotes];
    [self.delegate indexDidChange];
   
    
    int64_t delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        AppDelegate *del = APP_DELEGATE;
        [del resumeWalkthroughWithView:self.view];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.currentNoteViewController.noteDocument closeWithCompletionHandler:^(BOOL success){
        NSLog(@"\nclosed doc with url: %@",self.currentNoteViewController.noteDocument.fileURL.lastPathComponent);
    }];
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
    [self setAddNoteView:nil];
    [self setAddNoteLabel:nil];
    [super viewDidUnload];
}

- (void)presentNotes {
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSUInteger currentIndex = model.selectedNoteIndex;
    
    if (model.currentNoteEntries.count == 0) {
        return;
    }
    
    self.previousNoteEntry = [model previousNoteInStackFromIndex:currentIndex];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:currentIndex];
    
    [self setStackState];
}

- (void)setStackState
{
    if (_stackVC.state != kNoteStack) {
        [_stackVC setState:kNoteStack];
        [self.view addSubview:_stackVC.view];
        [_stackVC.view setFrameX:-320.0];
    }
}

#pragma mark Pinch gesture to collapse notes stack

- (void)setPinchPercentComplete:(float)percent
{
    pinchPercentComplete = percent;
    
    if (pinchPercentComplete>=1.0) {
        pinchPercentComplete = 1.0;
    } else if (pinchPercentComplete<0.0) {
        pinchPercentComplete = 0.0;
    }
}

- (void) alertView:(TTAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        
        
    } else if (buttonIndex==1) {
        _alertView = nil;
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    int noteCount = [[[ApplicationModel sharedInstance] currentNoteEntries] count];
    if ([self walkthroughShouldBlockForStep:walkThroughStepGoToList]) {
        NSLog(@"prevented pinch gesture");
        return;
    }
    
    [self endTouchDemoAnimation];
    if (noteCount < 2){
        NSLog(@"only show list if there's more than one note, do a bounce animation");
//#warning Re-comment to prvent exiting last note
        /*
         if (!_alertView) {
         _alertView = [[TTAlertView alloc] initWithTitle:@"Last note!" message:@"No other notes to see here." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
         [_alertView.containerView setBackgroundColor:[UIColor colorWithHexString:@"1A9FEB"]];
         [_alertView show];
         }
         */
        
        return;
    }
    
    CGFloat scale = gesture.scale;
        
    pinchYTarget = [gesture locationInView:self.view].y;
    pinchVelocity = gesture.velocity;

    if ([gesture numberOfTouches] == 2 && _currentGestureState==kStackingPinch) {
        CGPoint p1 = [gesture locationOfTouch:0 inView:self.view]; //first finger
        CGPoint p2 = [gesture locationOfTouch:1 inView:self.view]; //second finger
        
        // Compute the new spread distance.
        CGFloat xd = p1.x - p2.x;
        CGFloat yd = p1.y - p2.y;
        pinchDistance = sqrt(xd*xd + yd*yd);
        
        if (initialPinchDistance==0.0) {
            initialPinchDistance = pinchDistance;
        }
    }
    
    [self setPinchPercentComplete:(initialPinchDistance-pinchDistance)/(initialPinchDistance-kPinchDistanceCompleteThreshold)];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        [self endTouchDemoAnimation];
        
        if (_stackVC.view.frame.origin.x < 0.0) {
            [_stackVC.view setFrameX: 0.0];
        }
        [self pinchToCollapseBegun:YES];
        [_stackVC prepareForCollapse];
        if (![_stackVC needsAnimation]) {
            [self finishPinch];
            return;
        }
        [self.view addSubview:_stackVC.view];
        [_stackVC animateCollapseForScale:scale percentComplete:pinchPercentComplete];
      
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        [_stackVC animateCollapseForScale:scale percentComplete:pinchPercentComplete];

        if (pinchPercentComplete>=1.0) {
            NSLog(@"reported as complete");
            pinchComplete = YES;
        } else {
            pinchComplete = NO;
        }
        
        // a strong pinch should finish things immediately
        if (pinchVelocity < -0.8 && pinchComplete) {
            [self.view setUserInteractionEnabled:NO];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        
        [self pinchToCollapseBegun:NO];
        
        if (pinchComplete) {
            [self finishPinch];
            
        } else {
            [_stackVC resetToExpanded:^{
                [self.currentNoteViewController setWithNoDataTemp:NO];
                if (_stackVC.view.frame.origin.x == 0.0) {
                    [_stackVC.view setFrameX:-320.0];
                }
            }];
        }
    }
}

- (void)pinchToCollapseBegun:(BOOL)val
{
    pinchPercentComplete = 0.0;
    
    if (val) {

        [self.currentNoteViewController.textView resignFirstResponder];
        [self.currentNoteViewController.textView setScrollEnabled:NO];
        [self setGestureState:kStackingPinch];
        
    } else {
        
        [self.currentNoteViewController.textView setScrollEnabled:YES];
        [self setGestureState:kGestureFinished];
        
    }
}

- (void)finishPinch
{
    [_stackVC finishCollapse:^{
        
        [self.view setUserInteractionEnabled:YES];
        initialPinchDistance = 0.0;
        _currentGestureState = kGestureFinished;
        [self.currentNoteViewController setWithNoDataTemp:NO];
        self.dismissBlock([_stackVC finalYOriginForCurrentNote]);
        [self dismissViewControllerAnimated:NO completion:nil];
        [self walkThroughStepCheck:walkThroughStepGoToList];
        
    }];
}

#pragma mark Stacked note views setup

static const float kCellHeight = 66.0;
static const float kAverageMinimumDistanceBetweenTouches = 110.0;

- (int)documentCount
{
    return [[ApplicationModel sharedInstance] currentNoteEntries].count;
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 2.0;
}

- (UIImageView *)shadowView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cellShadow"]];
}

// use the hidden nextNoteVC's view to create a snapshot of doc
- (UIImage *)imageForDocument:(NoteEntry *)noteEntry
{
    NoteEntry *previous = self.currentNoteViewController.noteEntry;
    [self.currentNoteViewController setNoteEntry:noteEntry];
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size,YES,0.0f); //screenshot
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.currentNoteViewController.view.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // set back to actual current note
    [self.currentNoteViewController setNoteEntry:previous];
    
    return viewImage;
}

#pragma mark Stacking animation helpers


- (float)indexOffsetForStackedNoteAtIndex:(int)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    float offset = -(float)(model.selectedNoteIndex - index);
    
    return offset;
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
    BOOL shouldDelete = velocity.x != 0 ? YES : NO;
    if ([self walkthroughShouldBlockForStep:walkThroughStepDelete]) {
        shouldDelete = NO;
    } else {
        return shouldDelete;
    }
    
    return shouldDelete;
}

- (BOOL)wantsToCreateWithPoint:(CGPoint)point velocity:(CGPoint)velocity
{
    BOOL shouldCreate = velocity.y != 0.0;// && abs(velocity.x) < 800.0;
    if (!_currentTourStep) {
        return shouldCreate;
    }
    
    int currentStep = [[_currentTourStep objectForKey:@"index"] intValue];
    if (currentStep != walkThroughStepCreate1 && currentStep != walkThroughStepCreate2) {
        shouldCreate =  NO;
    }
    
    if (!shouldCreate) {
        NSLog(@"stop");
    }
        
    return shouldCreate;
}

- (BOOL)wantsToCycleWithVelocity:(CGPoint)velocity
{
    BOOL shouldCycle = velocity.x != 0 && abs(velocity.y) < 60.0;
    
    if ([self walkthroughShouldBlockForStep:walkThroughStepCycle]) {
        shouldCycle = NO;
    }
    
    if (!shouldCycle) {
        NSLog(@"\n\nrejected cycle for velocity: %@\n\n",NSStringFromCGPoint(velocity));
    }
    
    return shouldCycle;
}


#pragma mark Main gesture set

- (void) panReceived:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    //NSLog(@"velocity %@",NSStringFromCGPoint(velocity));
    //NSLog(@"hidden: %s, frame: %@",self.nextNoteViewController.view.hidden ? "yes" : "no",NSStringFromCGRect(self.nextNoteViewController.view.frame));
    //CGRect nextNoteFrame = self.nextNoteViewController.view.frame;
    //CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    
    //NSLog(@"gesture state %i",_currentGestureState);
    
    if (self.currentNoteViewController.view.frame.origin.x < 0) {
        self.optionsViewController.view.hidden = YES;
    }
    
    //if (self.currentNoteViewController.textView.isDragging) { //prevents accidental switching of note when user is scrolling current note
    //    return;
    //}
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.currentNoteViewController.textView.scrollEnabled = NO;
        numberOfTouchesInCurrentPanGesture = recognizer.numberOfTouches;
        
        if (numberOfTouchesInCurrentPanGesture == 1) { //switches note
            
            if ([self wantsToCycleWithVelocity:velocity]) {
                
                 [self endTouchDemoAnimation];
                 [self setGestureState:kCycle];
                 self.currentNoteViewController.textView.scrollEnabled = NO;
                 [self setNextNoteDocumentForVelocity:velocity];
                 
            } else if ([self wantsToCreateWithPoint:point velocity:velocity]) {
                [self endTouchDemoAnimation];
                [self setGestureState:kShouldCreateNew];
                
                [self.nextNoteViewController setWithPlaceholderData:YES defaultData:nil];
                //[self debugView:self.nextNoteViewController.view color:[UIColor greenColor]];
                [self.view addSubview:self.nextNoteViewController.view];
                self.nextNoteViewController.view.hidden = NO;
            } else {
                NSLog(@"\n\nNo gesture captured for velocity %@\n\n",NSStringFromCGPoint(velocity));
            }
            
        } else if (numberOfTouchesInCurrentPanGesture >= 2) { //two finger delete
            if ([self wantsToDeleteWithPoint:point velocity:velocity]) { //if the pan gesture is going from left to right
                [self endTouchDemoAnimation];
                [self setGestureState:kShouldDelete];
                self.currentNoteViewController.textView.scrollEnabled = NO;
                [self.view bringSubviewToFront:self.sliceView];
            } 
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) { //this handles the drag animation
        
        if (numberOfTouchesInCurrentPanGesture == 1) {
            if (_currentGestureState == kCycle) {
                [self handleSingleTouchPanChangedForPoint:point]; //switches note
            } else if (_currentGestureState == kShouldCreateNew) {
                // move next document in from the far right, on top
                [self updatePositionOfNextDocumentToPoint:point];
                //[self handleCreationGestureForPoint:point];
            }
        } else if (numberOfTouchesInCurrentPanGesture == 2) {
            //NSLog(@"hidden? %s",[self.currentNoteViewController.view isHidden] ? "yes" : " no");
            //NSLog(@"%@",NSStringFromCGRect(self.currentNoteViewController.view.frame));
            // delete the note if panning w/ 2 fingers to the right
            if (_currentGestureState == kShouldDelete) {
                float newX = 0.0;
                if (velocity.x > 0.0) {
                    newX = point.x - self.view.frame.size.width;
                } else if (velocity.x < 0.0) {
                    newX = self.view.frame.size.width + point.x;
                }
                
                self.sliceView.frame = CGRectMake(newX, 0, self.view.frame.size.width, self.view.frame.size.height); //move the self.sliceView UIView with the slice Images to wherever the fingers are dragged
                
            }
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        self.currentNoteViewController.textView.scrollEnabled = YES;
        
        if (numberOfTouchesInCurrentPanGesture == 1){
            if (_currentGestureState == kCycle) { //if the user ended their one finger pan gesture
                [self handleSingleTouchPanEndedForVelocity:velocity]; //either changes the note to the next note or animates and "snaps" back the current note depending on whether 1. there's another note in the stack or 2. the user panned far enough on the screen or not
            } else if (_currentGestureState == kShouldCreateNew) {
                //NSLog(@"%@",NSStringFromCGRect(nextNoteFrame));
                //NSLog(@"if (%f < %f || %i < %f) then should cancel",CGRectGetMaxY(nextNoteFrame),viewFrame.size.height/2,abs(velocity.y),FLIP_VELOCITY_THRESHOLD/4);
                if ([self shouldCancelForPoint:point velocity:velocity]) { //midpoint not working
                    [self setGestureState:kGestureFinished];
                    [self snapBackCurrentNote];
                    
                    self.nextNoteViewController.view.hidden = YES;
                    [self snapBackNextNote];
                    // undo the dummy placeholder data
                    //NSLog(@"CANCELED NEW WITH velocity %@",NSStringFromCGPoint(velocity));
                } else {
                    
                    [self finishCreatingNewDocumentWithVelocity:velocity];
                }
            }
        }
        
        if (numberOfTouchesInCurrentPanGesture == 2) {
            
            if (_currentGestureState == kShouldDelete) { //if the user panned from left to right to delete
                BOOL shouldCancel = NO;
                if (velocity.x > 0) {
                    if (point.x < self.view.frame.size.width/2) {
                        shouldCancel = YES;
                    }
                } else if (velocity.x < 0) {
                    if (point.x > self.view.frame.size.width/2) {
                        shouldCancel = YES;
                    }
                }
                if (shouldCancel) { //if user didn't pan past the half way point
                    [UIView animateWithDuration:1.0
                                     animations:^(void){
                                         float newX = 0.0;
                                         if (velocity.x > 0) {
                                             newX = -320.0;
                                         } else if (velocity.x < 0) {
                                             newX = 320.0;
                                         }
                                         self.sliceView.frame = CGRectMake(newX, 0, self.view.frame.size.width, self.view.frame.size.height); //slowly animate the slice view back off screen
                                     }
                                     completion:^(BOOL finished){
                                         self.currentNoteViewController.view.hidden = NO; //and show the actual note again
                                         //self.screenShot.hidden = YES;
                                         [self finishDeletingDocument:point];
                                     }];
                } else { //if user panned past the half way point

                    [UIView animateWithDuration:0.5
                                     animations:^(void){
                                         
                                        self.sliceView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //complete the animation to "slice" the whole note
                                     }completion:^(BOOL finished){
                                         UIGraphicsBeginImageContext(CGSizeMake(self.view.frame.size.width, self.view.frame.size.height));
                                         CGContextRef context = UIGraphicsGetCurrentContext();
                                         [self.view.layer renderInContext:context]; //gets screenshot of the note
                                         //[self.sliceView.layer renderInContext:context]; //gets screenshot of the slice images
                                         UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext(); //saves both as one image
                                         UIGraphicsEndImageContext();
                                         self.slicedNoteScreenShot.image = viewImage;
                                         [self cropNote];
                                         
                                     }];
                    
                }
            }
        }
    }
}

- (BOOL)shouldCancelForPoint:(CGPoint)point velocity:(CGPoint)velocity
{
    BOOL shouldCancel = YES;
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    if (point.y < viewFrame.size.height/2) {
        if (abs(velocity.y) > CREATE_NEW_VELOCITY_THRESHOLD) {
            shouldCancel = NO;
        }
    } else {
        shouldCancel = NO;
    }

    return shouldCancel;
}

/*
 -(void)deletePan:(UIPanGestureRecognizer *)gesture{ //animation for deleting the note with a two finger pan
 CGRect frame = [[UIScreen mainScreen] applicationFrame];
 CGPoint point = [gesture translationInView:self.view];
 if (gesture.state == UIGestureRecognizerStateBegan) {
 self.currentNoteViewController.textView.scrollEnabled = NO;
 [self.view bringSubviewToFront:self.sliceView];
 }
 
 if (gesture.state == UIGestureRecognizerStateChanged) { //while the pan gesture is still in action
 NSLog(@"gesturechanged %f", point.x);
 self.sliceView.frame = CGRectMake(point.x - self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height); //move the self.sliceView UIView with the slice Images to wherever the fingers are dragged
 
 }
 if (gesture.state == UIGestureRecognizerStateEnded) {
 if (point.x < self.view.frame.size.width/2) { //if user didn't pan past the half way point
 [UIView animateWithDuration:1.0
 animations:^(void){
 self.sliceView.frame = CGRectMake(-320, 0, self.view.frame.size.width, self.view.frame.size.height); //slowly animate the slice view back off screen
 }
 completion:^(BOOL finished){
 self.currentNoteViewController.view.hidden = NO; //and show the actual note again
 //self.screenShot.hidden = YES;
 }];
 }
 else{ //if user panned past the half way point
 [UIView animateWithDuration:0.5
 animations:^(void){
 self.sliceView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //complete the animation to "slice" the whole note
 }completion:^(BOOL finished){
 UIGraphicsBeginImageContext(CGSizeMake(self.view.frame.size.width, self.view.frame.size.height));
 CGContextRef context = UIGraphicsGetCurrentContext();
 [self.view.layer renderInContext:context]; //gets screenshot of the note
 //[self.sliceView.layer renderInContext:context]; //gets screenshot of the slice images
 UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext(); //saves both as one image
 UIGraphicsEndImageContext();
 self.slicedNoteScreenShot.image = viewImage;
 [self cropNote];
 [self walkThroughStepCheck:walkThroughStepDelete];
 }];
 
 }
 
 }
 }
 
 */

-(void)cropNote {
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    for (int i = 0; i < NUMBER_OF_SLICES; i++) {
        CGRect cropRect = CGRectMake(0, (frame.size.height*i)/NUMBER_OF_SLICES, 320, frame.size.height/NUMBER_OF_SLICES); //frame of the crop
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[self.slicedNoteScreenShot.image crop:cropRect]]; //crops note
        imageView.frame = CGRectMake(0, (frame.size.height*i)/NUMBER_OF_SLICES, self.view.frame.size.width, frame.size.height/NUMBER_OF_SLICES);
        [self.slicedNoteArray addObject:imageView];
    }
    
    for (UIImageView *imageView in [self.slicedNoteArray reverseObjectEnumerator]) {
        [self.view addSubview:imageView]; //adds the subview from the end of the array first so that when the sliced note falls...it falls in front of the other subviews...instead of behind
    }
    
    [self animateSlicedNoteFalling];
}

-(void)animateSlicedNoteFalling
{
   
    self.currentNoteViewController.view.hidden = YES;
    self.sliceView.frame = CGRectMake(-320, 0, self.view.frame.size.width, self.view.frame.size.height);
  
    int64_t delayInSeconds = 1.75;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self walkThroughStepCheck:walkThroughStepDelete];
    });
    [UIView animateWithDuration:2.0
                     animations:^(void){
                         for (UIImageView *iView in self.slicedNoteArray){ //iterates through every UIImageView in the array
                             iView.frame = CGRectMake([self randomXValue], 1000, iView.image.size.width, iView.image.size.height); //animates each view off screen at the same time...to a random x position
                             iView.transform = CGAffineTransformMakeRotation([self randomAngle]); //random rotation angle
                             
                         }
                         
                     } completion:^(BOOL finished){
                         for (UIImageView *imageView in [self.slicedNoteArray reverseObjectEnumerator]) {
                             [imageView removeFromSuperview]; //adds the subview from the end of the array first so that when the sliced note falls...it falls in front of the other subviews...instead of behind
                         }
                         
                         [self.view insertSubview:self.sliceView atIndex:0];
                         if ([[[ApplicationModel sharedInstance] currentNoteEntries] count] == 0) {
                             [self dismissViewControllerAnimated:NO completion:nil];
                         }
                     }];
    
    
    [self finishDeletingDocument:CGPointMake(0, 0)];
   
}

-(int)randomAngle{
    
    int lowerBound = -300;
    int upperBound = 300;
    int ranAngle = lowerBound + arc4random() % (upperBound - lowerBound);
    return ranAngle;
    
}

-(int)randomXValue{
    int lowerBound = -320;
    int upperBound = 320;
    int randomX = lowerBound + arc4random() % (upperBound - lowerBound);
    
    return randomX;
}

- (void)setNextNoteDocumentForVelocity:(CGPoint)velocity
{
    int noteCount = [[ApplicationModel sharedInstance].currentNoteEntries count];
    int xDirection = (velocity.x > 0) ? PREVIOUS_DIRECTION : NEXT_DIRECTION;
    
    NoteEntry *entryUnderneath;
    if (noteCount == 1) {
        self.nextNoteViewController.view.hidden = YES;
    } else {
        self.nextNoteViewController.view.hidden = NO;
        if (xDirection == PREVIOUS_DIRECTION) {
            entryUnderneath = self.previousNoteEntry;
        } else {
            entryUnderneath = self.nextNoteEntry;
        }
        self.nextNoteViewController.noteEntry = entryUnderneath;
    }
}

#pragma mark Note deletion

- (void)finishDeletingDocument:(CGPoint)point
{
    // shredding animations for deletion
    NoteDocument *doc = self.currentNoteViewController.noteDocument;
    UIDocumentState state = [doc documentState];

    NSLog(@"\n\nClosing doc %@, state was %i",doc.fileURL.lastPathComponent,state);
    //if ([doc hasUnsavedChanges]) {

    NSUndoManager *undoManager = [doc undoManager];
    [undoManager disableUndoRegistration];
    //}
    
    if (state != UIDocumentStateNormal) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Document not safe to delete" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        // optional - add more buttons:
        [alert addButtonWithTitle:@"Ok"];
        [alert show];
        
        return;
    }
    
    if (creatingNewNote) {
        NSLog(@"aha!");
    }
    
    [doc closeWithCompletionHandler:^(BOOL success) {
        UIDocumentState state = [doc documentState];
        if (success) {
            NSLog(@"\n\n\n**************\nClosed & deleted doc:\n%@, state was %i\n*****************\n\n",doc.fileURL.lastPathComponent,state);
            ApplicationModel *model = [ApplicationModel sharedInstance];
            NoteEntry *toDelete = currentNoteViewController.noteEntry;
            [self setGestureState:kGestureFinished];
            
            [slicedNoteScreenShot removeFromSuperview];
            self.currentNoteViewController.textView.scrollEnabled = YES;
            
            self.currentNoteViewController.view.hidden = NO;
            
            [model setCurrentNoteIndexToNextPriorToDelete];
            [[ApplicationModel sharedInstance] deleteNoteEntry:toDelete withCompletionBlock:^{
                //NSLog(@"selectedindex after delete: %i",model.selectedNoteIndex);
                //NSLog(@"\n\ncheck that note is GONE: %@\n\n",toDelete.fileURL.lastPathComponent);
            }];
            
            if (model.currentNoteEntries.count==0) {
                [self dismissViewControllerAnimated:NO completion:nil];
            } else {
                [self updateNoteDocumentsForIndex:model.selectedNoteIndex];
                [self setCurrentNoteToModel];
            }
        } else {
            NSLog(@"Couldn't close doc %@",self.currentNoteViewController.noteDocument.fileURL.lastPathComponent);
        }
        

    }];
    
    [self walkThroughStepCheck:walkThroughStepDelete];
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

- (void)handleCreationGestureForPoint:(CGPoint)point {
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    CGRect newFrame = CGRectMake(0, 0 + point.y, currentNoteFrame.size.width, currentNoteFrame.size.height);
    
    self.currentNoteViewController.view.frame = newFrame;
}

- (void)handleSingleTouchPanChangedForPoint:(CGPoint)point
{
    // move the current note vc with the touch location
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    CGRect newFrame = CGRectMake(0 + point.x, 0, currentNoteFrame.size.width, currentNoteFrame.size.height);
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    
    self.currentNoteViewController.view.frame = newFrame;
    NoteEntry *entryUnderneath = nil;
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    int noteCount = [model.currentNoteEntries count];
    if (noteCount > 1) {
        
        // if user has moved it far enough to what's behind on the left side
        if (currentNoteFrame.origin.x + currentNoteFrame.size.width > viewFrame.size.width) {
            entryUnderneath = self.previousNoteEntry;
            self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
            self.nextNoteViewController.noteEntry = entryUnderneath;
            // else if user has moved it far enough to what's behind on the right side
        } else if (currentNoteFrame.origin.x < viewFrame.origin.x) {
            entryUnderneath = self.nextNoteEntry;
            self.nextNoteViewController.view.hidden = (entryUnderneath == nil);
            self.nextNoteViewController.noteEntry = entryUnderneath;
        }
    }
}

- (void)handleSingleTouchPanEndedForVelocity:(CGPoint)velocity
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    int noteCount = [[ApplicationModel sharedInstance].currentNoteEntries count];
    [self setGestureState:kGestureFinished];
    if (noteCount==1) { //if there's only one note then don't allow them to change views when panning...snaps back
        [self snapBackCurrentNote];
        return;
    }
    if (currentNoteFrame.origin.x > viewFrame.size.width/2 || velocity.x > FLIP_VELOCITY_THRESHOLD) { //if the user panned and dragged the page to more than half of the screen
        [self walkThroughStepCheck:walkThroughStepCycle];
        [self animateCurrentOutToRight];
    } else if (currentNoteFrame.origin.x + currentNoteFrame.size.width < viewFrame.size.width/2 || velocity.x < -FLIP_VELOCITY_THRESHOLD) {
        [self walkThroughStepCheck:walkThroughStepCycle];
        [self animateCurrentOutToLeft];
    } else { // if the user didn't drag the note past half the screen then snap back
        
        [self snapBackCurrentNote];
    }
    
}

#pragma mark Walk-through

- (void)walkThroughStepCheck:(int)stepNum
{
    if (_currentTourStep) {
        int index = [[_currentTourStep objectForKey:@"index"] intValue];
        if (index == stepNum) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWalkThroughStepComplete object:nil userInfo:_currentTourStep];
        } 
    }
}

- (void)beginTouchDemoAnimation
{
    [self endTouchDemoAnimation];
    
    walkthroughGestureTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(runGestureDemoForWalkthroughStep:) userInfo:[_currentTourStep objectForKey:@"index"] repeats:YES];
    [walkthroughGestureTimer fire];
}

- (void)endTouchDemoAnimation
{
    if (walkthroughGestureTimer) {
        [walkthroughGestureTimer invalidate];
        walkthroughGestureTimer = nil;
    }
    
    [[self.view viewWithTag:kFingerTipsTag] removeFromSuperview];
}

- (void)runGestureDemoForWalkthroughStep:(NSTimer *)timer
{
    NSNumber *step = timer.userInfo;
    int stepNum = step.intValue;
    
    float width = 60.0;
    float padding = 10.0;
    float circleRadius = 25.0;
    
    UIView *container = [self.view viewWithTag:kFingerTipsTag];
    if (container) {
        [container removeFromSuperview];
    }
    
    container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 60.0)];;    
    [container setTag:kFingerTipsTag];
    
    CGRect viewFrame = self.view.frame;
    
    UIImageView *circle1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fingertip"]];
    UIImageView *circle2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fingertip"]];
    
    switch (stepNum) {
        case walkThroughStepCreate1:
        case walkThroughStepCreate2:
        {
            [self.view addSubview:container];
            [circle1 setFrame:CGRectMake(0.0, 0.0, circleRadius, circleRadius)];
            [container setFrame:CGRectMake((viewFrame.size.width - container.frame.size.width)*0.5, 15.0, circleRadius, circleRadius)];
            float yTranslate = viewFrame.size.height - 185.0;
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [container setFrameY:yTranslate];
                             }
                             completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.5 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState
                                                  animations:^{
                                                      [container setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
                                                      [container setAlpha:0.0];
                                                  }
                                                  completion:^(BOOL finished){
                                                      [container removeFromSuperview];
                                                  }];
                                 
                             }];
        }
            break;
        case walkThroughStepCycle:
        {
            [self.view addSubview:container];
            [circle1 setFrame:CGRectMake(0.0, 0.0, circleRadius, circleRadius)];
            [container setFrame:CGRectMake(padding, 120.0, width, 60.0)];
            [UIView animateWithDuration:0.8
                             animations:^{
                                 [container setTransform:CGAffineTransformMakeTranslation(viewFrame.size.width - container.frame.size.width - padding, 0.0)];
                                 [container setAlpha:0.0];
                             }
                             completion:^(BOOL finished){
                                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC);
                                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                     [container setAlpha:1.0];
                                     [UIView animateWithDuration:0.8 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                                         [container setTransform:CGAffineTransformMakeTranslation(padding, 10.0)];
                                         [container setAlpha:0.0];
                                     } completion:^(BOOL finished){
                                         [container removeFromSuperview];
                                     }];
                                 });
                                 
                             }];
        }
            break;
        case walkThroughStepDelete:
        {
            [self.view addSubview:container];
            [container addSubview:circle2];
            [circle1 setFrame:CGRectMake(0.0, 0.0, circleRadius, circleRadius)];
            [circle2 setFrame:CGRectMake(10.0, 35.0, circleRadius, circleRadius)];
            [container setFrame:CGRectMake(padding, (viewFrame.size.height - 60.0)*0.5-20.0, width, 60.0)];
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [container setTransform:CGAffineTransformMakeTranslation(viewFrame.size.width - container.frame.size.width - padding, 0.0)];
                                 [container setAlpha:0.0];
                             }
                             completion:^(BOOL finished){
                                 [container removeFromSuperview];
                             }];
        }
            break;
        case walkThroughStepGoToList:
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [self.view addSubview:container];
                float walkthroughHeight = 135;
                [container addSubview:circle2];
                [circle1 setFrame:CGRectMake(0.0, 0.0, circleRadius, circleRadius)];
                float height = viewFrame.size.height - walkthroughHeight - 15.0;
                [circle2 setFrame:CGRectMake(7.0, height - circleRadius, circleRadius, circleRadius)];
                [container setFrame:CGRectMake((viewFrame.size.width - container.frame.size.width)*0.5, 10.0, width, height)];
                [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     [circle1 setFrameY:height*0.5-20.0];
                                     [circle2 setFrameY:height*0.5+20.0];
                                     [container setAlpha:0.08];
                                 }
                                 completion:^(BOOL finished){
                                     [container removeFromSuperview];
                                 }];
                
            });
        }
            break;
        default:
            return;
            break;
    }
    
    [container addSubview:circle1];
    
}

- (BOOL)walkthroughShouldBlockForStep:(UserSteps)step
{
    if (!_currentTourStep) {
        return NO;
    }
    
    if ([[_currentTourStep objectForKey:@"index"] intValue] != step) {
        return YES;
    }
    
    return NO;
}

#pragma mark New Note

- (void)finishCreatingNewDocumentWithVelocity:(CGPoint)velocity
{
    creatingNewNote = YES;
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model setSelectedNoteIndex:0];
    
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect currentFrame = self.currentNoteViewController.view.frame;
    CGFloat velocityY = velocity.y;
    CGFloat pointsY = abs(currentFrame.origin.y);
    NSTimeInterval duration = pointsY / velocityY;
    if (duration < 0.0) {
        duration = DURATION;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.currentNoteViewController.view.frame = CGRectMake(0.0, viewFrame.size.height, currentFrame.size.width, currentFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         [self.view addSubview:self.currentNoteViewController.view];
                         self.currentNoteViewController.view.hidden = NO;
                     }];
    
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        
        dispatch_sync(concurrentQueue, ^{

            if (_currentTourStep) {
                int index = [[_currentTourStep objectForKey:@"index"] intValue];
                NSString *text = index == walkThroughStepCreate1 ? @"My first note" : @"";
                text = index == walkThroughStepCreate2 ? @"My second note" : text;
                [model createNoteWithText:text andCompletionBlock:^(NoteEntry *doc){
                    if (!doc.adding) {
                        [self openNewNoteDocument];
                    } else {
                        NSLog(@"note as adding, did not update UI! [%i]",__LINE__);
                    }
                }];
            } else {
                [model createNoteWithCompletionBlock:^(NoteEntry *doc){
                    if (!doc.adding) {
                        [self openNewNoteDocument];
                    } else {
                        NSLog(@"note as adding, did not update UI! [%i]",__LINE__);
                    }
                }];
            }

        });
        
        dispatch_sync(dispatch_get_main_queue(), ^{

            if (model.currentNoteEntries.count == 2) {
                [self walkThroughStepCheck:walkThroughStepCreate1];
            } else if (model.currentNoteEntries.count == 3) {
                [self walkThroughStepCheck:walkThroughStepCreate2];
            }
            
            [self.delegate indexDidChange];
            [self setGestureState:kGestureFinished];
        });
        
    });

}

- (void)openNewNoteDocument
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model noteDocumentAtIndex:model.selectedNoteIndex completion:^(NoteDocument *doc){
        self.currentNoteViewController.noteDocument = doc;
        NSLog(@"\n\nOpened brand new doc and set as current %@",self.currentNoteViewController.noteDocument.fileURL.lastPathComponent);
        
        if (creatingNewNote == YES) {
            creatingNewNote = NO;
        }
    }];
    [self updateNoteDocumentsForIndex:0];
    [self setCurrentNoteToModel];
}

- (void)animateCurrentOutToLeft
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
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
                             [self setCurrentNoteToModel];
                         }
                     }];
}

- (void)animateCurrentOutToRight
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
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

- (void)updatePositionOfNextDocumentToPoint:(CGPoint)point {
    float offset = point.y;
    
    float newNoteViewOffset;
    float newNoteOffset;
    float currentNoteOffset = offset >= 0 ? offset : 0;
    
    if (offset <= 40 && offset >= 0) {
        newNoteOffset = offset;
        newNoteViewOffset = offset;
    }
    else if (offset <= 80) {
        newNoteOffset = 40 - (offset - 40);
        newNoteViewOffset = 40;
    }
    else {
        newNoteOffset = 0;
        newNoteViewOffset = 40;
    }
    
    if (offset >= 40) {
        self.addNoteLabel.text = @"Release to create a new note.";
    }
    else {
        self.addNoteLabel.text = @"Pull to create a new note.";
    }
    
    CGRect newNoteViewFrame = self.addNoteView.frame;
    CGRect newNoteFrame = self.nextNoteViewController.view.frame;
    CGRect currentNoteFrame = self.currentNoteViewController.view.frame;
    
    CGRect newNoteViewUpdatedFrame = CGRectMake(0, -40 + newNoteViewOffset, newNoteViewFrame.size.width, newNoteViewFrame.size.height);
    CGRect newNoteUpdatedFrame = CGRectMake(0.0, 0 + newNoteOffset, newNoteFrame.size.width, newNoteFrame.size.height);
    CGRect currentNoteUpdatedFrame = CGRectMake(0.0, 0 + currentNoteOffset, currentNoteFrame.size.width, currentNoteFrame.size.height);
    
    self.addNoteView.frame = newNoteViewUpdatedFrame;
    self.nextNoteViewController.view.frame = newNoteUpdatedFrame;
    self.currentNoteViewController.view.frame = currentNoteUpdatedFrame;
    
    [self.view bringSubviewToFront:self.currentNoteViewController.view];
}

- (void)createDeletingViews //deletes the note from two finger right pan
{
    deletingViews = [NSMutableArray new];
    
    screenShot = [[UIImageView alloc] initWithImage:[self imageForDocument:self.currentNoteViewController.noteEntry]]; //gets current screenshot and sets it as a UIImage
    screenShot.frame = CGRectMake(0, 0, screenShot.image.size.width, screenShot.image.size.height);
    [self.view addSubview:screenShot];
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Create and show the new image from bitmap data
   /* for (int k = 0; k <= numberOfTouchesInCurrentPanGesture; k++) {
        // Create rectangle that represents a cropped image
        // from the middle of the existing image
        CGRect cropRect = CGRectMake(0, (480*k)/(numberOfTouchesInCurrentPanGesture+1), 320, 480/(numberOfTouchesInCurrentPanGesture+1));
        
        // Create and show the new image from bitmap data
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[viewImage.image crop:cropRect]];
        imageView.frame = CGRectMake(0, 0, 320, 480/(numberOfTouchesInCurrentPanGesture+1)); //this is the frame of each individual shredded note
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
    }*/
    
    /*for (int i = 0; i < 10; i++) {
        CGRect cropRect = CGRectMake(0, (480*i)/10, 320, 48);
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[viewImage crop:cropRect]];
        imageView.frame = CGRectMake(0, 0, 320, 48);
        [deletingViews addObject:imageView];
        imageView.hidden = NO;
        
        imageView.layer.shadowColor = [[UIColor blackColor] CGColor];
        imageView.layer.shadowOffset = CGSizeMake(-1,-2);
        imageView.layer.shadowOpacity = .70;
        imageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        imageView.layer.shouldRasterize = YES;
        [imageView.layer setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:imageView.bounds cornerRadius:6.5] CGPath]];
        imageView.layer.cornerRadius = 6.5;
        
        [self.view addSubview:imageView];
     
    }*/
    
    
}

/*
 - (void)animateDeletingViewsForPoint:(CGPoint)point withRecgonizer:(UIPanGestureRecognizer *)gesture
 {
 
 for (int k = 0; k < [deletingViews count]; k++) {
 double middle = deletingViews.count/2.0; // 1.5 for now
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
 */

- (void)snapBackCurrentNote
{
    // snap back
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
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
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.nextNoteViewController.view.frame = CGRectMake(0.0, -(viewFrame.size.height), viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL complete){
                         self.nextNoteViewController.view.frame = viewFrame;
                         [self.view addSubview:currentNoteViewController.view];
                         [self.nextNoteViewController setWithPlaceholderData:NO defaultData:nil];
                     }];
}

- (void)slideOffCurrentNoteToLeftWithCompletion:(void(^)())completion
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
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

/*
 - (void)popToNoteList:(int)index
 {
 self.dismissBlock([_stackVC finalYOriginForCurrentNote]);
 [self dismissViewControllerAnimated:YES completion:nil];
 }
 */

- (void)updateNoteDocumentsForIndex:(NSUInteger)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    int count = [model currentNoteEntries].count;
    if (count == 0) {
        [self showNewNote];
    }
    
    self.previousNoteEntry = [model previousNoteInStackFromIndex:index];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:index];
    
    NoteEntry *entryToShow = [model noteAtIndex:index];
        
    [self.currentNoteViewController setNoteEntry:entryToShow];
    [self.currentNoteViewController.view setNeedsDisplay];
    self.currentNoteViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.delegate indexDidChange];
}

- (void)showNewNote
{
    // don't allow zero notes
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSString *text = @"Back to square one. Write something!";
    [model createNoteWithText:text andCompletionBlock:^(NoteEntry *doc){
        if (!doc.adding) {
            [self updateNoteDocumentsForIndex:0];
            [self setCurrentNoteToModel];
        }
    }];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_currentGestureState == kStackingPinch) {
        return;
    }
    
    if(!self.optionsViewController.view.hidden) { //if it's on the options screen
        // find the element that is being touched, if any.
        CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        CGRect frame = self.overView.frame;
        if(!CGRectContainsPoint(frame, currentLocation)) {
            //NSLog(@"touch options panel");
        } else {
            
            [self shiftCurrentNoteOriginToPoint:CGPointMake(0, 0) completion:^{
                [self.optionsViewController reset];
            }];
            //NSLog(@"touched outside of options");
        }
    }
}

#pragma mark OptionsViewController Delegate

-(void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor {
    [self.currentNoteViewController setColors:color textColor:textColor];
}

- (void)showOptions
{
    if ([self walkthroughShouldBlockForStep:walkThroughStepOptions]) {
        return;
    }
    
    [self.currentNoteViewController.textView resignFirstResponder];
    [self shiftCurrentNoteOriginToPoint:CGPointMake(96, 0) completion:nil];
    [self walkThroughStepCheck:walkThroughStepOptions];
}

-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point completion:(void(^)())completionBlock //shifts current note to only partially show on screen
{
    if (point.x != 0) {
        self.optionsViewController.view.hidden = NO;
        [self.view setBackgroundColor:[UIColor blackColor]];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    
    [self.currentNoteViewController.textView resignFirstResponder];
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
                         self.currentNoteViewController.view.frame = CGRectMake(point.x, self.currentNoteViewController.view.frame.origin.y, appFrame.size.width, appFrame.size.height);
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
    
    [self.view removeGestureRecognizer:self.panGestureRecognizer];
    
    
}
- (void) shiftViewDownAfterKeyboard:(NSNotification*)theNotification;
{
    // Step 1: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.currentNoteViewController.textView.contentInset = contentInsets;
    self.currentNoteViewController.textView.scrollIndicatorInsets = contentInsets;
    
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
}


- (void)textfieldWasSelected:(NSNotification *)notification {
    self.currentNoteViewController.textView = notification.object;
}

- (void)keyboardWillShow:(NSNotification *)notification {

    keyboard.hidden = NO;
}




- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.currentNoteViewController.textView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - kbSize.height); //sets the size of the scrolling textview equal to the height of the whole screen minus the height of the keyboard
    
    if(keyboard) return;
    
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1]; ///makes uiview "keyboard" into the uikeyboard some how.. i don't know how lol
    for(int i = 0; i < [tempWindow.subviews count]; i++) {
        UIView *possibleKeyboard = [tempWindow.subviews objectAtIndex:i];
        if([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES){
            keyboard = possibleKeyboard;
            return;
        }
    }
}

-(void)keyboardDismissed{
    self.currentNoteViewController.textView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //resets the height of the textview to the full height of the screen
}

-(void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer { //pan gesture recogizer for keyboard animation
    CGPoint location = [gestureRecognizer locationInView:[self view]];
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan){
        originalKeyboardY = keyboard.frame.origin.y;
    }
    
    if(gestureRecognizer.state == UIGestureRecognizerStateEnded){
        if (velocity.y > 0 && location.y <= keyboard.frame.origin.y) { //if panning down then call method to animate keyboard off the screen. only animates if user pans past keyboard...so scrolling the note doesnt dismiss the keybaord
            [self animateKeyboardOffscreen];
        }else{ //if panning up then call method to animate keyboard back on the screen
            [self animateKeyboardReturnToOriginalPosition];
        }
        return; //leaves this method if gesture ended if not continue below
    }
    
    CGFloat spaceAboveKeyboard = self.view.bounds.size.height - (keyboard.frame.size.height);
    if (location.y < spaceAboveKeyboard) {
        return; //return if touch is the keyboard or below
    }
    
    CGRect newFrame = keyboard.frame;
    CGFloat newY = originalKeyboardY + (location.y - spaceAboveKeyboard);
    newY = MAX(newY, originalKeyboardY);
    newFrame.origin.y = newY;
    [keyboard setFrame: newFrame];
    
    
    if (location.y >= keyboard.frame.origin.y) { //make sure the touch is at or below where the keyboard is
        CGRect textFrame = self.view.frame;
        textFrame.size.height = location.y; //changes the height of the textbox to the y value of the location of the touch/pan
        [self.currentNoteViewController.textView setFrame:textFrame];
    }
    
    
    
}

- (void)animateKeyboardOffscreen { //slowly animates the keyboard off screen if the user lets go of the touch/pan
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect newFrame = keyboard.frame;
                         //CGFloat newY = CGRectGetMaxY(keyboard.window.frame); // unused variable
                         newFrame.origin.y = keyboard.window.frame.size.height;
                         [keyboard setFrame: newFrame];
                         //CGRect aFrame = self.view.frame; // unused variable
                         //self.currentNoteViewController.textView.frame = self.view.frame;

                     }
     
                     completion:^(BOOL finished){
                         keyboard.hidden = YES;
                         [self.currentNoteViewController.textView resignFirstResponder];
                     }];
}

- (void)animateKeyboardReturnToOriginalPosition { //brings keyboard back on screen if user pans up
    [UIView beginAnimations:nil context:NULL];
    CGRect newFrame = keyboard.frame;
    newFrame.origin.y = originalKeyboardY;
    [keyboard setFrame: newFrame];
    self.currentNoteViewController.textView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - keyboard.frame.size.height); ///sets the height of the textbox to the height of the screen minus the hieght of the keyboard so the user cannot type underneath the keybaordd
    [UIView commitAnimations];
}


- (void)configureKeyboard
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textfieldWasSelected:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDismissed) name:UIKeyboardWillHideNotification object:nil];

    
    BOOL useSystem = YES; //[[NSUserDefaults standardUserDefaults] boolForKey:USE_STANDARD_SYSTEM_KEYBOARD]; //user option to use standard or custom keyboard. switch button in options view. for now......system keyboard only
    if (!useSystem) { //custom keyboard
        
        if (!self.keyboardViewController) {
            self.keyboardViewController = [[KeyboardViewController alloc] initWithNibName:@"KeyboardViewController" bundle:nil];
        }
        
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
        
        self.currentNoteViewController.textView.inputView = self.keyboardViewController.view;
        
        
    } else { //system keyboard

        self.currentNoteViewController.textView.inputView = nil;
        [self.currentNoteViewController.textView setKeyboardAppearance:UIKeyboardAppearanceAlert];
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
        //panRecognizer.delegate = self;
        [self.view addGestureRecognizer:panRecognizer];

    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidHideNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        [self.view addGestureRecognizer:self.panGestureRecognizer];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        
        [self.view removeGestureRecognizer:self.panGestureRecognizer];
    }];
    
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
        if (isALetterTwoAgo && [lastCharacter isEqualToString:@" "]){ //inserts period after pressing spacebar twice
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

- (void)didUpdateModel
{
    [_stackVC updateNoteText];
}

#pragma mark OptionsViewDelegate

- (void)sendEmail
{
    self.mailVC = [[MFMailComposeViewController alloc] init];
    
    if (!self.mailVC) {
        //
    }
    
    self.mailVC.mailComposeDelegate = self;
    
    NSArray* lines = [[ApplicationModel sharedInstance].noteAtSelectedNoteIndex.text componentsSeparatedByString: @"\n"];
    NSString* noteTitle = [lines objectAtIndex:0];
    NSString *body = [[NSString alloc] initWithFormat:@"%@\n\n%@",[self getNoteTextAsMessage],@"Sent from Noted"];
	[self.mailVC setSubject:noteTitle];
	[self.mailVC setMessageBody:body isHTML:NO];
    [self presentViewController:self.mailVC animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)getNoteTextAsMessage
{
    NSString *noteText = [ApplicationModel sharedInstance].noteAtSelectedNoteIndex.text;
    noteText = [noteText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if ([noteText length] > 140) {
        noteText = [noteText substringToIndex:140];
    }
    return noteText;
}

- (void)sendTweet
{
    NSString *noteText = [self getNoteTextAsMessage];
    
    if (SYSTEM_VERSION_LESS_THAN(@"6")){
        if([TWTweetComposeViewController canSendTweet])
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            [tweetViewController setInitialText:noteText];
            
            tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result)
            {
                // Dismiss the controller
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            [self presentViewController:tweetViewController animated:YES completion:nil];
            
        }else {
            NSString * message = [NSString stringWithFormat:@"This device is currently not configured to send tweets."];
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6")) {
        // 3
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            // 4
            //[self.tweetText setAlpha:0.5f];
        } else {
            // 5
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [composeViewController setInitialText:noteText];
            [self presentViewController:composeViewController animated:YES completion:nil];
        }
    }

}

- (void)sendSMS
{
    if([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        messageViewController.body = [self getNoteTextAsMessage];
        messageViewController.messageComposeDelegate = self;
        messageViewController.wantsFullScreenLayout = NO;
        [self presentViewController:messageViewController animated:YES completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    else {
        NSString * message = [NSString stringWithFormat:@"This device is currently not configured to send text messages."];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}







@end
