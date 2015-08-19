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
#import <FlurrySDK/Flurry.h>
#import <BlocksKit/BlocksKit.h>
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
#import "NTDCollectionViewController+ShakeToUndoDelete.h"
#import "NTDModalView.h"
#import "UIViewController+NTDToast.h"
#import "NTDDropboxManager.h"

typedef NS_ENUM(NSInteger, NTDCardPanningDirection) {
    NTDCardPanningNoDirection = -1,
    NTDCardPanningHorizontalDirection,
    NTDCardPanningVerticalDirection
};

@interface NTDCollectionViewController () <UIGestureRecognizerDelegate, UITextViewDelegate, NTDOptionsViewDelegate>
@property (nonatomic, strong) UIView *pullToCreateContainerView;

@property (nonatomic, strong, readonly) NSIndexPath *visibleCardIndexPath;
@property (nonatomic, strong, readonly) NTDCollectionViewCell *pinchedCell;

@property (nonatomic, strong) NSMutableArray *deletedNotesStack;

@property (nonatomic, assign) NTDDeletionDirection oneFingerDeletionDirection;

@property (nonatomic, assign) CGRect initialFrameForVisibleNoteWhenViewingOptions;

@property (nonatomic, strong) NTDOptionsViewController *optionsViewController;
@property (nonatomic, strong) MFMailComposeViewController *mailViewController;

@property (nonatomic) NTDCardPanningDirection cardPanningDirection;
@property (nonatomic) BOOL hasTwoFingerNoteDeletionBegun;
@property (nonatomic) CGRect noteTextViewFrameWhileNotEditing;

@property (nonatomic, assign) BOOL transitioningToPagingLayout;

@end

NSString *const NTDCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";
NSString *const NTDCollectionViewPullToCreateCardReuseIdentifier = @"NTDCollectionViewPullToCreateCardReuseIdentifier";

//static const CGFloat SettingsTransitionDuration = 0.5;
static const CGFloat SwipeVelocityThreshold = 1000.0;
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
        self.cardPanningDirection = NTDCardPanningNoDirection;
        
        // decide on the slice count
        if ([UIDeviceHardware isHighPerformanceDevice]) {
            // 60 slices
            self.deletedNoteHorizSliceCount = 6;
            self.deletedNoteVertSliceCount = 10;
        } else {
            // 15 slices
            self.deletedNoteHorizSliceCount = 5;
            self.deletedNoteVertSliceCount = 3;
        }

        self.hasTwoFingerNoteDeletionBegun = NO;
        self.note_refresh_group = dispatch_group_create();
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.allowsSelection = NO;
        self.collectionView.alwaysBounceVertical = YES;
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([NTDCollectionViewCell class]) bundle:nil];
        [self.collectionView registerNib:nib
              forCellWithReuseIdentifier:NTDCollectionViewCellReuseIdentifier];
        [self.collectionView registerNib:nib
              forSupplementaryViewOfKind:NTDCollectionElementKindPullToCreateCard
                     withReuseIdentifier:NTDCollectionViewPullToCreateCardReuseIdentifier];
        
        /* Enable scrollsToTop functionality. */
        __weak UICollectionView *collectionView = self.collectionView;
        _pagingLayoutIndexObserver = [self.pagingLayout bk_addObserverForKeyPath:@"activeCardIndex"
                                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                               task:^(id obj, NSDictionary *change) {
                                                   NSInteger oldIndex = [change[NSKeyValueChangeOldKey] integerValue];
                                                   NSInteger newIndex = [change[NSKeyValueChangeNewKey] integerValue];

                                                   NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:oldIndex inSection:0];
                                                   NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];

                                                   NTDCollectionViewCell *oldCell = (NTDCollectionViewCell *)[collectionView cellForItemAtIndexPath:oldIndexPath];
                                                   NTDCollectionViewCell *newCell = (NTDCollectionViewCell *)[collectionView cellForItemAtIndexPath:newIndexPath];

                                                   oldCell.textView.scrollsToTop = NO;
                                                   newCell.textView.scrollsToTop = YES;
                                               }];
        
        /* Notifications */
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
                                                 selector:@selector(didAdvanceWalkthroughToStep:)
                                                     name:NTDDidAdvanceWalkthroughToStepNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEndWalkthroughStep:)
                                                     name:NTDWillEndWalkthroughStepNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEndWalkthrough:)
                                                     name:NTDDidEndWalkthroughNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mayShowNoteAtIndexPath:)
                                                     name:NTDMayShowNoteAtIndexPathNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toggledStatusBar:)
                                                     name:NTDDidToggleStatusBarNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(noteWasUpdated:)
                                                     name:NTDNoteWasChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(noteWasDeleted:)
                                                     name:NTDNoteWasDeletedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(noteWasAdded:)
                                                     name:NTDNoteWasAddedNotification
                                                   object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];   
    [self setupPullToCreate];
    
    // swipe to remove in listlayout
    self.removeCardGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRemoveCardGesture:)];
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
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    self.panCardGestureRecognizer = panGestureRecognizer;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
  
    // 2 finger pan to delete card
    UIPanGestureRecognizer *twoFingerPanGestureRecognizer;
    twoFingerPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCardWithTwoFingers:)];
    twoFingerPanGestureRecognizer.enabled = NO;
    twoFingerPanGestureRecognizer.delegate = self;
    [twoFingerPanGestureRecognizer setMaximumNumberOfTouches:2];
    [twoFingerPanGestureRecognizer setMinimumNumberOfTouches:2];
    self.twoFingerPanGestureRecognizer = twoFingerPanGestureRecognizer;
    [self.collectionView addGestureRecognizer:twoFingerPanGestureRecognizer];
    
    // pinch to bring back tolist layout
    UIPinchGestureRecognizer *pinchGestureRecognizer;
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchToListLayout:)];
    self.pinchToListLayoutGestureRecognizer = pinchGestureRecognizer;
    [self.collectionView addGestureRecognizer:pinchGestureRecognizer];
    
    // pan while viewing options
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCardWhileViewingOptions:)];
    panGestureRecognizer.enabled = NO;
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    self.panCardWhileViewingOptionsGestureRecognizer = panGestureRecognizer;
    
    // tap while viewing options
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCardTapWhileViewingOptions:)];
    tapGestureRecognizer.enabled = NO;
//    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.tapCardWhileViewingOptionsGestureRecognizer = tapGestureRecognizer;
    
    // create launch image view while the notes are reloading
    UIImage *launchImage = (IS_TALL_IPHONE) ? [UIImage imageNamed:@"Default-568h"] : [UIImage imageNamed:@"Default"];
    __block UIImageView *launchImageView = [[UIImageView alloc] initWithImage:launchImage];
    [[[UIApplication sharedApplication] keyWindow] addSubview:launchImageView];

    // set up properties
    [self bindGestureRecognizers];
    [self.collectionView reloadData];
    self.collectionView.alwaysBounceVertical = YES;
    [self reloadNotes];
    dispatch_group_notify(self.note_refresh_group,
                          dispatch_get_main_queue(),
                          ^{
                              if ( launchImageView ) {
                                  [launchImageView removeFromSuperview];
                                  launchImageView = nil;
                              }
                              [self bk_performBlock:^(id sender) {
                                  if (!NTDWalkthrough.isCompleted)
                                      [NTDWalkthrough.sharedWalkthrough promptUserToStartWalkthrough];
                                  else
                                      if (![NTDWalkthrough hasLearnedAboutThemes])
                                          [NTDWalkthrough.sharedWalkthrough promptUserAboutThemes];
                              }
                                      afterDelay:NTDDefaultInitialModalDelay];
                          });
    
    [self becomeFirstResponder];

    [self.view addObserver: self
                forKeyPath: @"frame"
                   options: 0
                   context: NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(__unused void *)context
{
    if( [keyPath isEqualToString:@"frame"] && object == self.view ) {
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        if ( self.view.$y != statusBarHeight ) {
            self.view.$y = statusBarHeight;
        }
    }
}

-(void)dealloc
{
    if ( _pagingLayoutIndexObserver ) {
        [self.pagingLayout bk_removeObserversWithIdentifier:_pagingLayoutIndexObserver];
    }
    _pagingLayoutIndexObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    UIApplication.sharedApplication.keyWindow.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
    [super viewDidAppear:animated];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.collectionView.collectionViewLayout != self.pagingLayout) return;
    
    /* Fixes a 7.1b1 bug. It seems that zIndex isn't being respected, so we resort the collection view's subviews here. */
    NSMutableArray *cells = [NSMutableArray array];
    [[self.collectionView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NTDCollectionViewCell class]]) [cells addObject:obj];
    }];
    if (cells.count <= 1) return;

    // Bubble sort
    BOOL didSwap;
    do {
        didSwap = NO;
        for (int i = 1; i < cells.count; i++) {
            NTDCollectionViewCell *cell = cells[i], *previousCell = cells[i-1];
            if (cell.layer.transform.m43 < previousCell.layer.transform.m43) {
                [self.collectionView insertSubview:cell belowSubview:previousCell];
                [cells exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                didSwap = YES;
            }
        }
    } while (didSwap);
}

- (BOOL)canBecomeFirstResponder
{
    /* So we can detect shake events.*/
    return YES;
}

#pragma mark - Setup
static CGFloat PullToCreateLabelXOffset = 20.0, PullToCreateLabelYOffset = 6.0;
- (void)setupPullToCreate
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        PullToCreateLabelXOffset -= 8.5;
        PullToCreateLabelYOffset -= 2;
    }
    self.pullToCreateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pullToCreateLabel.text = @"Pull to create a new note.";
    self.pullToCreateLabel.font = [UIFont fontWithName:@"Avenir-Light" size:16];
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
//    NSLog(@"%s: creating cell for note #%d\n", __FUNCTION__, indexPath.item);

    [cell.settingsButton addTarget:self
                            action:@selector(showSettings:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    NTDNote *note = [self noteAtIndexPath:indexPath];
    cell.relativeTimeLabel.text = [Utilities formatRelativeDate:note.lastModifiedDate];
    cell.dateCreated = note.lastModifiedDate;

    if (!self.hasTwoFingerNoteDeletionBegun)
        cell.layer.mask = nil;

    cell.textView.text = note.headline;
    if ([self shouldShowBodyForNoteAtIndexPath:indexPath]) {
        [self setBodyForCell:cell atIndexPath:indexPath];
    }
    [cell applyTheme:note.theme];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        if (self.collectionView.collectionViewLayout == self.listLayout && 0 != indexPath.item && !self.transitioningToPagingLayout) {
            /* It's necessary to remove and re-add the motion effects (on the next turn of the run-loop) because the effects
             * were being suspended for some unknown reason. */
            [self removeMotionEffects:cell atIndexPath:indexPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addMotionEffects:cell atIndexPath:indexPath];
            });
        }
    }
    [cell willTransitionFromLayout:nil toLayout:collectionView.collectionViewLayout];
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:NTDCollectionElementKindPullToCreateCard]) {
        NTDCollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:NTDCollectionElementKindPullToCreateCard
                                                                         withReuseIdentifier:NTDCollectionViewPullToCreateCardReuseIdentifier
                                                                                forIndexPath:indexPath];
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

                // make the shadow larger and sticky to the cell's alpha
                NTDCollectionViewCell *theCell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                theCell.layer.shouldRasterize = YES;
                [theCell applyShadow:YES];
            }
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
            
            BOOL velocityCrossesThreshold = fabsf([gestureRecognizer velocityInView:self.collectionView].x) > SwipeVelocityThreshold;
            BOOL positionCrossesThreshold = ABS(translation.x) > self.collectionView.frame.size.width/2;
            shouldDelete = velocityCrossesThreshold || positionCrossesThreshold;
            
            self.collectionView.scrollEnabled = YES;            
            
            self.listLayout.swipedCardIndexPath = nil;
            if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                gestureRecognizer.enabled = YES;
            }
            if (shouldDelete && [self.collectionView numberOfItemsInSection:0] > 1) {
                [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughOneFingerDeleteStep];
                gestureRecognizer.enabled = NO;
                self.oneFingerDeletionDirection = (translation.x > 0) ? NTDDeletionDirectionRight : NTDDeletionDirectionLeft;
                [self.listLayout completeDeletion:swipedCardIndexPath
                                       completion:^{
                                           [self deleteCardAtIndexPath:swipedCardIndexPath];
                                           shouldDelete = NO;
                                           [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughOneFingerDeleteStep];
                                           if (self.notes.count == 1)
                                               [self didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                                           gestureRecognizer.enabled = YES;
                                       }];
            } else {
                // animate the cell back to its orig position
                [self animateSwipedCellToOriginalPosition];
                
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
        self.collectionView.collectionViewLayout == self.listLayout) {
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
            if (panGestureRecognizer.numberOfTouches == 2) {
                [self prepareVisibleNoteForShredding];
            } else {
                panGestureRecognizer.enabled = NO;
            }
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            // we want a rtl swipe for shredding to begin
            if (!self.hasTwoFingerNoteDeletionBegun) {
                self.twoFingerDeletionDirection = (velocity > 0) ? NTDDeletionDirectionRight : NTDDeletionDirectionLeft;
                self.hasTwoFingerNoteDeletionBegun = YES;
            }
            
            if (self.hasTwoFingerNoteDeletionBegun)
                [self shredVisibleNoteByPercent:touchLocation.x/self.collectionView.frame.size.width completion:nil];
            
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            BOOL shouldDelete = NO;
            BOOL doNotRefresh = NO;
            NSInteger newIndex = self.visibleCardIndexPath.item;
            
            if (self.hasTwoFingerNoteDeletionBegun) {
                if ( fabsf(translation.x) >= self.collectionView.frame.size.width/2)
                    shouldDelete = YES;
                else if ((velocity > SwipeVelocityThreshold && translation.x > 0)
                         || (velocity < -SwipeVelocityThreshold && translation.x < 0)) {
                         
                    shouldDelete = YES;
                }
                
                self.hasTwoFingerNoteDeletionBegun = NO;
            }
            
            BOOL shouldDeleteLastNote = NO;
            if (shouldDelete) {
                doNotRefresh = YES;
                if (self.notes.count == 1)
                    shouldDeleteLastNote = YES;
                else
                    newIndex--;
            } else {
                shouldDelete = NO;
            }
            
            NSIndexPath *prevVisibleCardIndexPath = self.visibleCardIndexPath;
            
            // make sure we stay within bounds
            newIndex =  CLAMP(newIndex, 0, [self.collectionView numberOfItemsInSection:0]-1);
            self.pagingLayout.activeCardIndex = newIndex ;
            
            // update this so we know to animate to resting position
            self.pagingLayout.pannedCardXTranslation = 0;
                        
            if (shouldDelete) {
                [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughTwoFingerDeleteStep];
                float percentToShredBy = (self.twoFingerDeletionDirection==NTDDeletionDirectionRight)?1:0;
                [self shredVisibleNoteByPercent:percentToShredBy completion:^{
                    if (shouldDeleteLastNote) {
                        self.pagingLayout.deletedLastNote = YES;
                        
                        // TODO Refactor this so it actually deletes the note, instead of replacing the text. This will fail when we add Dropbox.
                        NTDNote *deletedNote = [self.notes objectAtIndex:0];
                        [self.deletedNotesStack addObject:[[NTDDeletedNotePlaceholder alloc] initWithNote:deletedNote]];
                        [deletedNote setText:@""];
                        [deletedNote setTheme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite]];
                        [deletedNote setLastModifiedDate:[NSDate date]];
                        
                        // forcing the controller to reload the notes, thus updating the lastModifiedDate of the deletedNote (which isnt actually being deleted)
                        NSMutableArray *stack = [self.deletedNotesStack mutableCopy];
                        [self reloadNotes];
                        dispatch_group_notify(self.note_refresh_group,
                                              dispatch_get_main_queue(),
                                              ^{
                                                  self.deletedNotesStack = stack;
                                              });
                        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
                        [self.pagingLayout finishAnimationWithVelocity:0 completion:nil];

                    } else {
                        [self.collectionView performBatchUpdates:^{
                            [self deleteCardAtIndexPath:prevVisibleCardIndexPath];
//                            if (shouldDeleteLastNote) {
//                                [NTDNote newNoteWithCompletionHandler:^(NTDNote *note) {
//                                    [self.notes insertObject:note atIndex:0];
//                                    self.pagingLayout.deletedLastNote = YES;
//                                    self.pagingLayout.activeCardIndex = 0;
//                                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
//                                    [self.pagingLayout finishAnimationWithVelocity:0 completion:nil];
//                                }];
//                            }
                        } completion:^(BOOL finished) {
                            [self.collectionView reloadData];
                            [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughTwoFingerDeleteStep];
                        }];
                    }
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
    CGPoint velocity = [panGestureRecognizer velocityInView:self.collectionView];
    
    int newIndex = (int)self.pagingLayout.activeCardIndex;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan :
            if (panGestureRecognizer.numberOfTouches != 1)
                panGestureRecognizer.enabled = NO;
            else
                // prevent user from editing note with one finger while panning with another
                self.visibleCell.textView.userInteractionEnabled = NO;
            break;
            
        case UIGestureRecognizerStateChanged :
            
            // decide whether it is a vertical of horizontal pan
            if (self.cardPanningDirection == NTDCardPanningNoDirection) {
                self.cardPanningDirection = (translation.y > fabsf(translation.x))?NTDCardPanningVerticalDirection : NTDCardPanningHorizontalDirection;
            
                // if we are in the process of swiping down
                if (self.cardPanningDirection == NTDCardPanningVerticalDirection
                    && velocity.y > 0) {
                    // and the textview is scrolled to the top or further
                    if (self.visibleCell.textView.contentOffset.y <= 0) {
                        
                        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                            self.visibleCell.textView.panGestureRecognizer.enabled = NO;
                        } else {
                            // animate it to a content offset of 0 and disable scrolling
                            [UIView animateWithDuration:.2 animations:^{
                                // animates the contentoffset to CGPointZero
                                self.visibleCell.textView.scrollEnabled = NO;
                            }];
                        }
                    } else {
                        panGestureRecognizer.enabled = NO;
                    }
                }
            }
            
            switch (self.cardPanningDirection) {
                case NTDCardPanningHorizontalDirection:
                    /* This bit of logic exists to make dragging text and horizontally panning cards
                     * mutually exclusive. So if we're currently dragging, don't start panning. And when
                     * we do start panning, prevent future dragging. */
                    if (!self.visibleCell.textView.dragging) {
                        self.pagingLayout.pannedCardXTranslation = translation.x;
                        self.visibleCell.textView.scrollEnabled = NO;
                    }
                    break;
                case NTDCardPanningVerticalDirection:
                {
                    CGFloat y = translation.y *.4;
                    if (y < self.pullToCreateContainerView.$height) {
                        self.pullToCreateContainerView.$y = y-self.pullToCreateContainerView.$height;
                    } else {
                        self.pullToCreateContainerView.$y = 0;
                    }
                    self.pagingLayout.pannedCardYTranslation = y;

                    break;
                }
                    
                default:
                    break;
            }
            
            
            if (!self.hasTwoFingerNoteDeletionBegun)
                [self.pagingLayout invalidateLayout];
            
            // if we are at the end or beginning of the stack, cancel the touch early to indicate that the user has reached the limit.
            CGFloat cancelTouchLimit = self.view.frame.size.width * 0.67 ;
            if ((self.visibleCardIndexPath.item == 0 && translation.x > cancelTouchLimit) ||
                (self.visibleCardIndexPath.item == self.notes.count-1 && translation.x < -cancelTouchLimit))
                panGestureRecognizer.enabled = NO;
            break;
            
        case UIGestureRecognizerStateEnded :
        {
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                self.visibleCell.textView.panGestureRecognizer.enabled = YES;
            }
            self.visibleCell.textView.scrollEnabled = YES;
            

            switch (self.cardPanningDirection) {
                case NTDCardPanningHorizontalDirection:
                {
                    // check if translation is past threshold
                    if (fabs(translation.x) >= self.collectionView.frame.size.width/2) {
                        // left
                        if (translation.x < 0)
                            newIndex ++ ;
                        else
                            newIndex -- ;
                        
                        // check for a swipe
                    } else if (fabs(velocity.x) > SwipeVelocityThreshold
                               && fabs(velocity.x) > fabs(velocity.y)) {
                        // left
                        if (velocity.x < 0 && translation.x < 0)
                            newIndex ++ ;
                        else if (velocity.x > 0 && translation.x > 0)
                            newIndex -- ;
                    }
                    
                    // make sure we stay within bounds
                    newIndex = CLAMP(newIndex, 0, (int)[self.collectionView numberOfItemsInSection:0]-1);
                    self.pagingLayout.activeCardIndex = newIndex ;
                    [self finishAnimationForVisibleCardWithVelocity:velocity.x completion:nil];

                    break;
                }
                case NTDCardPanningVerticalDirection:
                {                    
                    BOOL shouldCreateNewCard = (-self.pagingLayout.pannedCardYTranslation <= self.listLayout.pullToCreateCreateCardOffset);
                    
                    if (shouldCreateNewCard) {
                        CGFloat panSpeed = fabsf(velocity.y) - 30;
                        CGFloat panPosition = fabsf(translation.y);
                        CGFloat panDuration = panPosition / panSpeed;
                        
                        NSTimeInterval duration = panDuration;
                        duration = CLAMP(duration, 0.2, 0.6);
                        
                        // finish the pull and reveal the new card
                        [self insertNewCardWithDuration:duration];
                        self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
                    } else {
                        
                        // return the card to the top
                        [self finishAnimationForVisibleCardWithVelocity:velocity.y completion:^{
                            self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
                        }];
                    }
                    
                    break;
                }
                
                    
                    
                default:
                    self.visibleCell.textView.scrollEnabled = YES;
                    break;
            }
            
            self.cardPanningDirection = NTDCardPanningNoDirection;
            
            
            break;
        }
            
        case UIGestureRecognizerStateFailed :
        case UIGestureRecognizerStateCancelled :
        {
            self.cardPanningDirection = NTDCardPanningNoDirection;
            panGestureRecognizer.enabled = YES;
            self.visibleCell.textView.scrollEnabled = YES;

            [self finishAnimationForVisibleCardWithVelocity:velocity.y completion:^{
                self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
            }];
        }
        default:
            break;
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
            self.pagingLayout.pannedCardXTranslation = translation.x < 0 ? MAX(-self.pagingLayout.currentOptionsOffset, translation.x) : 0;
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
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bugfix for recognizing taps inside the options section
        CGPoint tapLoc = [tapGestureRecognizer locationInView:self.view];
        BOOL touchIsInsideOptions = tapLoc.x < self.pagingLayout.currentOptionsOffset;
        if (!touchIsInsideOptions)
            [self closeOptionsWithVelocity:.2];
    }
}

- (IBAction)squeezeLastNote:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    if (self.notes.count != 1)
        return;
    
    static CGFloat initialDistance = 0.0f, endDistance = 130.0f;
    
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (pinchGestureRecognizer.velocity > 0) {
                pinchGestureRecognizer.enabled = NO;
                break;
            } else {
                initialDistance = PinchDistance(pinchGestureRecognizer);
            }
            
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            
            pinchRatio = CLAMP(pinchRatio, 0, 1);
            self.pagingLayout.pinchRatio = pinchRatio;
            
            // if pinched more than Cutoff, cancel the gesture
            static CGFloat Cutoff = 0.45;
            if (pinchRatio < Cutoff)
                pinchGestureRecognizer.enabled = NO;
            else
                // update the affine transform
                [self.pagingLayout invalidateLayout];
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self.pagingLayout finishAnimationWithVelocity:pinchGestureRecognizer.velocity completion:nil];
            pinchGestureRecognizer.enabled = YES;
            break;
            
        default:
            break;
    }

}

- (IBAction)pinchToListLayout:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    // special case squeezing when there is only one card
    if (self.notes.count == 1)
        return [self squeezeLastNote:pinchGestureRecognizer];

    static CGFloat initialDistance = 0.0f, endDistance = 130.0f;
    static CGPoint initialContentOffset;
    
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (pinchGestureRecognizer.velocity > 0) {
                pinchGestureRecognizer.enabled = NO;
                break;
            } else {
                initialDistance = PinchDistance(pinchGestureRecognizer);
            }
            
            NSIndexPath *visibleCardIndexPath = [NSIndexPath indexPathForItem:self.pagingLayout.activeCardIndex inSection:0 ];
            self.listLayout.pinchStartedInListLayout = (self.collectionView.collectionViewLayout == self.listLayout);
            self.listLayout.pinchedCardIndexPath = visibleCardIndexPath;
            self.listLayout.pinchRatio = (self.listLayout.pinchStartedInListLayout) ? 0.0 : 1.0;
            if (self.listLayout.pinchStartedInListLayout) {
                CGPoint touchPoint = [pinchGestureRecognizer locationInView:self.collectionView];
                self.listLayout.pinchedCardIndexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
            }
            [self.pinchedCell doNotHideSettingsForNextLayoutChange];
            
            initialContentOffset = self.collectionView.contentOffset;
            [self updateLayout:self.listLayout
                      animated:NO];
            
            if (!self.listLayout.pinchStartedInListLayout) {
                CGFloat returnCardToContentOffset = CLAMP((visibleCardIndexPath.row * self.listLayout.cardOffset) - self.collectionView.frame.size.height/3,
                                                          0,
                                                          self.collectionView.contentSize.height - self.collectionView.frame.size.height);
                [self.collectionView setContentOffset:CGPointMake(0, returnCardToContentOffset) animated:NO];
                self.collectionView.scrollEnabled = NO;
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            // don't do anything when we have none left
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            
            if (self.listLayout.pinchStartedInListLayout) {
                CGFloat offset, adjustedPinchRatio = pinchRatio - 1, minRatioCutoff = -0.05;// maxRatioCutoff = 0.1;
                if (adjustedPinchRatio < minRatioCutoff) {
                    offset = adjustedPinchRatio - minRatioCutoff;
                    adjustedPinchRatio = minRatioCutoff + offset/10;
                } else if (adjustedPinchRatio > 0.1) {
                    offset = adjustedPinchRatio - 0.1;
                    adjustedPinchRatio = 0.1 + offset/10;
                }
                pinchRatio = CLAMP(adjustedPinchRatio, -0.2, 0.2);
            } else {
                self.pinchedCell.settingsButton.alpha = CLAMP(pinchRatio, 0, 1) ;
            }
            self.listLayout.pinchRatio = pinchRatio;
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);

            BOOL shouldReturnToPagingLayout = (pinchRatio > 0.0 && pinchGestureRecognizer.velocity > -PinchVelocityThreshold);
            shouldReturnToPagingLayout &= !self.listLayout.pinchStartedInListLayout;
            
            if (shouldReturnToPagingLayout) {
                [self updateLayout:self.pagingLayout
                          animated:NO];
                [self.collectionView setContentOffset:initialContentOffset animated:NO];
            } else {
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
    self.transitioningToPagingLayout = YES;
    NTDCollectionViewCell *selectedCell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self setBodyForCell:selectedCell atIndexPath:indexPath];
    
    CGFloat topOffset = selectedCell.frame.origin.y - self.collectionView.contentOffset.y;
    CGFloat bottomOffset = self.collectionView.frame.size.height - (topOffset + self.listLayout.cardOffset);

    void (^animationBlock)() = ^{
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
    };
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        self.pagingLayout.activeCardIndex = indexPath.item;
        [self updateLayout:self.pagingLayout
                  animated:NO];
        self.transitioningToPagingLayout = NO;

    };
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        for (NTDCollectionViewCell *cell in self.collectionView.visibleCells) {
            [self removeMotionEffects:cell atIndexPath:nil];
        }
        [UIView animateWithDuration:.4
                              delay:0
             usingSpringWithDamping:.7
              initialSpringVelocity:-10
                            options:UIViewAnimationCurveEaseInOut  | UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        [UIView animateWithDuration:.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:completionBlock];
    }
    
}

//-(void)setNotes:(NSMutableArray *)notes
//{
//    if (_notes) {
//        NSLog(@"Changing notes from %p to %p", _notes, notes);
//        NSLog(@"Old Notes: %@", _notes);
//    }
//    NSLog(@"New Notes: %@", notes);
//    _notes = notes;
//}

- (IBAction)showSettings:(id)sender
{
    if (self.visibleCell.layer.animationKeys != nil) return;
    
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughTapOptionsStep];
    
    NTDCollectionViewCell *visibleCell = self.visibleCell;
    
    /* Get selected text.*/
    NSRange selectedRange = visibleCell.textView.selectedRange;
    if (selectedRange.length == 0) {
        self.optionsViewController.selectedText = nil;
    } else {
        NSString *selectedText = [visibleCell.textView.text substringWithRange:selectedRange];
        self.optionsViewController.selectedText = selectedText;
    }
    
    /* Don't let user interact with anything but our options. */
    visibleCell.textView.editable = NO;
    self.panCardWhileViewingOptionsGestureRecognizer.enabled = YES;

    [self.visibleCell addGestureRecognizer:self.tapCardWhileViewingOptionsGestureRecognizer];
    self.tapCardWhileViewingOptionsGestureRecognizer.enabled = YES;
    
    self.twoFingerPanGestureRecognizer.enabled = NO;
    self.pinchToListLayoutGestureRecognizer.enabled = NO;
    
    self.optionsViewController.view.frame = visibleCell.frame;
    self.optionsViewController.note = [self noteAtIndexPath:self.visibleCardIndexPath];
    [self addChildViewController:self.optionsViewController];
    [self.collectionView insertSubview:self.optionsViewController.view belowSubview:visibleCell];
    [self.optionsViewController didMoveToParentViewController:self];
    self.optionsViewController.view.layer.transform = CATransform3DMakeTranslation(0, 0, self.pagingLayout.activeCardIndex);
    
    [self.optionsViewController reset];
    
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
        self.collectionView.scrollEnabled = NO;
        self.collectionView.scrollsToTop = NO;
        
    } else if (layout == self.listLayout) {
        self.selectCardGestureRecognizer.enabled = YES;
        self.removeCardGestureRecognizer.enabled = YES;
        self.panCardGestureRecognizer.enabled = NO;
        self.twoFingerPanGestureRecognizer.enabled = NO;
        self.collectionView.scrollEnabled = YES;
        self.collectionView.scrollsToTop = YES;

        self.view.$width = [[UIScreen mainScreen] bounds].size.width;
    }
    [self.collectionView reloadData];
}

- (void)animateSwipedCellToOriginalPosition {
    self.listLayout.swipedCardIndexPath = nil;
    self.oneFingerDeletionDirection = NTDDeletionDirectionNoDirection;
    [self.collectionView performBatchUpdates:nil completion:nil];

}

- (void)finishAnimationForVisibleCardWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock {
    self.visibleCell.textView.userInteractionEnabled = NO;
    [self.pagingLayout finishAnimationWithVelocity:velocity completion:^{
        self.visibleCell.textView.userInteractionEnabled = YES;
        if (completionBlock)
            completionBlock();
    }];
}

- (void)insertNewCardWithDuration:(NSTimeInterval)duration
{
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughMakeANoteStep];
    [self pretendPullToCreateCardIsANewNote];
    
    BOOL isListLayout = (self.collectionView.collectionViewLayout == self.listLayout);
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         // reveal new card
                         NSArray *indexPaths = [self.collectionView indexPathsForVisibleItems];
                         for (NSIndexPath *visibleIndexPath in indexPaths) {
                             NTDCollectionViewCell *cell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:visibleIndexPath];
                             cell.$y += self.collectionView.$height;
                         }
                     } completion:^(BOOL finished) {
                         // repleace dummy card
                         [NTDNote newNoteWithCompletionHandler:^(NTDNote *note) {
                             [self.notes insertObject:note atIndex:0];
                             self.pagingLayout.activeCardIndex = 0;
                             self.pagingLayout.pannedCardYTranslation = 0;
                             self.pagingLayout.pinchRatio = 1;
                             //self.visibleCell.$y = 0; /* Hack for iOS 7.1 during 2nd step of walkthrough. Card was at (0,568) for some reason. */
                             
                             if (isListLayout)
                                 [self updateLayout:self.pagingLayout animated:NO];
                             else
                                 [self.collectionView reloadData];
                                 
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.visibleCell.textView becomeFirstResponder];
                                 if (isListLayout)
                                     [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughMakeANoteStep];
                             });
                         }];
                     }];    
}

- (void)pretendPullToCreateCardIsANewNote {
    NSMutableArray *subviews = [[self.collectionView subviews] mutableCopy];
    for (UIView *view in subviews) {
        /* Search for & edit the 'pull to create card' cell. */
        if ([view isKindOfClass:[NTDCollectionViewCell class]]) {
            NTDCollectionViewCell *cell = (NTDCollectionViewCell *)view;
            if ([cell.textView.text isEqualToString:@"Release to create a note"]) {
                cell.relativeTimeLabel.text = @"Today";
            }
        }
    }
}

- (void)restoreCard:(NTDDeletedNotePlaceholder *)restoredNote
{
    NSIndexPath *indexPath = restoredNote.indexPath;
    self.pagingLayout.activeCardIndex = indexPath.item;
    
    // if in list layout, set the indexpath and the offset
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        self.listLayout.swipedCardIndexPath = indexPath;
        self.listLayout.swipedCardOffset = (restoredNote.deletionDirection == NTDDeletionDirectionRight) ? 150 : -150;
    
        /* fixes the 'two cards animate back in' bug. */
        [UIView setAnimationsEnabled:NO];
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [UIView setAnimationsEnabled:YES];
        
        CGFloat insertedCellScrollPos = self.listLayout.cardOffset * indexPath.item;
        
        if (insertedCellScrollPos < self.collectionView.contentOffset.y
            || insertedCellScrollPos >= self.collectionView.contentOffset.y + self.collectionView.frame.size.height)
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        
        [self animateSwipedCellToOriginalPosition];
        [self adjustMotionEffects];
    } else if (restoredNote.savedColumnsForDeletion == nil) {
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    } else {
        [self restoreShreddedNote:restoredNote];
    }
}

- (void)deleteCardAtIndexPath:(NSIndexPath *)indexPath
{
    NTDNote *note = [self noteAtIndexPath:indexPath];
    NTDDeletedNotePlaceholder *deletedNote = [[NTDDeletedNotePlaceholder alloc] initWithNote:note];
    deletedNote.indexPath = indexPath;
    deletedNote.savedColumnsForDeletion = self.columnsForDeletion;
    deletedNote.deletionDirection = (self.collectionView.collectionViewLayout == self.listLayout) ? self.oneFingerDeletionDirection : self.twoFingerDeletionDirection;
    self.columnsForDeletion = nil;
    [self.deletedNotesStack addObject:deletedNote];
    
    [self.notes removeObject:note];
    [note deleteWithCompletionHandler:nil];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        if (indexPath.item == self.notes.count) {
            [self.collectionView reloadItemsAtIndexPaths:@[[indexPath ntd_indexPathForPreviousItem]]];
        }
    } completion:^(BOOL finished) {
        [self showShakeToUndoModalIfNecessary];
        [NTDDropboxManager deleteNoteFromDropbox:note]; // KAK TODO
    }];
}

- (void) restoreDeletedNote {
    // moved this method here because it involves inserting into the notes array
    if (self.deletedNotesStack.count == 0) {
        [self showToastWithMessage:@"There's nothing to restore!"];
    } else {
        NTDDeletedNotePlaceholder *restoredNote = [self.deletedNotesStack lastObject];
        [NTDNote restoreNote:restoredNote completionHandler:^(NTDNote *note) {
            NSUInteger newIndex = MIN(restoredNote.indexPath.item, self.notes.count);
            [self.notes insertObject:note atIndex:newIndex];
            restoredNote.indexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];
            [self.deletedNotesStack removeLastObject];
            [self restoreCard:restoredNote];
        }];
    }
}


- (NTDNote *)noteAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath);
    NSAssert(indexPath.item < self.notes.count, @"!(%ld < %lu)", (long)indexPath.item, (unsigned long)self.notes.count);
    if (indexPath.item >= self.notes.count)
        [NSException raise:NSInvalidArgumentException format:@"!(%d < %d)", (int)indexPath.item, (int)self.notes.count];
    return self.notes[indexPath.item];
}

- (NSIndexPath *)indexPathForNote:(NTDNote *)note
{
    NSUInteger index = [self.notes indexOfObject:note];
    if (index == NSNotFound) {
        NSLog(@"Couldn't find note %@", note);
        return nil;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    return indexPath;
}

- (void)setBodyForCell:(NTDCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    /* We take `cell` as a parameter because `-[UICollectionView cellForItemAtIndexPath:]`
     * returns `nil` inside of `collectionView:cellForItemAtIndexPath:`. */
    NTDNote *note = [self noteAtIndexPath:indexPath];
    NTDCollectionViewCell __weak *weakCell = cell;
    if (note.fileState != NTDNoteFileStateOpened) {
//        NSLog(@"%s: opening note #%d\n", __FUNCTION__, indexPath.item);
        [note openWithCompletionHandler:^(BOOL success) {
            if ([weakCell.textView.text isEqualToString:note.headline])
                weakCell.textView.text = note.text;
//            else
//                NSLog(@"Cell doesn't have proper headline: %@", weakCell.textView.text);
        }];
    } else {
        weakCell.textView.text = note.text;
    }
}

- (void)reloadNotes
{
    dispatch_group_enter(self.note_refresh_group);
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
        self.notes = [notes mutableCopy];
        self.deletedNotesStack = [NSMutableArray array];
        if (self.notes.count == 0) {
            [self addDefaultNotesIfNecessary];
        } else if (self.notes.count == 1) {
            self.pagingLayout.activeCardIndex = 0;
            [self.collectionView reloadData]; /* fixes an EXC_BAD_ACCESS crash when using Dropbox. No clue why. */
            [self updateLayout:self.pagingLayout animated:NO];
        } else {
            [self.collectionView reloadData];
        }
        dispatch_group_leave(self.note_refresh_group);
    }];
}

- (void)addDefaultNotesIfNecessary
{
    
    NSArray *initialNotes = @[
                              @"“The best art makes your head spin with questions. Perhaps this is the fundamental distinction between pure art and pure design. While great art makes you wonder, great design makes things clear.” ― John Maeda",
                              @"“I am not a genius, I am just curious. I ask many questions. And when the answer is simple, then God is answering.” ― Albert Einstein",
                              @"“Truth is ever to be found in the simplicity, and not in the multiplicity and confusion of things.” ― Isaac Newton",
                              @"“That’s been one of my mantras – focus and simplicity. Simple can be harder than complex. You have to work hard to get your thinking clean to make it simple. But it’s worth it in the end because once you get there, you can move mountains.” ― Steve Jobs",
                              @"“Good design is a lot like clear thinking made visual.” ― Edward Tufte",
                              @"“It is not a daily increase, but a daily decrease. Hack away at the inessentials.” ― Bruce Lee",
                              ];
    
    NSArray *initialThemes = @[
                               [NTDTheme themeForColorScheme:NTDColorSchemeWhite],
                               [NTDTheme themeForColorScheme:NTDColorSchemeSky],
                               [NTDTheme themeForColorScheme:NTDColorSchemeLime],
                               [NTDTheme themeForColorScheme:NTDColorSchemeShadow],
                               [NTDTheme themeForColorScheme:NTDColorSchemeTack],
                               [NTDTheme themeForColorScheme:NTDColorSchemeKernal]
                               ];
    
    if (self.notes.count == 0) {
        dispatch_group_enter(self.note_refresh_group);
        [NTDNote newNotesWithTexts:initialNotes themes:initialThemes completionHandler:^(NSArray *notes) {
            self.notes = [notes mutableCopy];
            [self.collectionView reloadData];
            dispatch_group_leave(self.note_refresh_group);
        }];
    }

//    if (!self.panCardWhileViewingOptionsGestureRecognizer.isEnabled) {
//        [self.collectionView reloadData];
//    }
}

- (BOOL)shouldShowBodyForNoteAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.collectionViewLayout == self.pagingLayout)
        return YES;
    
    if ([self.listLayout.pinchedCardIndexPath isEqual:indexPath])
        return YES;
    
    BOOL isFinalCell = (self.notes.count > 0) && (indexPath.item == self.notes.count-1);

    if (isFinalCell)
        return YES;
    
    return NO;
}

- (NSArray *)visibleCells
{
    return [self.collectionView.subviews bk_select:^BOOL(UIView *view) {
        return [view isKindOfClass:[NTDCollectionViewCell class]];
    }];
}

#pragma mark - Motion Effects
- (void)addMotionEffects:(NTDCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"adding motion effects: (%d) %p", indexPath.item, cell);
    UIInterpolatingMotionEffect *effect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"frame.origin.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    effect.minimumRelativeValue = @(-10 * indexPath.item);
    effect.maximumRelativeValue = @(10 * indexPath.item);
    [cell addMotionEffect:effect];
}

- (void)removeMotionEffects:(NTDCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"removing motion effects: (%d) %p", indexPath.item, cell);
    for (UIMotionEffect *effect in cell.motionEffects) [cell removeMotionEffect:effect];
}

- (void)adjustMotionEffects
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) return;
    
    CGFloat verticalContentOffset = self.collectionView.contentOffset.y;
    for (NTDCollectionViewCell *cell in self.collectionView.visibleCells) {
//        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        CGFloat offset = cell.$y - verticalContentOffset;
//        if (offset < 0) {
//            [self removeMotionEffects:cell atIndexPath:indexPath];
//            continue;
//        }
        NSInteger index = floor(offset / (int)self.listLayout.cardOffset);
//        if (cell.motionEffects.count == 0) {
//            [self addMotionEffects:cell atIndexPath:indexPath];
//        }
        if (index < 0 || cell.motionEffects.count == 0) continue;
        UIInterpolatingMotionEffect *effect = cell.motionEffects[0];
        effect.minimumRelativeValue = @(-10 * index);
        effect.maximumRelativeValue = @(10 * index);
    }
}

#pragma mark - Notifications
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
    
    // [UIView animateWithDuration:0.25 animations:^{
    //     animations are very jarring; so disabled for now.
    //     they cause a bunch of strange view artifacts.
    self.view.frame = newViewFrame;
    self.optionsViewController.view.frame = newOptionsFrame;
    // }];
}

- (void)mayShowNoteAtIndexPath:(NSNotification *)notification
{
    //TODO fix this when I start closing files again.
    //PS why in the world am I not closing files?
    static NSMutableSet *visitedPaths;
    if (!visitedPaths) visitedPaths = [NSMutableSet set];
    
    NSIndexPath *indexPath = notification.object;
    if ([visitedPaths containsObject:indexPath])
        return;
    
    NTDNote *note = [self noteAtIndexPath:indexPath];
//    NSLog(@"checking state of note #%d", indexPath.item);
    if (note.fileState != NTDNoteFileStateOpened) {
        [visitedPaths addObject:indexPath];
//        NSLog(@"%s: opening note #%d\n", __FUNCTION__, indexPath.item);
        [note openWithCompletionHandler:NULL];
    }
}

#pragma mark NTDNote
- (void)noteWasUpdated:(NSNotification *)notification
{
    NTDNote *note = notification.object;
    NSIndexPath *indexPath = [self indexPathForNote:note];
    if ([self shouldShowBodyForNoteAtIndexPath:indexPath]) { /* this isn't selective enough. in paging layout we should be visible. */
        NTDCollectionViewCell *cell = (NTDCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [note updateWithCompletionHandler:^(BOOL success) {
                cell.relativeTimeLabel.text = [Utilities formatRelativeDate:note.lastModifiedDate];
                cell.dateCreated = note.lastModifiedDate;
                cell.textView.text = note.text;
                [cell applyTheme:note.theme];
            }];
        }
    } else {
        // If we don't have to do a full update, we at least need to re-render the note.
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

- (void)noteWasDeleted:(NSNotification *)notification
{
    NTDNote *note = notification.object;
    NSIndexPath *indexPath = [self indexPathForNote:note];
    [self.notes removeObject:note];
    if (indexPath) {
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } else {
        NSLog(@"Received a 'note deleted' notification, but couldn't find the note. %@", note);
    }
    if (self.notes.count == 0) {
        [NTDNote newNoteWithText:@"" theme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite] completionHandler:^(NTDNote *note) {
            [self.notes addObject:note];
            [self.collectionView reloadData];
            self.pagingLayout.activeCardIndex = 0;
            [self updateLayout:self.pagingLayout animated:NO];
        }];
    }
}

- (void)noteWasAdded:(NSNotification *)notification
{
    
    NTDNote *note = notification.object;
    if ([self.notes containsObject:note]) {
        NSLog(@"Received a 'note added' notification, but we already have the note. %@", note);
        return;
    } else {
        [note openWithCompletionHandler:^(BOOL success) {
            NSInteger i = [NTDNote indexForNote:note amongNotes:self.notes];
            NSLog(@"New note %@ should be placed at index %ld", note.filename, (long)i);
            [self.notes insertObject:note atIndex:i];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // if the scrollview
    if (otherGestureRecognizer.view == self.visibleCell.textView
        && gestureRecognizer == self.panCardGestureRecognizer) {
        if (self.visibleCell.textView.contentOffset.y <= 0)
            return YES;
    }
    
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
    
    // This keyboard function doesn't work as expected, and crashes in many cases
    /*if (scrollView == self.visibleCell.textView &&
        [self.visibleCell.textView isFirstResponder] &&
        SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        CGRect keyboardFrame = [self keyboardFrame];
        [self keyboardWasPannedToFrame:[self.visibleCell.textView convertRect:keyboardFrame
                                                                     fromView:[[UIApplication sharedApplication] keyWindow]]];
    }*/
    
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
    CGFloat IndicatorWidth = 7.0;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        IndicatorWidth = 3.5;
    UIView *possibleIndicatorView = [[scrollView subviews] lastObject];
    if ([possibleIndicatorView isKindOfClass:[UIImageView class]] &&
        possibleIndicatorView.$width == IndicatorWidth) {
        if (CATransform3DIsIdentity(possibleIndicatorView.layer.transform))
            possibleIndicatorView.layer.zPosition = CGFLOAT_MAX;
    }
    
    [self adjustMotionEffects];
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
    if (scrollView != self.collectionView)
        return;

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
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        textView.alwaysBounceVertical = YES;
    } else {
        [textView addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
            [self keyboardWasPannedToFrame:keyboardFrameInView];
        }];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [[self noteAtIndexPath:self.visibleCardIndexPath] setText:textView.text];
    [Flurry logEvent:@"Note Edited" withParameters:@{@"length" : @(textView.text.length)}];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        textView.alwaysBounceVertical = NO;
    }
    self.panCardGestureRecognizer.enabled = YES;
    self.twoFingerPanGestureRecognizer.enabled = YES;
    self.pinchToListLayoutGestureRecognizer.enabled = YES;
}

#pragma mark - Keyboard Handling
static BOOL keyboardIsBeingShown;
- (void)keyboardWasShown:(NSNotification*)notification
{
    /* This particular nightmare is necessary because a UIKeyboardDidShow notification is
        is sent right before a UIKeyboardWillHide notification. Jesus Christ. */
    if (keyboardIsBeingShown) return;
    keyboardIsBeingShown = YES;
    
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) return;
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UITextView *textView = self.visibleCell.textView;
    
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    contentInset.bottom += keyboardSize.height;
    textView.contentInset = contentInset;
    textView.scrollIndicatorInsets = contentInset;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UITextPosition *textPosition = [textView positionWithinRange:textView.selectedTextRange farthestInDirection:UITextLayoutDirectionRight];
        CGRect caretRect = [textView caretRectForPosition:textPosition];
//        CGPoint caretBottomPoint = CGPointMake(0, CGRectGetMaxY(caretRect));
        caretRect.size.height *= 2;
        
//        [textView scrollRangeToVisible:textView.selectedRange]; /* doesn't work  */
//        [textView scrollRectToVisible:caretRect animated:YES]; /* doesn't work */
        [textView scrollRectToVisible:caretRect animated:NO]; /*works */
//        [textView setContentOffset:caretBottomPoint animated:NO]; /* works */
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    [UIView animateWithDuration:duration
                          delay:0
                        options:(curve << 16)
                     animations:^{
                         self.visibleCell.textView.contentInset = self.visibleCell.textView.scrollIndicatorInsets = UIEdgeInsetsZero;
                     } completion:^(BOOL finished) {
                     }];

    [self.visibleCell applyMaskWithScrolledOffset:0];
    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughSwipeToCloseKeyboardStep];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughSwipeToCloseKeyboardStep];
    keyboardIsBeingShown = FALSE;
}

- (void)keyboardWasPannedToFrame:(CGRect)frame
{
    UITextView *textView = self.visibleCell.textView;
    UIEdgeInsets contentInset = textView.contentInset;
    contentInset.bottom = textView.$height - (frame.origin.y - textView.contentOffset.y);
    textView.contentInset = contentInset;
    textView.scrollIndicatorInsets = contentInset;
}

- (CGRect)keyboardFrame
{
    NSAssert(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"), @"You should only call this on iOS 7 or above.");
    NSMutableArray *windows = [[[UIApplication sharedApplication] windows] mutableCopy];
    [windows removeObject:[[UIApplication sharedApplication] keyWindow]];
    
    for (UIWindow *window in windows) {
        if (![window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) continue;

        UIView *peripheralHostView = window.subviews[0];
        if ( [peripheralHostView isKindOfClass:NSClassFromString(@"UIPeripheralHostView")] ||
            [peripheralHostView isKindOfClass:NSClassFromString(@"UIInputSetContainerView")] ) {
            return [[[UIApplication sharedApplication] keyWindow] convertRect:peripheralHostView.frame
                                                               fromWindow:window];
        }
    }
    
    NSAssert(FALSE, @"Wasn't able to find keyboard frame. Bailing");
    return CGRectZero;
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
    [Flurry logEvent:@"Theme Changed" withParameters:@{@"theme": [self.optionsViewController.note.theme themeName]}];
}

- (void)dismissOptions
{
    [self closeOptionsWithVelocity:.2];
}

- (void)closeOptionsWithVelocity:(CGFloat)velocity
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0") && fabs(velocity - 0.2) <= 0.001 ) velocity = 1600;

    [NTDWalkthrough.sharedWalkthrough stepShouldEnd:NTDWalkthroughCloseOptionsStep];
    /* We need this coverup view b/c in iOS 7, if you tap to close from Settings or About, 
     * you'll see the right edge of the options view while the bounce animation runs. */
    UIView *coverupView = [[UIView alloc] initWithFrame:self.optionsViewController.view.frame];
    coverupView.$left = coverupView.center.x;
    coverupView.backgroundColor = [UIColor blackColor];
    coverupView.layer.transform = self.optionsViewController.view.layer.transform;
    [self.collectionView insertSubview:coverupView aboveSubview:self.optionsViewController.view];
    [self.pagingLayout hideOptionsWithVelocity:velocity completion:^{
        self.panCardWhileViewingOptionsGestureRecognizer.enabled = NO;
        self.tapCardWhileViewingOptionsGestureRecognizer.enabled = NO;
        
        self.visibleCell.textView.editable = YES;
        self.pinchToListLayoutGestureRecognizer.enabled = YES;
        self.twoFingerPanGestureRecognizer.enabled = YES;
        [self.optionsViewController willMoveToParentViewController:nil];
        [self.optionsViewController.view removeFromSuperview];
        [self.optionsViewController removeFromParentViewController];
        [self.optionsViewController reset];
        [coverupView removeFromSuperview];
        [NTDWalkthrough.sharedWalkthrough shouldAdvanceFromStep:NTDWalkthroughCloseOptionsStep];
    }];
}

#pragma mark - NTDPagingCollectionViewLayoutDelegate
- (NSInteger)numberOfNotes {
    return self.notes.count;
}

@end
