//  NoteCollectionViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <MessageUI/MessageUI.h>
#import <Twitter/Twitter.h>
#import <UIView+FrameAdditions/UIView+FrameAdditions.h>
#import "NTDCollectionViewController.h"
#import "NTDListCollectionViewLayout.h"
#import "NTDPagingCollectionViewLayout.h"
#import "DAKeyboardControl.h"
#import "NSIndexPath+NTDManipulation.h"
#import "NTDOptionsViewController.h"
#import "UIDeviceHardware.h"
#import "NTDCollectionViewController+Shredding.h"
#import "NTDNote.h"
#import "Utilities.h"
#import "NTDWalkthrough.h"
#import "NTDCollectionViewController+Walkthrough.h"

@interface NTDCollectionViewController () <UIGestureRecognizerDelegate, UITextViewDelegate, NTDOptionsViewDelegate>
@property (nonatomic, strong) UIView *pullToCreateContainerView;

@property (nonatomic, strong, readonly) NSIndexPath *visibleCardIndexPath;
@property (nonatomic, strong, readonly) NTDCollectionViewCell *pinchedCell;

@property (nonatomic, assign) CGRect initialFrameForVisibleNoteWhenViewingOptions;

@property (nonatomic, strong) NTDOptionsViewController *optionsViewController;
@property (nonatomic, strong) MFMailComposeViewController *mailViewController;

@property (nonatomic) BOOL hasTwoFingerNoteDeletionBegun;
@property (nonatomic) CGRect noteTextViewFrameWhileNotEditing;

@end

NSString *const NTDCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";
NSString *const NTDCollectionViewDuplicateCardReuseIdentifier = @"NoteCollectionViewDuplicateCardReuseIdentifier";

static const CGFloat SettingsTransitionDuration = 0.5;
static const CGFloat SwipeVelocityThreshold = 400.0;
static const CGFloat PinchVelocityThreshold = 2.2;
static const CGFloat InitialNoteOffsetWhenViewingOptions = 96.0;

@implementation NTDCollectionViewController

- (id)init
{
    NTDListCollectionViewLayout *initialLayout = [[NTDListCollectionViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:initialLayout];
    if (self) {
        self.listLayout = initialLayout;
        self.pagingLayout = [[NTDPagingCollectionViewLayout alloc] init];
        
        // decide on the slice count
        if ([UIDeviceHardware performanceClass] == NTDHighPerformanceDevice) {
            // 60 slices
            self.deletedNoteHorizSliceCount = 6;
            self.deletedNoteVertSliceCount = 10;
        } else {
            // 15 slices
            self.deletedNoteHorizSliceCount = 5;
            self.deletedNoteVertSliceCount = 3;
        }

        self.hasTwoFingerNoteDeletionBegun = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.allowsSelection = NO;
        self.collectionView.alwaysBounceVertical = YES;
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([NTDCollectionViewCell class]) bundle:nil]
              forCellWithReuseIdentifier:NTDCollectionViewCellReuseIdentifier];
        
        // register for keyboard notification so we can resize the textview
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willBeginWalkthrough:)
                                                     name:NTDWillBeginWalkthroughNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didDeclineWalkthrough:)
                                                     name:NTDDidDeclineWalkthroughNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didAdvanceWalkthroughToStep:)
                                                     name:NTDDidAdvanceWalkthroughToStepNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEndWalkthroughStep:)
                                                     name:NTDWillEndWalkthroughStepNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didCompleteWalkthrough:)
                                                     name:NTDDidCompleteWalkthroughNotification
                                                   object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];   
    [self setupPullToCreate];
    
    // swipe to remove in listlayout
    SEL selector = @selector(handleRemoveCardGesture:);
    self.removeCardGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:selector];
    self.removeCardGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.removeCardGestureRecognizer];
    
    // tap to change to page layout
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCardTap:)];
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.selectCardGestureRecognizer = tapGestureRecognizer;
    
    // pan to page cards
    UIPanGestureRecognizer *panGestureRecognizer;
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCard:)];
    panGestureRecognizer.enabled = NO;
    panGestureRecognizer.delegate = self;
    self.panCardGestureRecognizer = panGestureRecognizer;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    
    // 2 finger pan to delete card
    UIPanGestureRecognizer *twoFingerPanGestureRecognizer;
    twoFingerPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCardWithTwoFingers:)];
    twoFingerPanGestureRecognizer.enabled = NO;
    twoFingerPanGestureRecognizer.delegate = self;
    self.twoFingerPanGestureRecognizer = twoFingerPanGestureRecognizer;
    [self.collectionView addGestureRecognizer:twoFingerPanGestureRecognizer];
    
    // pinch to bring back tolist layout
    UIPinchGestureRecognizer *pinchGestureRecognizer;
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchToListLayout:)];
    pinchGestureRecognizer.enabled = NO;
    self.pinchToListLayoutGestureRecognizer = pinchGestureRecognizer;
    [self.collectionView addGestureRecognizer:pinchGestureRecognizer];
    
    // pan while viewing options
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCardWhileViewingOptions:)];
    panGestureRecognizer.enabled = NO;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    self.panCardWhileViewingOptionsGestureRecognizer = panGestureRecognizer;
    
    // tap while viewing options
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCardTapWhileViewingOptions:)];
    tapGestureRecognizer.enabled = NO;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.tapCardWhileViewingOptionsGestureRecognizer = tapGestureRecognizer;
    
    // set up properties
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
        self.notes = [notes mutableCopy];
        if (self.notes.count == 0) {
            [self noteListChanged:nil];
        } else {
            [self.collectionView reloadData];
        }
    }];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(noteListChanged:)
//                                                 name:kNoteListChangedNotification
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggledStatusBar:)
                                                 name:NTDDidToggleStatusBarNotification
                                               object:nil];
    
    self.collectionView.alwaysBounceVertical = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [NTDWalkthrough.sharedWalkthrough promptUserToStartWalkthrough];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup
static CGFloat PullToCreateLabelXOffset = 20.0, PullToCreateLabelYOffset = 6.0;
- (void)setupPullToCreate
{
    self.pullToCreateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pullToCreateLabel.text = @"Pull to create a new note.";
    self.pullToCreateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    self.pullToCreateLabel.backgroundColor = [UIColor blackColor];
    self.pullToCreateLabel.textColor = [UIColor whiteColor];
    [self.pullToCreateLabel sizeToFit];

    CGRect containerViewFrame = CGRectMake(0.0,
                                           -(self.pullToCreateLabel.$height + PullToCreateLabelYOffset),
                                           self.collectionView.bounds.size.width,
                                           self.pullToCreateLabel.$height + PullToCreateLabelYOffset);
    self.pullToCreateContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    self.pullToCreateContainerView.layer.zPosition = -10000;
    [self.collectionView addSubview:self.pullToCreateContainerView];

    self.pullToCreateLabel.$x = PullToCreateLabelXOffset;
    self.pullToCreateLabel.$y = PullToCreateLabelYOffset;
    [self.pullToCreateContainerView addSubview:self.pullToCreateLabel];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.notes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NTDCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NTDCollectionViewCellReuseIdentifier
                                                                            forIndexPath:indexPath];
    cell.textView.delegate = self;
    
    [cell.settingsButton addTarget:self
                            action:@selector(showSettings:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    NTDNote *note = [self noteAtIndexPath:indexPath];
    cell.relativeTimeLabel.text = [Utilities formatRelativeDate:note.lastModifiedDate];
#if DEBUG
    cell.relativeTimeLabel.text = [NSString stringWithFormat:@"[%d] %@", indexPath.item, cell.relativeTimeLabel.text];
#endif
    
    if (!self.hasTwoFingerNoteDeletionBegun)
        cell.layer.mask = nil;

    cell.textView.text = note.headline;
    BOOL isFinalCell = (self.notes.count > 0) && (indexPath.item == self.notes.count-1);
    if (collectionView.collectionViewLayout == self.pagingLayout || isFinalCell) {
        [self setBodyForCell:cell atIndexPath:indexPath];
    }
    [cell applyTheme:note.theme];

    [cell willTransitionFromLayout:nil toLayout:collectionView.collectionViewLayout];
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:NTDCollectionElementKindPullToCreateCard]) {
        NTDCollectionViewCell *cell = (NTDCollectionViewCell *) [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        cell.relativeTimeLabel.text = @"Today";
        cell.textView.text = @"Release to create a note";
        [cell applyTheme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite]];
        cell.textView.delegate = nil;
        return cell;
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    [[self noteAtIndexPath:indexPath] closeWithCompletionHandler:nil];
}

#pragma mark - Properties
-(NTDOptionsViewController *)optionsViewController
{
    if (_optionsViewController == nil) {
        _optionsViewController = [[NTDOptionsViewController alloc] init];
        _optionsViewController.delegate = self;
    }
    return _optionsViewController;
}

- (NTDCollectionViewCell *)visibleCell
{
    return (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.visibleCardIndexPath];
}

- (NSIndexPath *)visibleCardIndexPath
{
   return [NSIndexPath indexPathForItem:self.pagingLayout.activeCardIndex inSection:0];
}

- (NTDCollectionViewCell *)pinchedCell
{
    return (NTDCollectionViewCell *)[[self collectionView] cellForItemAtIndexPath:self.listLayout.pinchedCardIndexPath];
}


#pragma mark - Gesture Handling
- (void)handleRemoveCardGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    //hack. we should be more discerning about when we trigger anyway. aka, we should cancel
    //if indexPath==nil when in the 'began' state.
    if (self.notes.count == 0)
        return;
    
    static NSIndexPath *swipedCardIndexPath = nil;
    static BOOL shouldDelete = NO;
    
    CGPoint translation = [gestureRecognizer translationInView:self.collectionView];
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint initialPoint = [gestureRecognizer locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:initialPoint];
            if (indexPath) {
                swipedCardIndexPath = indexPath;
                self.listLayout.swipedCardOffset = 0.0;
            }
            // make the shadow larger and sticky to the cell's alpha
            NTDCollectionViewCell *theCell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            theCell.layer.shouldRasterize = YES;
            [theCell applyShadow:YES];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (self.collectionView.dragging) {
                // upon scrollview dragging ended, gesture will be re-enabled
                [self.removeCardGestureRecognizer setEnabled:NO];
                break;
            }
            self.collectionView.scrollEnabled = NO;
            self.listLayout.swipedCardIndexPath = swipedCardIndexPath;
            self.listLayout.swipedCardOffset = translation.x;
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (swipedCardIndexPath == nil)
                break;
            
            if (fabsf([gestureRecognizer velocityInView:self.collectionView].x) > SwipeVelocityThreshold
                || translation.x > self.collectionView.frame.size.width/2)
                shouldDelete = YES;
                
            self.collectionView.scrollEnabled = YES;            
            
            self.listLayout.swipedCardIndexPath = nil;
            if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                gestureRecognizer.enabled = YES;
            }
            if (shouldDelete && [self.collectionView numberOfItemsInSection:0] > 1) {
                [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughOneFingerDeleteStep];
                [self.listLayout completeDeletion:swipedCardIndexPath
                                       completion:^{
                                           [self deleteCardAtIndexPath:swipedCardIndexPath];
                                           shouldDelete = NO;
                                           [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughOneFingerDeleteStep];
                                       }];
            } else {
                // animate the cell back to its orig position
                [self.collectionView performBatchUpdates:nil completion:^(BOOL finished) {
                    // if it didnt delete, make the shadow smaller and un rasterized
                    NTDCollectionViewCell *theCell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:swipedCardIndexPath];
                    theCell.layer.shouldRasterize = NO;
                    [theCell applyShadow:NO];
                }];
                
            }
        
            break;
        }
        
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed :
        {
            // bugfix: return card to upright position
            if (self.listLayout.swipedCardIndexPath) {
                [self.collectionView performBatchUpdates:nil completion:nil];
            }
            
            if (self.hasTwoFingerNoteDeletionBegun)
                [self cancelShredForVisibleNote];
            
            swipedCardIndexPath = nil;
            shouldDelete = NO;
        }
            
        default:
            break;
    }
}

- (void)handleCardTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded &&
        self.listLayout == self.collectionView.collectionViewLayout) {
        CGPoint tapPoint = [tapGestureRecognizer locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:tapPoint];
        if (indexPath) {
            [self didSelectItemAtIndexPath:indexPath];
            
        }
    }
}

- (IBAction)panCardWithTwoFingers:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint translation = [panGestureRecognizer translationInView:self.collectionView];
    CGPoint touchLocation = [panGestureRecognizer locationInView:self.collectionView];
    CGFloat velocity = [panGestureRecognizer velocityInView:self.collectionView].x;

    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (panGestureRecognizer.numberOfTouches != 2)
                panGestureRecognizer.enabled = NO;
            else
                [self prepareVisibleNoteForShredding];
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            // we want a rtl swipe for shredding to begin
            if (!self.hasTwoFingerNoteDeletionBegun) {
                self.deletionDirection = (velocity > 0) ? NTDPageDeletionDirectionRight : NTDPageDeletionDirectionLeft;
                self.hasTwoFingerNoteDeletionBegun = YES;
            }
            
            if (self.hasTwoFingerNoteDeletionBegun)
                [self shredVisibleNoteByPercent:touchLocation.x/self.collectionView.frame.size.width completion:nil];
            
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            BOOL shouldDelete = NO;
            BOOL doNotRefresh = NO;
            int newIndex = self.visibleCardIndexPath.row;
            
            if (self.hasTwoFingerNoteDeletionBegun) {
                if ( fabsf(translation.x) >= self.collectionView.frame.size.width/2)
                    shouldDelete = YES;
                else if (fabsf(velocity) > SwipeVelocityThreshold ) {
                    shouldDelete = YES;
                }
                
                self.hasTwoFingerNoteDeletionBegun = NO;
            }
            
            if (self.notes.count > 1 && shouldDelete) {
                doNotRefresh = YES;
                newIndex--;
            } else {
                shouldDelete = NO;
            }
            
            NSIndexPath *prevvisibleCardIndexPath = self.visibleCardIndexPath;
            
            // make sure we stay within bounds
            newIndex = MAX(0, MIN(newIndex, [self.collectionView numberOfItemsInSection:0]-1));
            self.pagingLayout.activeCardIndex = newIndex ;
            
            // update this so we know to animate to resting position
            self.pagingLayout.pannedCardXTranslation = 0;
                        
            if (shouldDelete) {
                [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughTwoFingerDeleteStep];
                float percentToShredBy = (self.deletionDirection==NTDPageDeletionDirectionRight)?1:0;
                [self shredVisibleNoteByPercent:percentToShredBy completion:^{
                    [self.collectionView performBatchUpdates:^{
                        [self deleteCardAtIndexPath:prevvisibleCardIndexPath];
                    } completion:^(BOOL finished) {
                        [self.collectionView reloadData];
                        [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughTwoFingerDeleteStep];
                    }];
                }];
                    
            } else {
                [self cancelShredForVisibleNote];
            }
            self.hasTwoFingerNoteDeletionBegun = NO;
            
        }
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:            
        default:
            [self cancelShredForVisibleNote];
            
            self.hasTwoFingerNoteDeletionBegun = NO;
            
            panGestureRecognizer.enabled = YES;
            
            break;
    }
}

- (IBAction)panCard:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint translation = [panGestureRecognizer translationInView:self.collectionView];
    CGFloat velocity = [panGestureRecognizer velocityInView:self.collectionView].x;
    
    BOOL panEnded = NO;
    BOOL doNotRefresh = NO;
    int newIndex = self.pagingLayout.activeCardIndex;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan :
            if (panGestureRecognizer.numberOfTouches != 1)
                panGestureRecognizer.enabled = NO;
            
            break;
            
        case UIGestureRecognizerStateChanged :
            self.pagingLayout.pannedCardXTranslation = translation.x;            
            break;
            
        case UIGestureRecognizerStateEnded :
        {
            // check if translation is past threshold
            if (fabs(translation.x) >= self.collectionView.frame.size.width/2) {
                // left
                if (translation.x < 0)
                    newIndex ++ ;
                else
                    newIndex -- ;
                
            // check for a swipe
            } else if (fabs(velocity) > SwipeVelocityThreshold ) {
                // left
                if (velocity < 0)
                    newIndex ++ ;
                else
                    newIndex -- ;
            }
                                    
            // make sure we stay within bounds
            newIndex = MAX(0, MIN(newIndex, [self.collectionView numberOfItemsInSection:0]-1));
            self.pagingLayout.activeCardIndex = newIndex ;
            
            // update this so we know to animate to resting position
            self.pagingLayout.pannedCardXTranslation = 0;            
            panEnded = YES;
            break;
        }
            
        case UIGestureRecognizerStateFailed :
        case UIGestureRecognizerStateCancelled :
            NSLog(@"CANCEL");
            panGestureRecognizer.enabled = YES;
            
        default:            
            break;
    }
    
    if (!doNotRefresh) {
        if (panEnded)
            // animate to rest with some added velocity
            [self.pagingLayout finishAnimationWithVelocity:velocity+30 completion:nil];
        else if (!self.hasTwoFingerNoteDeletionBegun)
            [self.pagingLayout invalidateLayout];
    }
    
}

- (IBAction)panCardWhileViewingOptions:(UIPanGestureRecognizer *)panGestureRecognizer
{
    
    CGPoint translation = [panGestureRecognizer translationInView:self.collectionView];
    CGFloat velocity = [panGestureRecognizer velocityInView:self.collectionView].x;
    BOOL needsTranslation = NO;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan :
        case UIGestureRecognizerStateChanged :
            self.pagingLayout.pannedCardXTranslation = translation.x < 0 ? fmax(-self.pagingLayout.currentOptionsOffset, translation.x) : 0;
            needsTranslation = YES;
            break;
            
        case UIGestureRecognizerStateEnded :
            // check if translation is past threshold or a swipe
            if ((translation.x < 0 && fabs(translation.x) >= self.pagingLayout.currentOptionsOffset/2) ||
                (velocity < 0 && fabs(velocity) > SwipeVelocityThreshold)) {
                self.pagingLayout.pannedCardXTranslation = 0;
                [self closeOptionsWithVelocity:velocity];
            } else {
                self.pagingLayout.pannedCardXTranslation = 0;
                [self.pagingLayout finishAnimationWithVelocity:velocity+30 completion:nil];
            }
            
        default:
            break;
    }
    
    if (needsTranslation)
        [self.pagingLayout invalidateLayout];
}

- (void)handleCardTapWhileViewingOptions:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded)
        [self closeOptionsWithVelocity:.2];
}

- (IBAction)pinchToListLayout:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
{
    static CGFloat initialDistance = 0.0f, endDistance = 130.0f;
    static CGPoint initialContentOffset;
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *visibleCardIndexPath = [NSIndexPath indexPathForItem:self.pagingLayout.activeCardIndex inSection:0 ];
            
            initialDistance = PinchDistance(pinchGestureRecognizer);
            self.listLayout.pinchedCardIndexPath = visibleCardIndexPath;
            self.listLayout.pinchRatio = 1.0;
            
            [self.pinchedCell doNotHideSettingsForNextLayoutChange];
            
            initialContentOffset = self.collectionView.contentOffset;
            [self updateLayout:self.listLayout
                      animated:NO];
            
            float returnCardToContentOffset = CLAMP(0,
                                                    (visibleCardIndexPath.row * self.listLayout.cardOffset) - self.collectionView.frame.size.height/3,
                                                    self.collectionView.contentSize.height - self.collectionView.frame.size.height);
            
            [self.collectionView setContentOffset:CGPointMake(0, returnCardToContentOffset) animated:NO];
            self.collectionView.scrollEnabled = NO;
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            
            self.pinchedCell.settingsButton.alpha = CLAMP(pinchRatio, 0, 1) ;
//                NSLog(@"scale: %.2f, ratio: %.2f", pinchGestureRecognizer.scale, pinchRatio);
//                NSLog(@"initial d: %.2f, current d: %.2f", initialDistance, currentDistance);
            self.listLayout.pinchRatio = pinchRatio;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            
            BOOL shouldReturnToPagingLayout = (pinchRatio > 0.0 && pinchGestureRecognizer.velocity > -PinchVelocityThreshold);
            
            if (shouldReturnToPagingLayout) {
                [self updateLayout:self.pagingLayout
                          animated:NO];
                [self.collectionView setContentOffset:initialContentOffset animated:NO];
            } else {
                pinchGestureRecognizer.enabled = NO;
                self.collectionView.scrollEnabled = YES;
                self.pinchedCell.settingsButton.alpha = 0;
                [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughPinchToListStep];
                [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughPinchToListStep];
            }
            self.listLayout.pinchedCardIndexPath = nil;
            break;
        }
            
        case UIGestureRecognizerStateCancelled:
            pinchGestureRecognizer.enabled = YES;
            break;
            
        default:
            break;
    }
}

#pragma mark - Actions

-(void) didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    NTDCollectionViewCell *selectedCell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self setBodyForCell:selectedCell atIndexPath:indexPath];
    
    CGFloat topOffset = selectedCell.frame.origin.y - self.collectionView.contentOffset.y;
    CGFloat bottomOffset = self.collectionView.frame.size.height - (topOffset + self.listLayout.cardOffset);

    [UIView animateWithDuration:.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         selectedCell.settingsButton.alpha = 1;
                         NSArray *indexPaths = [self.collectionView indexPathsForVisibleItems];
                         for (NSIndexPath *visibleCardIndexPath in indexPaths) {
                             NTDCollectionViewCell *cell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:visibleCardIndexPath];
                             if (visibleCardIndexPath.row <= indexPath.row) {
                                 cell.$y -= topOffset;
                             } else {
                                 cell.$y += bottomOffset;
                             }

                         }
                     } completion:^(BOOL finished) {
                         self.pagingLayout.activeCardIndex = indexPath.row;
                         [self updateLayout:self.pagingLayout
                                   animated:NO];
                     }];
    
}

- (IBAction)showSettings:(id)sender
{
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughTapOptionsStep];
    
    NTDCollectionViewCell *visibleCell = self.visibleCell;
    
    /* Don't let user interact with anything but our options. */
    visibleCell.textView.editable = NO;
    self.panCardWhileViewingOptionsGestureRecognizer.enabled = YES;
    self.tapCardWhileViewingOptionsGestureRecognizer.enabled = YES;
    self.pinchToListLayoutGestureRecognizer.enabled = NO;
    
    self.optionsViewController.view.frame = visibleCell.frame;
    self.optionsViewController.note = [self noteAtIndexPath:self.visibleCardIndexPath];
    [self.collectionView insertSubview:self.optionsViewController.view belowSubview:visibleCell];
    
    [self.pagingLayout revealOptionsViewWithOffset:InitialNoteOffsetWhenViewingOptions
                                        completion:^{
                                            [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughTapOptionsStep];
                                        }];
}

#pragma mark - Helpers
CGFloat PinchDistance(UIPinchGestureRecognizer *pinchGestureRecognizer)
{
    UIView *view = pinchGestureRecognizer.view;
    CGPoint p1 = [pinchGestureRecognizer locationOfTouch:0 inView:view];
    CGPoint p2 = [pinchGestureRecognizer locationOfTouch:1 inView:view];
    return DistanceBetweenTwoPoints(p1, p2);
}

CGFloat DistanceBetweenTwoPoints(CGPoint p1, CGPoint p2)
{
    CGFloat d = (p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y);
    return sqrtf(d);
}

- (void)updateLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated
{
    [self.collectionView setCollectionViewLayout:layout animated:animated];
    if (layout == self.pagingLayout) {
        self.selectCardGestureRecognizer.enabled = NO;
        self.removeCardGestureRecognizer.enabled = NO;
        self.panCardGestureRecognizer.enabled = YES;
        self.twoFingerPanGestureRecognizer.enabled = YES;
        self.pinchToListLayoutGestureRecognizer.enabled = YES;
        
        self.collectionView.scrollEnabled = NO;
        
    } else if (layout == self.listLayout) {
        self.selectCardGestureRecognizer.enabled = YES;
        self.removeCardGestureRecognizer.enabled = YES;
        self.panCardGestureRecognizer.enabled = NO;
        self.twoFingerPanGestureRecognizer.enabled = NO;
        
        self.view.$width = [[UIScreen mainScreen] bounds].size.width;
    }
    [self.collectionView reloadData];
}

- (void)insertNewCardWithDuration:(NSTimeInterval)duration
{
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughMakeANoteStep];
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         NSMutableArray *subviews = [[self.collectionView subviews] mutableCopy];
                         NSArray *indexPaths = [self.collectionView indexPathsForVisibleItems];
                         for (NSIndexPath *visibleIndexPath in indexPaths) {
                             NTDCollectionViewCell *cell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:visibleIndexPath];
                             cell.$y += self.collectionView.frame.size.height;
                             [subviews removeObject:cell];
                         }
                         for (UIView *view in subviews) {
                             /* Search for & edit the 'pull to create card' cell. */
                             if ([view isKindOfClass:[NTDCollectionViewCell class]] &&
                                 (view.$y <= self.listLayout.pullToCreateCreateCardOffset) &&
                                 !view.hidden) {
                                 NTDCollectionViewCell *cell = (NTDCollectionViewCell *)view;
#if DEBUG
                                 cell.relativeTimeLabel.text = @"[0] Today";
#else
                                  cell.relativeTimeLabel.text = @"Today";
#endif
                                 break;
                             }
                         }
                     } completion:^(BOOL finished) {
                         [NTDNote newNoteWithCompletionHandler:^(NTDNote *note) {
                             [self.notes insertObject:note atIndex:0];
                             self.pagingLayout.activeCardIndex = 0;
                             [self updateLayout:self.pagingLayout
                                       animated:NO];
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.visibleCell.textView becomeFirstResponder];
                                 [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughMakeANoteStep];
                             });
                         }];
                     }];
}

- (void)deleteCardAtIndexPath:(NSIndexPath *)indexPath
{
    NTDNote *note = [self noteAtIndexPath:indexPath];
    [self.notes removeObject:note];
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    [note deleteWithCompletionHandler:nil];
}

- (NTDNote *)noteAtIndexPath:(NSIndexPath *)indexPath
{
    return self.notes[indexPath.item];
}

- (void)setBodyForCell:(NTDCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    /* We take `cell` as a parameter because `-[UICollectionView cellForItemAtIndexPath:]`
     * returns `nil` inside of `collectionView:cellForItemAtIndexPath:`. */
    NTDNote *note = [self noteAtIndexPath:indexPath];
    NTDCollectionViewCell __weak *weakCell = cell;
    if (note.fileState != NTDNoteFileStateOpened) {
        [note openWithCompletionHandler:^(BOOL success) {
            weakCell.textView.text = note.text;
        }];
    } else {
        weakCell.textView.text = note.text;
    }
}

- (void)closeOptionsWithVelocity:(CGFloat)velocity
{
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughCloseOptionsStep];
    [self.pagingLayout hideOptionsWithVelocity:velocity completion:^{
        self.panCardWhileViewingOptionsGestureRecognizer.enabled = NO;
        self.tapCardWhileViewingOptionsGestureRecognizer.enabled = NO;
        
        self.visibleCell.textView.editable = YES;
        self.pinchToListLayoutGestureRecognizer.enabled = YES;
        [self.optionsViewController.view removeFromSuperview];
        [self.optionsViewController reset];
        [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughCloseOptionsStep];
    }];
}

#pragma mark - Notifications
- (void)noteListChanged:(NSNotification *)notification
{
    if (self.notes.count == 0) {
        NSString *firstNoteText = @"Welcome to Noted.\n\n• Pull the list down to create a new note.\n• Swipe a note out of the stack to delete it.\n• Tap a note to see it and edit it.\n• Swipe left and right to page through notes.\n• Swipe right with two fingers to shred a note.\n\n😁 Have fun and send us your feedback!";
        NSString *secondNoteText = @"Here's another note.";
        NTDTheme *firstNoteTheme = [NTDTheme themeForColorScheme:NTDColorSchemeTack], *secondNoteTheme = [NTDTheme themeForColorScheme:NTDColorSchemeWhite];
        // add 2 notes
        [NTDNote newNoteWithText:firstNoteText theme:firstNoteTheme completionHandler:^(NTDNote *note) {
            [self.notes insertObject:note atIndex:0];
            [NTDNote newNoteWithText:secondNoteText theme:secondNoteTheme completionHandler:^(NTDNote *note) {
                [self.notes insertObject:note atIndex:0];
                [self.collectionView reloadData];
            }];
        }];
    }
    
    if (!self.panCardWhileViewingOptionsGestureRecognizer.isEnabled) {
        [self.collectionView reloadData];
    }
}

-(void)toggledStatusBar:(NSNotification *)notification
{
    // Main app frame and status bar size
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    
    // Main view and options view
    CGRect newViewFrame = self.view.frame;
    CGRect newOptionsFrame = self.optionsViewController.view.frame;
    
    // Detects whether the app starts up with status bar hidden or shown.
    if (![UIApplication sharedApplication].statusBarHidden) {
        newViewFrame.origin.y = statusBarHeight;
    } else {
        newViewFrame.origin.y = 0.0;
        newOptionsFrame.origin.y = 0.0;
    }
    
    newViewFrame.size.height = appFrame.size.height;
    newOptionsFrame.size.height = appFrame.size.height;
    
    self.view.frame = newViewFrame;
    self.optionsViewController.view.frame = newOptionsFrame;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isEqual:self.panCardGestureRecognizer] && [otherGestureRecognizer isEqual:self.twoFingerPanGestureRecognizer])
        return YES;
    
    if (otherGestureRecognizer == self.collectionView.panGestureRecognizer)
        return YES;
    else
        return NO;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.visibleCell.textView)
        [self.visibleCell applyMaskWithScrolledOffset:scrollView.contentOffset.y];
    
    if (scrollView != self.collectionView)
        return;
    
    // bugfix to prevent remove card from firing
    if (self.removeCardGestureRecognizer.state == UIGestureRecognizerStateBegan)
        self.removeCardGestureRecognizer.enabled = NO;
    
    CGFloat y = scrollView.bounds.origin.y;
    if (y < -self.pullToCreateContainerView.$height) {
        self.pullToCreateContainerView.$y = y;
    } else {
        self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
    }
    
    /* In iOS 6, scroll indicator views are: the frontmost subview of a scrollview; instances of UIImageVIew
     * and have a width of 7 points. As you can tell, this is a total hack to place the scroll indicators
     * on top of all visible cards. */
    UIView *possibleIndicatorView = [[scrollView subviews] lastObject];
    if ([possibleIndicatorView isKindOfClass:[UIImageView class]] &&
        possibleIndicatorView.$width == 7) {
        if (CATransform3DIsIdentity(possibleIndicatorView.layer.transform))
            possibleIndicatorView.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, CGFLOAT_MAX);
    }
        
//    NSLog(@"Bounds: %@", NSStringFromCGRect(scrollView.bounds));
//    NSLog(@"Content Offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView != self.collectionView)
        return;
    
    // re-enable swipe to delete
    self.removeCardGestureRecognizer.enabled = YES;
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
//    NSLog(@"willEndDragging withVelocity:%@ contentOffset: %@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(scrollView.contentOffset));
    BOOL shouldCreateNewCard = (scrollView.contentOffset.y <= self.listLayout.pullToCreateCreateCardOffset);
    if (self.notes.count == 0) //hack alert
        shouldCreateNewCard = (scrollView.contentOffset.y <= 0.0);
    if (shouldCreateNewCard && self.collectionView.collectionViewLayout == self.listLayout) {
        CGPoint panVelocity = [scrollView.panGestureRecognizer velocityInView:scrollView];
        CGPoint panTranslation = [scrollView.panGestureRecognizer translationInView:scrollView];

//        CGFloat scrollSpeed = fabsf(60 * velocity.y) + 30;
//        CGFloat scrollPosition = fabsf(scrollView.contentOffset.y);
//        NSTimeInterval scrollDuration = scrollPosition / scrollSpeed;
        
        CGFloat panSpeed = fabsf(panVelocity.y) - 30;
        CGFloat panPosition = fabsf(panTranslation.y);
        CGFloat panDuration = panPosition / panSpeed;
        
        NSTimeInterval duration = panDuration;
        duration = CLAMP(duration, 0.2, 0.6);
        [self insertNewCardWithDuration:duration];

        CGPoint newPoint = scrollView.contentOffset;
        *targetContentOffset = newPoint;
    }

}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (NTDNoteFileStateOpened != [[self noteAtIndexPath:self.visibleCardIndexPath] fileState])
        return NO;
        
    self.panCardGestureRecognizer.enabled = NO;
    self.twoFingerPanGestureRecognizer.enabled = NO;
    self.pinchToListLayoutGestureRecognizer.enabled = NO;
    [textView addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        [self keyboardWasPannedToFrame:keyboardFrameInView];
    }];
    
    // resize the textview
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [[self noteAtIndexPath:self.visibleCardIndexPath] setText:textView.text];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
//    [textView removeKeyboardControl];
    self.panCardGestureRecognizer.enabled = YES;
    self.twoFingerPanGestureRecognizer.enabled = YES;
    self.pinchToListLayoutGestureRecognizer.enabled = YES;
}

#pragma mark - Keyboard Handling
- (void)keyboardWasShown:(NSNotification*)notification
{
    // save the frame
    self.noteTextViewFrameWhileNotEditing = self.visibleCell.textView.frame;
    
    // resize the textview
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.visibleCell.textView.$bottom = self.collectionView.frame.size.height - keyboardSize.height;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    self.visibleCell.textView.frame = self.noteTextViewFrameWhileNotEditing;
    [self.visibleCell applyMaskWithScrolledOffset:0];
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughSwipeToCloseKeyboardStep];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughSwipeToCloseKeyboardStep];
}

- (void)keyboardWasPannedToFrame:(CGRect)frame
{
    // resize the textview
    self.visibleCell.textView.$bottom = frame.origin.y - self.visibleCell.textView.contentOffset.y + self.visibleCell.textView.frame.origin.y;
}

#pragma mark - NTDOptionsViewControllerDelegate

-(CGFloat)initialOptionsViewWidth {
    return InitialNoteOffsetWhenViewingOptions;
}

-(void)changeOptionsViewWidth:(CGFloat)width {
    [self.pagingLayout revealOptionsViewWithOffset:width];
}

- (void)didChangeNoteTheme
{
    [self.visibleCell applyTheme:self.optionsViewController.note.theme];
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughChangeColorsStep];
    [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughChangeColorsStep];
}
@end
