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
#import "StackViewController.h"
#import "NoteEntryCell.h"

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
static const float kSectionZeroHeight = 44.0;
static const float kPinchDistanceCompleteThreshold = 130.0;

@interface NoteStackViewController () {
    
    int numberOfTouchesInCurrentPanGesture;
    BOOL optionsShowing;
    
    NSMutableArray *deletingViews;
    
    NSInteger _currentNoteIndex;
    
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
    StackViewController *_stackVC;
    
    float totalHeight;
    CGFloat pinchYTarget;
    CGFloat pinchDistance;
    CGFloat pinchVelocity;
    
    float adjustedScale;
    float pinchPercentComplete;
    CGFloat initialPinchDistance;
}

@property (strong,nonatomic)MFMailComposeViewController *mailVC;
@property (strong,nonatomic)MFMessageComposeViewController *messageVC;

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

- (id)initWithDismissalBlock:(TMDismissalBlock)dismiss andStackVC:(StackViewController *)stackVC
{
    self = [super initWithNibName:@"NoteStackViewController" bundle:nil];
    if (self){
        _dismissBlock = dismiss;
        _stackVC = stackVC;
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
    
    totalHeight = self.view.bounds.size.height - kSectionZeroHeight;
    initialPinchDistance = 0.0;
    self.view.layer.cornerRadius = kCornerRadius;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNoteListChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note){
        // if user changes storage settings while viewing this screen
        [self presentNotes];
    
    }];
    
    self.currentNoteViewController = [[NoteViewController alloc] init];
    self.currentNoteViewController.delegate = self;
    [self.view addSubview:self.currentNoteViewController.view];
    
    [self configureKeyboard];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"keyboardSettingChanged" object:nil queue:nil usingBlock:^(NSNotification *note){
        [self configureKeyboard];
    }];
  
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
    
    [self setCurrentNoteToModel];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"didToggleStatusBar" object:nil queue:nil usingBlock:^(NSNotification *note){
        
        CGRect newFrame =  [[UIScreen mainScreen] applicationFrame];
        newFrame.origin.x = self.currentNoteViewController.view.frame.origin.x;
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.currentNoteViewController.view.frame = newFrame;
                             self.nextNoteViewController.view.frame = newFrame;
                         }
                         completion:^(BOOL finished){
                             NSLog(@"finished animating");
                         }];
    }];
    
}

// on first view of note as well as right after creating note by pan getsure
- (void)setCurrentNoteToModel
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [self.currentNoteViewController setNoteEntry:[model noteAtSelectedNoteIndex]];
    self.currentNoteViewController.noteDocument = [model noteDocumentAtIndex:model.selectedNoteIndex completion:^{
        NSLog(@"now you can save changes using undo/redo");
    }];
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
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSUInteger currentIndex = model.selectedNoteIndex;
    self.previousNoteEntry = [model previousNoteInStackFromIndex:currentIndex];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:currentIndex];
    
    [self setUpRangeForStacking];
    [self.view addSubview:_stackVC.view];
}

- (void)popAndFormatCurrentTextFieldForParentView:(UIView *)parentView
{
    UITextView *textField = self.currentNoteViewController.textView;
    
    [parentView addSubview:textField];
    
    if ([parentView isKindOfClass:[NoteEntryCell class]]) {
        CGRect frame = textField.frame;
        UILabel *subtitle = [(NoteEntryCell *)_currentNote subtitleLabel];
        [subtitle setHidden:YES];
        frame.origin.y = subtitle.frame.origin.y - 29.0;
        frame.origin.x = subtitle.frame.origin.x - 8.0;
        textField.frame = frame;
        
    } else  {
        
        textField.frame = CGRectMake(0.0, 0.0, 320.0, 460.0);
        textField.text = [[ApplicationModel sharedInstance] noteAtSelectedNoteIndex].text;
    }
    
}

#pragma mark Pinch gesture to collapse notes stack

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    [self.currentNoteViewController.textView resignFirstResponder];
    
    CGFloat scale = gesture.scale;
    adjustedScale = [self adjustedScaleForPinch:scale];
        
    pinchYTarget = [gesture locationInView:self.view].y;
    pinchVelocity = gesture.velocity;
    
    //NSLog(@"velocity: %f",pinchVelocity);
    
    if ([gesture numberOfTouches] == 2 && _currentGestureState==kStackingPinch) {
        CGPoint p1 = [gesture locationOfTouch:0 inView:self.view];
        CGPoint p2 = [gesture locationOfTouch:1 inView:self.view];
        
        // Compute the new spread distance.
        CGFloat xd = p1.x - p2.x;
        CGFloat yd = p1.y - p2.y;
        pinchDistance = sqrt(xd*xd + yd*yd);
        
        if (initialPinchDistance==0.0) {
            initialPinchDistance = pinchDistance;
        }
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
                
        [_stackVC.view setFrameX:0.0];
        [self setGestureState:kStackingPinch];
        [self.view.layer setCornerRadius:kCornerRadius];
        [self.view setClipsToBounds:YES];
        [self animateCurrentNoteWithScale:scale];
        //[self.currentNoteViewController setWithNoDataTemp:YES];
        [self popAndFormatCurrentTextFieldForParentView:_currentNote];
        [self animateCurrentNoteWithScale:scale];
        [self animateStackedNotesForScale:scale];
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        [self animateCurrentNoteWithScale:scale];
        [self animateStackedNotesForScale:scale];
        
        pinchPercentComplete = (initialPinchDistance-pinchDistance)/(initialPinchDistance-kPinchDistanceCompleteThreshold);
        if (pinchPercentComplete>=1.0) {
            pinchPercentComplete = 1.0;
            pinchComplete = YES;
        } else if (pinchPercentComplete<0.0) {
            pinchPercentComplete = 0.0;
        } else {
            pinchComplete = NO;
        }
        
        // a strong pinch should finish things immediately
        if (pinchVelocity < -0.8 && pinchComplete) {
            [self.view setUserInteractionEnabled:NO];
            [self finishPinch];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        
        if (pinchComplete) {
            [self finishPinch];
            
        } else {
            [_stackVC resetToExpanded:^{
                [self popAndFormatCurrentTextFieldForParentView:self.currentNoteViewController.view];
                [self.currentNoteViewController setWithNoDataTemp:NO];
            }];
            
        }
        
        [self setGestureState:kGestureFinished];
    }
}

- (void)finishPinch
{
    void(^wrapUp)() = ^{
        
        [self.view setUserInteractionEnabled:YES];
        initialPinchDistance = 0.0;
        _currentGestureState = kGestureFinished;
        [self.currentNoteViewController setWithNoDataTemp:NO];
        self.dismissBlock(_currentNoteIndex,[self finalYOriginForCurrentNote]);
        [self dismissViewControllerAnimated:NO completion:nil];
        //[self popAndFormatCurrentTextFieldForParentView:self.currentNoteViewController.view];
        [_stackVC.view setFrameX:-320.0];
        
    };
    
    [self finishCenterNoteAnimationWithCompleteBlock:^{
        wrapUp();
    }];
    
}

- (double)adjustedScaleForPinch:(CGFloat)scale
{
    float newScale = 1.0 - pinchPercentComplete;
    if (newScale<=0.0) {
        newScale = 0.0;
    }
    
    return 1.0 - pinchPercentComplete;
}


#pragma mark Stacked notes animations

- (void)animateStackedNotesForScale:(CGFloat)scale
{
    for (int i = 0; i < stackingViews.count; i ++) {
        [self animateStackedNoteAtIndex:i withScale:scale];
    }
}

- (void)animateCurrentNoteWithScale:(CGFloat)scale
{
    float minusAmount = self.view.bounds.size.height-kCellHeight;
    float newHeight = self.view.bounds.size.height-(minusAmount*pinchPercentComplete);
    BOOL isLast = [_stackVC indexOfNoteView:_currentNote]==[self documentCount]-1;
    BOOL isFirst = [_stackVC indexOfNoteView:_currentNote]==0;
    //NSLog(@"Is first: %s, is last: %s",isFirst ? "YES" : "NO",isLast ? "YES" : "NO");
        
    [self updateSubviewsForNote:_currentNote scaled:YES];
    
    centerNoteFrame = CGRectMake(0.0, (self.view.bounds.size.height-newHeight)*0.5, 320.0, newHeight);
    
    [_currentNote setFrame:centerNoteFrame];
}

- (void)animateStackedNoteAtIndex:(int)index withScale:(CGFloat)scale
{
    NSDictionary *noteDict = [stackingViews objectAtIndex:index];
    
    UIView *note = [noteDict objectForKey:@"noteView"];
    BOOL isLast = [_stackVC indexOfNoteView:note]==[self documentCount]-1;
    BOOL isFirst = [_stackVC indexOfNoteView:note]==0;
    NSLog(@"Is first: %s, is last: %s",isFirst ? "YES" : "NO",isLast ? "YES" : "NO");
    
    int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
    int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - stackingIndex);
    float currentNoteOffset = 0.0;
    

    float newHeight = kCellHeight;
    float newY = 0.0;
    if (offset<0) {
        currentNoteOffset = offset*kCellHeight;
        newY = CGRectGetMinY(_currentNote.frame) + currentNoteOffset;
    
    } else if (offset>0) {
        currentNoteOffset = CGRectGetMaxY(_currentNote.frame) + (offset-1)*kCellHeight;
        newY = currentNoteOffset;
        newHeight = self.view.bounds.size.height-CGRectGetMaxY(_currentNote.frame);
        NSLog(@"Note with offset %d getting set to y Origin of %f (%f + (%d-1)*kCellHeight)",offset,newY,CGRectGetMaxY(_currentNote.frame),offset);
    }
    
    CGRect newFrame = CGRectMake(0.0, floorf(newY), 320.0, newHeight);
    
    [self updateSubviewsForNote:note scaled:YES];
     
    [note setFrame:newFrame];
}

- (float)finalYOriginForCurrentNote
{
    float finalY = (self.view.bounds.size.height-kCellHeight)*0.5;
    
    return finalY;
}

- (float)displayFloat:(float)val
{
    NSString *newVal = [NSString stringWithFormat:@"%0.2f",val];
    return [newVal floatValue];
}

static const float circleXStart = 285.0;
static const float circleOffset = 20.0;
static const float labelStart = 135.0;
static const float labelOffset = 24.0;

- (void)updateSubviewsForNote:(UIView *)note scaled:(BOOL)scaled
{
    UIView *littleCircle = [note viewWithTag:78];
    
    if (!scaled) {
        
        littleCircle.alpha = 0.0;
        return;
    }
    
    littleCircle.alpha = 1.0-(pinchPercentComplete*1.1);
}

- (void)finishCenterNoteAnimationWithCompleteBlock:(void(^)())complete
{
    //BOOL done = _currentNote.frame.size.height==kCellHeight || pinchPercentComplete==1.0;
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         float currentNoteY = (self.view.bounds.size.height-kCellHeight)*0.5;
                         centerNoteFrame = CGRectMake(0.0, currentNoteY, 320.0, kCellHeight);
                         [_currentNote setFrame:centerNoteFrame];
                         
                         for (int i = 0; i < stackingViews.count; i ++) {
                             NSDictionary *noteDict = [stackingViews objectAtIndex:i];
                             
                             UIView *note = [noteDict objectForKey:@"noteView"];
                             int stackingIndex = [[noteDict objectForKey:@"index"] intValue];
                             
                             int offset = -([ApplicationModel sharedInstance].selectedNoteIndex - stackingIndex);
                             
                             float newHeight = kCellHeight;
                             float newY = 0.0;
                             if (offset < 0) {
                                 float finalCY = [self finalYOriginForCurrentNote];
                                 float balh = offset*kCellHeight;
                                 newY = finalCY + balh;
                                 
                             } else if (offset>0) {
                                 newHeight = self.view.bounds.size.height-CGRectGetMaxY(_currentNote.frame);
                                 newY = (CGRectGetMaxY(centerNoteFrame))+((offset-1)*kCellHeight);
                             }
                             
                             CGRect newFrame = CGRectMake(0.0, newY, 320.0, newHeight);
                             [note setFrame:newFrame];
                         }
                     }
                     completion:^(BOOL finished){
                         complete();
                         
                     }];
}

#pragma mark Stacked note views setup

static const float kCellHeight = 66.0;
static const float kAverageMinimumDistanceBetweenTouches = 110.0;

- (int)documentCount
{
    return [[ApplicationModel sharedInstance] currentNoteEntries].count;
}

- (void)setUpRangeForStacking
{
    if (stackingViews) {
        [stackingViews removeAllObjects];
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    _currentNoteIndex = model.selectedNoteIndex;//[[model currentNoteEntries] indexOfObject:self.currentNoteViewController.noteEntry];
    NSLog(@"%d",_currentNoteIndex);
	
    NSRange range = [self stackedNotesRange];
    NSLog(@"Stack notes from %d to %d",range.location,range.length);
    
    [self makeCurrentNote];

    stackingViews = [[NSMutableArray alloc] initWithCapacity:range.length];
    int stackingIndex = 0;
    for (int i = range.location; i < range.length; i++) {
        
        if (i == _currentNoteIndex) {
            // skip the current doc
            stackingIndex++;
            continue;
        }

        /*
         ApplicationModel *model = [ApplicationModel sharedInstance];
         int offset = -(float)(model.selectedNoteIndex - stackingIndex);
         NSLog(@"i is %d, offset for getting view from stackvc is %d",i,offset);
         if (![_stackVC viewAtIndex:stackingIndex]) {
         NSLog(@"Couldn't find view for index %d",stackingIndex);
         }
         */

        UIView *noteView = [_stackVC viewAtIndex:stackingIndex];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:noteView,@"noteView",[NSNumber numberWithInt:stackingIndex],@"index", nil];
        
        [stackingViews addObject:dict];
        stackingIndex++;
    }
    
}

// 0 1 2 3 [4] 5 6 7 [8] 9 
// [zero] 1 2 3 4 5 [6] 7 8 9 10 11
// 0 1 2 3 4 [5] 6 7 8 9 10 [eleven]
// [zero] 1 [2]
- (NSRange)stackedNotesRange
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NSMutableOrderedSet *allDocuments = [model currentNoteEntries];
    
    int count = allDocuments.count;
    int displayableCellCount = (int)ceilf((self.view.bounds.size.height/kCellHeight));
    displayableCellCount = displayableCellCount > count ? count : displayableCellCount;
    
    int beginRange = _currentNoteIndex;
    int endRange = _currentNoteIndex;
    while (endRange-beginRange<=displayableCellCount) {
        beginRange--;
        endRange++;
    }
    
    beginRange = beginRange < 0 ? 0 : beginRange;
    endRange = endRange > count ? count : endRange;
    
    while (endRange-beginRange<displayableCellCount && beginRange>0) {
        beginRange--;
    }
    
    NSLog(@"begin: %d, end: %d",beginRange,endRange);
    
    return NSMakeRange(beginRange, endRange);
}

- (void)makeCurrentNote
{
    _currentNote = nil;
    NSLog(@"current index %d %d",_currentNoteIndex,__LINE__);
    _currentNote = [_stackVC viewAtIndex:_currentNoteIndex];
    //[self debugView:_currentNote color:[UIColor blueColor]];
}

- (void)debugView:(UIView *)view color:(UIColor *)color
{
    // debugging
    view.layer.borderColor = color.CGColor;
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
- (UIImage *)imageForDocument:(NoteEntry *)noteEntry
{
    NoteEntry *previous = self.currentNoteViewController.noteEntry;
    [self.currentNoteViewController setNoteEntry:noteEntry];
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size,YES,0.0f);
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
    return velocity.x > 0;
}

- (BOOL)wantsToCreateWithPoint:(CGPoint)point velocity:(CGPoint)velocity
{
    return velocity.x < 0;
}

- (void) panReceived:(UIPanGestureRecognizer *)recognizer {
    
    BOOL useDefaultKeyboard = [[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultKeyboard"];
    if (_keyboardShowing && useDefaultKeyboard) {
        return;
    }
    
    ApplicationModel *model = [ApplicationModel sharedInstance];
    CGPoint point = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGRect nextNoteFrame = self.nextNoteViewController.view.frame;
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    
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
                
                NoteEntry *nextNote = [model nextNoteInStackFromIndex:model.selectedNoteIndex];
                [self.nextNoteViewController setNoteEntry:nextNote];
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

- (void)finishDeletingDocument:(CGPoint)point
{
    // shredding animations for deletion
    ApplicationModel *model = [ApplicationModel sharedInstance];
    NoteEntry *toDelete = currentNoteViewController.noteEntry;
    [self setGestureState:kGestureFinished];
    
    //NSLog(@"should delete %@",toDelete.text);
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
    if (noteCount==1) {
        [self snapBackCurrentNote];
        return;
    }
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
    NSLog(@"before count: %d",_currentNoteIndex);
    [model createNoteWithCompletionBlock:^(NoteEntry *doc){
        //[[NSNotificationCenter defaultCenter] postNotificationName:kNoteListChangedNotification object:nil];
        
    }];
    
    
    NSLog(@"New note entry with text: %@",model.noteAtSelectedNoteIndex.text);
    
    [model setSelectedNoteIndex:0];
    int currentIndex = model.selectedNoteIndex;
    
    [_stackVC generateCells];
    [self updateNoteDocumentsForIndex:currentIndex];
    [self setUpRangeForStacking];
        
    [self setGestureState:kGestureFinished];
    self.currentNoteViewController.view.hidden = NO;
    
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    [UIView animateWithDuration:DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.nextNoteViewController.view.frame = CGRectMake(0.0, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL success) {
                         [self.view addSubview:self.currentNoteViewController.view];
                         
                     }];
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
    
    UIImage *viewImage = [self imageForDocument:self.currentNoteViewController.noteEntry];
    
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
                         self.nextNoteViewController.view.frame = CGRectMake(viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL complete){
                         self.nextNoteViewController.view.frame = viewFrame;
                         [self.view addSubview:currentNoteViewController.view];
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

- (void)popToNoteList:(int)index
{
    self.dismissBlock(index,[self finalYOriginForCurrentNote]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateNoteDocumentsForIndex:(NSUInteger)index
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    
    self.previousNoteEntry = [model previousNoteInStackFromIndex:index];
    self.nextNoteEntry = [model nextNoteInStackFromIndex:index];
    
    NoteEntry *entryToShow = [model noteAtIndex:index];
        
    [self.currentNoteViewController setNoteEntry:entryToShow];
    [self.currentNoteViewController.view setNeedsDisplay];
    self.currentNoteViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self setUpRangeForStacking];
}

- (void)showVelocity:(CGPoint)velocity andEntryUnderneath:(NoteDocument *)entryUnderneath
{
    NSLog(@"velocity: %@",NSStringFromCGPoint(velocity));
    NSLog(@"entry underneath: %@",entryUnderneath.text);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //NSLog(@"note is touched");
    
    if (_currentGestureState == kStackingPinch) {
        return;
    }
    
    if(!self.optionsViewController.view.hidden) {
        // find the element that is being touched, if any.
        CGPoint currentLocation = [[touches anyObject] locationInView:self.view];
        CGRect frame = self.overView.frame;
        if(!CGRectContainsPoint(frame, currentLocation)) {
            NSLog(@"touch options panel");
        } else {
            
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

- (void)showOptions
{
    [self.currentNoteViewController.textView resignFirstResponder];
    [self shiftCurrentNoteOriginToPoint:CGPointMake(96, 0) completion:nil];
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

- (void)configureKeyboard
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    BOOL useSystem = [[NSUserDefaults standardUserDefaults] boolForKey:USE_STANDARD_SYSTEM_KEYBOARD];
    if (!useSystem) {
        
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
        
    } else {
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:self.currentNoteViewController queue:nil usingBlock:^(NSNotification *note){
            _keyboardShowing = YES;
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidHideNotification object:self.currentNoteViewController queue:nil usingBlock:^(NSNotification *note){
            _keyboardShowing = NO;
        }];
        
        self.currentNoteViewController.textView.inputView = nil;
        [self.currentNoteViewController.textView setKeyboardAppearance:UIKeyboardAppearanceAlert];
    }
    
}

#pragma mark OptionsViewDelegate

- (void)sendEmail
{
    self.mailVC = [[MFMailComposeViewController alloc] init];
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
