
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
#import "NoteCollectionViewController.h"
#import "NoteListCollectionViewLayout.h"
#import "NoteCollectionViewCell.h"
#import "UIView+FrameAdditions.h"
#import "ApplicationModel.h"
#import "NoteEntry.h"
#import "NTDPagingCollectionViewLayout.h"
#import "NTDCrossDetectorView.h"
#import "NoteData.h"
#import "NoteDocument.h"
#import "NTDNoteSettingsViewController.h"
#import "DAKeyboardControl.h"
#import "NSIndexPath+NTDManipulation.h"
#import "OptionsViewController.h"

@interface NoteCollectionViewController () <UIGestureRecognizerDelegate, UITextViewDelegate, NTDCrossDetectorViewDelegate, NoteCollectionViewCellDelegate, NTDNoteSettingsViewControllerDelegate, OptionsViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
@property (nonatomic, strong) NoteListCollectionViewLayout *listLayout;
@property (nonatomic, strong) NTDPagingCollectionViewLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) UIView *pullToCreateContainerView;
@property (nonatomic, strong, readonly) NoteCollectionViewCell *visibleCell;

@property (nonatomic, strong) UIPanGestureRecognizer *removeCardGestureRecognizer, *panCardGestureRecognizer, *panCardWhileViewingOptionsGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *selectCardGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchToListLayoutGestureRecognizer;

@property (nonatomic, assign) NSUInteger noteCount;
@property (nonatomic, strong) NSIndexPath *pullToCreateCardIndexPath;
@property (nonatomic, assign) BOOL shouldShowPullToCreateCard;
@property (nonatomic, assign) CGRect initialFrameForVisibleNoteWhenViewingOptions;

@property (nonatomic, strong) NTDNoteSettingsViewController *currentNoteSettingsController;
@property (nonatomic, strong) OptionsViewController *optionsViewController;
@property (nonatomic, strong) MFMailComposeViewController *mailViewController;
@end

NSString *const NoteCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";
NSString *const NoteCollectionViewDuplicateCardReuseIdentifier = @"NoteCollectionViewDuplicateCardReuseIdentifier";

static const CGFloat SettingsTransitionDuration = 0.5;
static const CGFloat InitialNoteOffsetWhenViewingOptions = 96.0;

@implementation NoteCollectionViewController

- (id)init
{
    NoteListCollectionViewLayout *initialLayout = [[NoteListCollectionViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:initialLayout];
    if (self) {
        self.listLayout = initialLayout;
        self.pagingLayout = [[NTDPagingCollectionViewLayout alloc] init];
        self.pagingLayout.itemSize = initialLayout.cardSize;

        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.allowsSelection = NO;
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier];
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forSupplementaryViewOfKind:NTDCollectionElementKindDuplicateCard withReuseIdentifier:NoteCollectionViewDuplicateCardReuseIdentifier];

        self.pullToCreateCardIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        self.shouldShowPullToCreateCard = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupPullToCreate];
    
    SEL selector = @selector(handleRemoveCardGesture:);
    self.removeCardGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:selector];
    self.removeCardGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.removeCardGestureRecognizer];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCardTap:)];
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.selectCardGestureRecognizer = tapGestureRecognizer;
    UIPanGestureRecognizer *panGestureRecognizer;
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCard:)];
    panGestureRecognizer.enabled = NO;
    panGestureRecognizer.delegate = self;
    self.panCardGestureRecognizer = panGestureRecognizer;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    UIPinchGestureRecognizer *pinchGestureRecognizer;
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchToListLayout:)];
    pinchGestureRecognizer.enabled = NO;
    self.pinchToListLayoutGestureRecognizer = pinchGestureRecognizer;
    [self.collectionView addGestureRecognizer:pinchGestureRecognizer];
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCardWhileViewingOptions:)];
    panGestureRecognizer.enabled = NO;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    self.panCardWhileViewingOptionsGestureRecognizer = panGestureRecognizer;
    
    self.noteCount = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarFrameChanged:)
                                                 name:NTDDidChangeStatusBarHiddenPropertyNotification
                                               object:nil];
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
    return (int)self.shouldShowPullToCreateCard + self.noteCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    cell.textView.delegate = self;
    cell.crossDetectorView.delegate = self;
    cell.delegate = self;
    
    [cell.actionButton addTarget:self
                          action:@selector(actionButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [cell.settingsButton addTarget:self
                            action:@selector(showSettings:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    if (indexPath.item == 0 && self.shouldShowPullToCreateCard) {
        cell.titleLabel.text = @"Release to create note";
        cell.relativeTimeLabel.text = @"";
        cell.textView.text = @"";
        [cell applyTheme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite]];        
    } else {
        NSInteger index = [self noteEntryIndexForIndexPath:indexPath];
        NoteEntry *entry = [[ApplicationModel sharedInstance] noteAtIndex:index];
        cell.titleLabel.text = [entry title];
        cell.relativeTimeLabel.text = entry.relativeDateString;
        cell.textView.text = entry.text;
        [cell applyTheme:[NTDTheme themeForBackgroundColor:entry.noteColor]];
    }
    [cell willTransitionFromLayout:nil toLayout:collectionView.collectionViewLayout];
    return cell;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:NTDCollectionElementKindDuplicateCard]) {
        NoteCollectionViewCell *cell = (NoteCollectionViewCell *) [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        cell.textView.delegate = nil;
        cell.crossDetectorView.delegate = nil;
        cell.delegate = nil;
        [cell.actionButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
//        [cell applyTheme:[NTDTheme themeForColorScheme:NTDColorSchemeKernal]]; /* debugging */
        return cell;
    } else {
        return nil;
    }
}

#pragma mark - UICollectionViewDelegate

-(void)__collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         NSArray *indexPaths = [collectionView indexPathsForVisibleItems];
                         for (NSIndexPath *visibleIndexPath in indexPaths) {
                             NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[collectionView cellForItemAtIndexPath:visibleIndexPath];
                             if ([visibleIndexPath isEqual:indexPath]) {
                                 cell.$y = self.collectionView.contentOffset.y;
                                 cell.scrollEnabled = YES;
                             } else {
                                 cell.$y = self.collectionView.contentOffset.y + self.collectionView.frame.size.height;
                                 cell.alpha = 0.1;
                             }
                         }
                     } completion:^(BOOL finished) {
                         [self updateLayout:self.pagingLayout animated:NO];
                         NSIndexPath *adjustedIndexPath = [NSIndexPath indexPathForItem:(indexPath.item-1) inSection:indexPath.section];
                         [collectionView scrollToItemAtIndexPath:adjustedIndexPath
                                                atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
                     }];
//    return;
//    
//    [collectionView performBatchUpdates:^{
//        self.listLayout.selectedCardIndexPath = indexPath;
//        NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//        cell.actionButton.hidden = NO;
//    }
//                             completion:^(BOOL finished){
//                                 self.listLayout.selectedCardIndexPath = nil;
//                                 [self updateLayout:self.pagingLayout animated:NO];
//                             }];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(NoteCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    if (collectionView.collectionViewLayout == self.pagingLayout) {
//        cell.scrollEnabled = NO;
//    }
}

#pragma mark - Properties
-(OptionsViewController *)optionsViewController
{
    if (_optionsViewController == nil) {
        _optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
//        _optionsViewController.view.frame = {{0.0, 0.0}, self.pagingLayout.cardSize};
        _optionsViewController.delegate = self;
    }
    return _optionsViewController;
}

- (NoteCollectionViewCell *)visibleCell
{
    NSParameterAssert(self.collectionView.collectionViewLayout == self.pagingLayout);
    return (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
}

#pragma mark - Actions
- (IBAction)actionButtonPressed:(UIButton *)actionButton
{
    NSIndexPath *topCardIndexPath = [self.collectionView indexPathsForVisibleItems][0];
    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:topCardIndexPath];
    [cell.textView resignFirstResponder];
}


- (void)handleRemoveCardGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    static NSIndexPath *swipedCardIndexPath = nil;
    static BOOL shouldDelete = NO;
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint initialPoint = [gestureRecognizer locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:initialPoint];
            if (indexPath) {
                if ([indexPath isEqual:self.pullToCreateCardIndexPath]) {
                    gestureRecognizer.enabled = NO;
                } else {
                    swipedCardIndexPath = indexPath;
//                    self.listLayout.swipedCardIndexPath = indexPath;
                    self.listLayout.swipedCardOffset = 0.0;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gestureRecognizer translationInView:self.collectionView];
            if (self.collectionView.dragging || fabs(translation.x) < 5.0)
                break;
            self.collectionView.scrollEnabled = NO;
            self.listLayout.swipedCardIndexPath = swipedCardIndexPath;
            self.listLayout.swipedCardOffset = translation.x;
            if (fabs(translation.x) >= 80) {
                gestureRecognizer.enabled = NO;
                shouldDelete = YES;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            self.collectionView.scrollEnabled = YES;
            [self.collectionView performBatchUpdates:^{
                self.listLayout.swipedCardIndexPath = nil;
                if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                    gestureRecognizer.enabled = YES;
                }
                if (shouldDelete) {
                    [self deleteCardAtIndexPath:swipedCardIndexPath];
                    shouldDelete = NO;
                }
            } completion:^(BOOL finished) {
            }];
            
            break;
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
            [self __collectionView:self.collectionView
        didSelectItemAtIndexPath:indexPath];
        }
    }
}

-(IBAction)showSettings:(id)sender
{
//    NTDNoteSettingsViewController *controller = [[NTDNoteSettingsViewController alloc] init];
//    controller.delegate = self;
//    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
//    [UIView transitionFromView:cell
//                        toView:controller.view
//                      duration:SettingsTransitionDuration
//                       options:UIViewAnimationOptionTransitionFlipFromLeft
//                    completion:NULL];
//    self.currentNoteSettingsController = controller;
    NoteCollectionViewCell *visibleCell = self.visibleCell;
    
    /* Don't let user interact with anything but our options. */
    visibleCell.textView.editable = NO;
    self.panCardWhileViewingOptionsGestureRecognizer.enabled = YES;

    self.optionsViewController.view.frame = self.initialFrameForVisibleNoteWhenViewingOptions = visibleCell.frame;
    [self.collectionView insertSubview:self.optionsViewController.view belowSubview:visibleCell];
    [self shiftCurrentNoteOriginToPoint:CGPointMake(InitialNoteOffsetWhenViewingOptions, 0.0) completion:NULL];
}

- (IBAction)panCard:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = panGestureRecognizer.view;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint point = [panGestureRecognizer locationInView:self.view.window]; // If we used 'view', point would be relative to content size
            NTDPagingDirection panDirection = ((point.x / view.$width) < 0.5) ? NTDPagingDirectionLeftToRight : NTDPagingDirectionRightToLeft;
            
            NSIndexPath *topCardIndexPath = [self.collectionView indexPathsForVisibleItems][0];
            NSInteger pannedCardIndex = -1, stationaryCardIndex = -1;
            if (panDirection == NTDPagingDirectionLeftToRight) {
                pannedCardIndex = topCardIndexPath.item - 1;
                stationaryCardIndex = topCardIndexPath.item;
            } else if (panDirection == NTDPagingDirectionRightToLeft) {
                pannedCardIndex = topCardIndexPath.item ;
                stationaryCardIndex = topCardIndexPath.item + 1;
            }

            if (stationaryCardIndex >= self.noteCount || pannedCardIndex < 0) {
                panGestureRecognizer.enabled = NO;
            } else {
                self.pagingLayout.pannedCardIndexPath = [NSIndexPath indexPathForItem:pannedCardIndex inSection:0];
                self.pagingLayout.pannedCardXTranslation = [panGestureRecognizer translationInView:view].x;
                self.pagingLayout.stationaryCardIndexPath = [NSIndexPath indexPathForItem:stationaryCardIndex inSection:0];
                self.pagingLayout.pagingDirection = panDirection;
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
            self.pagingLayout.pannedCardXTranslation = [panGestureRecognizer translationInView:view].x;
            break;
            
        case UIGestureRecognizerStateCancelled:
            panGestureRecognizer.enabled = YES;
            break;
            
        default:
        {
            CGPoint distance = [panGestureRecognizer translationInView:self.view];
            CGFloat percentage = fabs(distance.x) / view.$width;
            BOOL shouldReplaceCard = (percentage >= 0.6);
            
            NTDPagingDirection pagingDirection = self.pagingLayout.pagingDirection;
//            if (pagingDirection == NTDPagingDirectionRightToLeft) {
//                self.pagingLayout.stationaryCardIndexPath = nil;
//            }
            [self.collectionView performBatchUpdates:^{
                [self.pagingLayout completePanGesture:shouldReplaceCard];
            } completion:^(BOOL finished) {
                if (shouldReplaceCard) {
                    [self.pagingLayout invalidateLayout];

                    CGPoint offset = self.collectionView.contentOffset;
                    if (pagingDirection == NTDPagingDirectionLeftToRight) {
                        offset.x -= self.collectionView.bounds.size.width;
                    } else if (pagingDirection == NTDPagingDirectionRightToLeft) {
                        offset.x += self.collectionView.bounds.size.width;
                    }
                    [self.collectionView setContentOffset:offset animated:NO];
                }
            }];
            break;
        }
    }
}

CGFloat PinchDistance(UIPinchGestureRecognizer *pinchGestureRecognizer)
{
    UIView *view = pinchGestureRecognizer.view;
    CGPoint p1 = [pinchGestureRecognizer locationOfTouch:0 inView:view];
    CGPoint p2 = [pinchGestureRecognizer locationOfTouch:1 inView:view];
    return  DistanceBetweenTwoPoints(p1, p2);
}

CGFloat DistanceBetweenTwoPoints(CGPoint p1, CGPoint p2)
{
    CGFloat d = (p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y);
    return sqrtf(d);
}

- (IBAction)pinchToListLayout:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
{
    static CGFloat initialDistance = 0.0f, endDistance = 60.0f;
    static CGPoint initialContentOffset;
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *visibleCardIndexPath = [self.collectionView indexPathsForVisibleItems][0];
            NSIndexPath *pinchedCardIndexPath = [visibleCardIndexPath ntd_indexPathForNextItem];
            initialDistance = PinchDistance(pinchGestureRecognizer);
            self.listLayout.pinchedCardIndexPath = pinchedCardIndexPath;
            self.listLayout.pinchRatio = 1.0;
            
            initialContentOffset = self.collectionView.contentOffset;
            [self updateLayout:self.listLayout animated:NO];
            
            // Update content offset so card is correctly positioned.
            CGFloat offset = (visibleCardIndexPath.item - 1) * self.listLayout.cardOffset;
            CGFloat y = fmaxf(0.0, offset - (self.collectionView.$height / 2));
            [self.collectionView setContentOffset:CGPointMake(0.0, y) animated:NO];

            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGFloat currentDistance = PinchDistance(pinchGestureRecognizer);
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            self.listLayout.pinchRatio = pinchRatio;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            CGFloat currentDistance = PinchDistance(pinchGestureRecognizer);
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
            if (pinchRatio > 0.0) { /* Has to be <= 0.0 to switch layouts. */
                [self updateLayout:self.pagingLayout animated:NO];
                [self.collectionView setContentOffset:initialContentOffset animated:NO];
            } else {
                pinchGestureRecognizer.enabled = NO;
            }
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)panCardWhileViewingOptions:(UIPanGestureRecognizer *)panGestureRecognizer
{
    static CGPoint initialLocation;
    static CGRect initialFrame;
    
    UIView *view = panGestureRecognizer.view;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            initialLocation = [panGestureRecognizer locationInView:view];
            initialFrame = self.visibleCell.frame;
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint currentLocation = [panGestureRecognizer locationInView:view];
            CGFloat offset = currentLocation.x - initialLocation.x;
            CGRect frame = CGRectOffset(initialFrame, offset, 0.0);
            if (offset <= 0.0 /*&& frame.origin.x >= self.collectionView.contentOffset.x*/) {
                self.visibleCell.frame = frame;
            }
            break;
        }
        
        case UIGestureRecognizerStateEnded:
        {
            CGPoint currentLocation = [panGestureRecognizer locationInView:nil];
            CGFloat offset = self.visibleCell.$x - self.optionsViewController.view.$x;
            if (offset < InitialNoteOffsetWhenViewingOptions/2) {
                [self shiftCurrentNoteOriginToPoint:CGPointZero
                                         completion:^{
                                             panGestureRecognizer.enabled = NO;
                                             self.visibleCell.textView.editable = YES;
                                             [self.optionsViewController.view removeFromSuperview];
                                             [self.optionsViewController reset]; // what does this do?
                                         }];
            } else {
                [self shiftCurrentNoteOriginToPoint:CGPointMake(InitialNoteOffsetWhenViewingOptions, 0.0)
                                         completion:NULL];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Helpers
- (void)updateLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated
{
    [self.collectionView setCollectionViewLayout:layout animated:animated];
    if (layout == self.pagingLayout) {
        self.selectCardGestureRecognizer.enabled = NO;
        self.removeCardGestureRecognizer.enabled = NO;
        self.panCardGestureRecognizer.enabled = YES;
        self.pinchToListLayoutGestureRecognizer.enabled = YES;
        
        self.collectionView.scrollEnabled = NO;
        self.collectionView.directionalLockEnabled = YES;
        self.collectionView.pagingEnabled = YES;
        CGFloat padding = self.pagingLayout.minimumLineSpacing;
        self.view.$width += padding;

        self.shouldShowPullToCreateCard = NO;
        self.pullToCreateLabel.text = @"Pull to return to cards.";

    } else if (layout == self.listLayout) {
        self.selectCardGestureRecognizer.enabled = YES;
        self.removeCardGestureRecognizer.enabled = YES;
        self.panCardGestureRecognizer.enabled = NO;
        
        self.collectionView.scrollEnabled = YES;
        self.collectionView.pagingEnabled = NO;
        self.view.$width = [[UIScreen mainScreen] bounds].size.width;

        self.shouldShowPullToCreateCard = YES;
        self.pullToCreateLabel.text = @"Pull to create a new note.";
    }
    [self.collectionView reloadData];
}

- (void)insertNewCard
{
    NSIndexPath *newCardIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    [[ApplicationModel sharedInstance] createNoteWithCompletionBlock:^(NoteEntry *entry) {
        dispatch_async(dispatch_get_main_queue(), ^{
            entry.noteData.noteColor = [[NTDTheme randomTheme] backgroundColor];
            self.noteCount++;
            [self.collectionView insertItemsAtIndexPaths:@[newCardIndexPath]];
        });
    }];
}

- (void)deleteCardAtIndexPath:(NSIndexPath *)indexPath
{
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:[self noteEntryIndexForIndexPath:indexPath]
              withCompletionBlock:^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                      self.noteCount--;
                      [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                  });
              }];
}

- (NSInteger)noteEntryIndexForIndexPath:(NSIndexPath *)indexPath
{
    return (self.shouldShowPullToCreateCard) ? indexPath.item - 1 : indexPath.item;
}

- (void)returnToListLayout
{
    NSIndexPath *topCardIndexPath = [self.collectionView indexPathsForVisibleItems][0];
    [self updateLayout:self.listLayout animated:NO];
    CGFloat offset = (topCardIndexPath.item - 1) * self.listLayout.cardOffset;
    CGFloat y = fmaxf(0.0, offset - (self.collectionView.$height / 2));
    [self.collectionView setContentOffset:CGPointMake(0.0, y) animated:NO];

    NSIndexPath *selectedCardIndexPath = [NSIndexPath indexPathForItem:topCardIndexPath.item + 1
                                                             inSection:topCardIndexPath.section];
    NSArray *attributesArray = [self.listLayout layoutAttributesForElementsInRect:self.collectionView.bounds];

    void (^hideCells)(void) = ^{
        for (UICollectionViewLayoutAttributes *layoutAttributes in attributesArray) {
            NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:layoutAttributes.indexPath];
            if ([selectedCardIndexPath isEqual:layoutAttributes.indexPath]) {
                cell.$y = self.collectionView.contentOffset.y;
            } else {
                cell.$y = self.collectionView.contentOffset.y + self.collectionView.frame.size.height;
                cell.alpha = 0.1;
            }
        }
    };
    
    void (^showCells)(void) = ^{
        for (UICollectionViewLayoutAttributes *layoutAttributes in attributesArray) {
            NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:layoutAttributes.indexPath];
            cell.$y = layoutAttributes.frame.origin.y;
            cell.alpha = layoutAttributes.alpha;
        }
    };
    [self.collectionView performBatchUpdates:^{
        hideCells(); // Animation doesn't run on device, but does on Simulator.
    } completion:^(BOOL finished) {
        showCells(); // Does nothing on both platforms.
    }];
    
}
#pragma mark - Notifications
- (void)noteListChanged:(NSNotification *)notification
{
    self.noteCount = [[[ApplicationModel sharedInstance] currentNoteEntries] count];
    [self.collectionView reloadData];
}

- (void)statusBarFrameChanged:(NSNotification *)notification
{
    return;
    self.view.frame = [[[UIApplication sharedApplication] keyWindow] bounds];
    [self.listLayout invalidateLayout];
    self.pagingLayout.itemSize = self.listLayout.cardSize;
    [self.pagingLayout invalidateLayout];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer == self.collectionView.panGestureRecognizer)
        return YES;
    else
        return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.panCardGestureRecognizer) {
        CGPoint location = [touch locationInView:gestureRecognizer.view];
        CGFloat percentage = location.x / gestureRecognizer.view.$width;
        return (percentage >= 0.8 || percentage <= 0.2);
    }
    
    return YES;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.collectionView)
        return;
    
    CGFloat y = scrollView.bounds.origin.y;
    if (y < -self.pullToCreateContainerView.$height) {
        self.pullToCreateContainerView.$y = y;
    } else {
        self.pullToCreateContainerView.$y = -self.pullToCreateContainerView.$height;
    }
    
    CGFloat x = scrollView.bounds.origin.x;
    if (self.collectionView.collectionViewLayout == self.pagingLayout) {
        self.pullToCreateContainerView.$x = x;
    } else {
        self.pullToCreateContainerView.$x = 0.0;
    }
    
//    NSLog(@"Bounds: %@", NSStringFromCGRect(scrollView.bounds));
//    NSLog(@"Content Offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

static BOOL shouldCreateNewCard = NO, shouldReturnToListLayout = NO;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView != self.collectionView)
        return;
    
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        shouldCreateNewCard = (scrollView.contentOffset.y <= self.listLayout.pullToCreateCreateCardOffset);
        if (shouldCreateNewCard && !decelerate) {
            [self insertNewCard];
            shouldCreateNewCard = NO;
        }
    } else if (self.collectionView.collectionViewLayout == self.pagingLayout) {
        shouldReturnToListLayout = (scrollView.contentOffset.y <= self.listLayout.pullToCreateCreateCardOffset);
        if (shouldReturnToListLayout && !decelerate) {
            [self returnToListLayout];
            shouldReturnToListLayout = NO;
        }
    }
}

//-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
//{
//    if (self.collectionView.collectionViewLayout == self.pagingLayout) {
//        [self returnToListLayout];
//        shouldReturnToListLayout = NO;
//    }
//}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView != self.collectionView)
        return;

    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
    cell.scrollEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView != self.collectionView)
        return;
    
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        if (shouldCreateNewCard) {
            [self insertNewCard];
            shouldCreateNewCard = NO;
        }
    } else if (self.collectionView.collectionViewLayout == self.pagingLayout) {
        if (shouldReturnToListLayout) {
            [self returnToListLayout];
            shouldReturnToListLayout = NO;
        }
        BOOL onPageBoundary = (0 == (int)scrollView.contentOffset.x % (int)scrollView.$width);
        if (onPageBoundary) {
            NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
            cell.scrollEnabled = YES;
        }
    }
}

#pragma mark - UITextViewDelegate
-  (void)textViewDidBeginEditing:(UITextView *)textView
{
    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
    cell.actionButton.hidden = NO;
    cell.settingsButton.hidden = YES;
    self.collectionView.scrollEnabled = NO;
    [textView addKeyboardPanningWithActionHandler:nil];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView removeKeyboardControl];
    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
    cell.actionButton.hidden = YES;
    cell.settingsButton.hidden = NO;
//    self.collectionView.scrollEnabled = YES;
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtIndex:indexPath.item];
    void (^completion)(NoteDocument *noteDocument) = ^(NoteDocument *noteDocument) {
        if (noteDocument.documentState!=UIDocumentStateNormal ) {
            NSLog(@"couldn't save!");
            return;
        }
        
        NSString *text = textView.text;
        NSString *currentText = noteDocument.data.noteText;
        if (![currentText isEqualToString:text]) {
            [noteDocument setText:text];
            [noteEntry setNoteData:noteDocument.data];
            [noteDocument updateChangeCount:UIDocumentChangeDone];
            
            cell.titleLabel.text = [noteEntry title];
            cell.relativeTimeLabel.text = noteEntry.relativeDateString;
        }
        
    };
    [[ApplicationModel sharedInstance] noteDocumentAtIndex:indexPath.item
                                                completion:completion];
}

#pragma mark - Cross Detection
-(void)crossDetectorViewDidDetectCross:(NTDCrossDetectorView *)view
{
    NSLog(@"cross detected");
}

#pragma mark - NoteCollectionViewCellDelegate
- (void)didTriggerPullToReturn:(NoteCollectionViewCell *)cell
{
    [self returnToListLayout];
}

- (void)shouldEnableScrolling:(BOOL)shouldEnable forContainerViewOfCell:(NoteCollectionViewCell *)cell
{
//    self.collectionView.scrollEnabled = shouldEnable;
}

#pragma mark - NTDNoteSettingsViewController

- (void)changeNoteTheme:(NTDTheme *)newTheme
{
    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
    [cell applyTheme:newTheme];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NoteEntry *noteEntry = [[ApplicationModel sharedInstance] noteAtIndex:indexPath.item];

    void (^completion)(NoteDocument *noteDocument) = ^(NoteDocument *noteDocument) {
        
        UIColor *newColor = [newTheme backgroundColor];
        if (![noteDocument.color isEqual:newColor]) {
            noteDocument.color = newColor;
            [noteEntry setNoteData:noteDocument.data];
            [noteDocument updateChangeCount:UIDocumentChangeDone];
        }
        
    };
    [[ApplicationModel sharedInstance] noteDocumentAtIndex:indexPath.item
                                                completion:completion];
}

- (void)dismiss:(NTDNoteSettingsViewController *)controller
{
    NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView visibleCells][0];
    [UIView transitionFromView:controller.view
                        toView:cell
                      duration:SettingsTransitionDuration
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    completion:^(BOOL finished) {
                        self.currentNoteSettingsController = nil;
//                        self.collectionView.scrollEnabled = YES;
                    }];
}

#pragma mark - OptionsViewController Delegate

- (void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor
{
    [self changeNoteTheme:[NTDTheme themeForBackgroundColor:color]];
}


-(void)shiftCurrentNoteOriginToPoint:(CGPoint)point completion:(void(^)())completionBlock
{
    CGRect frame = self.initialFrameForVisibleNoteWhenViewingOptions;
    NoteCollectionViewCell *visibleCell = self.visibleCell;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         visibleCell.frame = CGRectOffset(frame, point.x, point.y);
                     } completion:^(BOOL success){
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (void)sendEmail
{
    self.mailViewController = [[MFMailComposeViewController alloc] init];
    
    if (!self.mailViewController) {
        //
    }
    
    self.mailViewController.mailComposeDelegate = self;
    
    NSArray* lines = [[ApplicationModel sharedInstance].noteAtSelectedNoteIndex.text componentsSeparatedByString: @"\n"];
    NSString* noteTitle = [lines objectAtIndex:0];
    NSString *body = [[NSString alloc] initWithFormat:@"%@\n\n%@",[self getNoteTextAsMessage],@"Sent from Noted"];
	[self.mailViewController setSubject:noteTitle];
	[self.mailViewController setMessageBody:body isHTML:NO];
    [self presentViewController:self.mailViewController animated:YES completion:nil];
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

#pragma mark Send Actions
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
