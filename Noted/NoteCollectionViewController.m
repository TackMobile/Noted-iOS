
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
#import "UIImage+Crop.h"
#import "ApplicationModel.h"
#import "NoteEntry.h"
#import "NTDPagingCollectionViewLayout.h"
#import "NTDCrossDetectorView.h"
#import "NoteData.h"
#import "NoteDocument.h"
#import "DAKeyboardControl.h"
#import "NSIndexPath+NTDManipulation.h"
#import "OptionsViewController.h"

@interface ColumnForShredding : NSObject

@property (nonatomic, strong) NSMutableArray *slices;
@property (nonatomic) float percentLeft;
@property (nonatomic) BOOL isDeleted;

@end

@implementation ColumnForShredding
@synthesize slices, percentLeft, isDeleted;
- (id) init {
    self = [super init];
    slices = [NSMutableArray array];
    percentLeft  = 0;
    isDeleted = NO;
    return self;
}

@end

@interface NoteCollectionViewController () <UIGestureRecognizerDelegate, UITextViewDelegate, NTDCrossDetectorViewDelegate, OptionsViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
@property (nonatomic, strong) NoteListCollectionViewLayout *listLayout;
@property (nonatomic, strong) NTDPagingCollectionViewLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) UIView *pullToCreateContainerView;

@property (nonatomic, strong, readonly) NoteCollectionViewCell *visibleCell;
@property (nonatomic, strong, readonly) NSIndexPath *visibleIndexPath;

@property (nonatomic, strong) UIPanGestureRecognizer *removeCardGestureRecognizer, *panCardGestureRecognizer, *panCardWhileViewingOptionsGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *selectCardGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchToListLayoutGestureRecognizer;

@property (nonatomic, assign) NSUInteger noteCount;
@property (nonatomic, assign) CGRect initialFrameForVisibleNoteWhenViewingOptions;

@property (nonatomic, strong) OptionsViewController *optionsViewController;
@property (nonatomic, strong) MFMailComposeViewController *mailViewController;

@property (nonatomic) BOOL twoFingerNoteDeletionBegun;
@property (nonatomic, strong) NSMutableArray *deletionNoteColumns;
@property (nonatomic, strong) NoteCollectionViewCell *currentDeletionCell;

@end

NSString *const NoteCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";
NSString *const NoteCollectionViewDuplicateCardReuseIdentifier = @"NoteCollectionViewDuplicateCardReuseIdentifier";

static const CGFloat SettingsTransitionDuration = 0.5;
static const CGFloat SwipeVelocityThreshold = 400.0;
static const CGFloat PinchVelocityThreshold = 2.2;
static const CGFloat InitialNoteOffsetWhenViewingOptions = 96.0;
static const int     DeletedNoteVertSliceCount = 10;
static const int     DeletedNoteHorizSliceCount = 6;


@implementation NoteCollectionViewController

- (id)init
{
    NoteListCollectionViewLayout *initialLayout = [[NoteListCollectionViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:initialLayout];
    if (self) {
        self.listLayout = initialLayout;
        self.pagingLayout = [[NTDPagingCollectionViewLayout alloc] init];
        self.deletionNoteColumns = [NSMutableArray array];

        self.twoFingerNoteDeletionBegun = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.allowsSelection = NO;
        self.collectionView.alwaysBounceVertical = YES;
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier];
        
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
    
    self.collectionView.alwaysBounceVertical = YES;
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
    return self.noteCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    cell.textView.delegate = self;
    cell.crossDetectorView.delegate = self;
    
    if (!self.twoFingerNoteDeletionBegun)
        cell.layer.mask = nil;
    
    [cell.settingsButton addTarget:self
                            action:@selector(showSettings:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    NSInteger index = [self noteEntryIndexForIndexPath:indexPath];
    NoteEntry *entry = [[ApplicationModel sharedInstance] noteAtIndex:index];
    cell.titleLabel.text = [entry title];
    cell.relativeTimeLabel.text = entry.relativeDateString;
#if DEBUG
    cell.relativeTimeLabel.text = [NSString stringWithFormat:@"[%d] %@", indexPath.item, cell.relativeTimeLabel.text];
#endif
    cell.textView.text = entry.text;
    [cell applyTheme:[NTDTheme themeForBackgroundColor:entry.noteColor]];

    [cell willTransitionFromLayout:nil toLayout:collectionView.collectionViewLayout];
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:NTDCollectionElementKindPullToCreateCard]) {
        NoteCollectionViewCell *cell = (NoteCollectionViewCell *) [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        cell.titleLabel.text = @"Release to create note";
        cell.relativeTimeLabel.text = @"";
        cell.textView.text = @"";
        [cell applyTheme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite]];
        cell.textView.delegate = nil;
        cell.crossDetectorView.delegate = nil;
        return cell;
    } else {
        return nil;
    }
}

#pragma mark - Properties
-(OptionsViewController *)optionsViewController
{
    if (_optionsViewController == nil) {
        _optionsViewController = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
        _optionsViewController.delegate = self;
    }
    return _optionsViewController;
}

- (NoteCollectionViewCell *)visibleCell
{
    return (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.visibleIndexPath];
}

- (NSIndexPath *)visibleIndexPath
{
   return [NSIndexPath indexPathForItem:self.pagingLayout.activeCardIndex inSection:0];
}

#pragma mark - Gesture Handling
- (void)handleRemoveCardGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    //hack. we should be more discerning about when we trigger anyway. aka, we should cancel
    //if indexPath==nil when in the 'began' state.
    if (self.noteCount == 0)
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
            NoteCollectionViewCell *theCell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
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
            
            if (fabsf([gestureRecognizer velocityInView:self.collectionView].x) > SwipeVelocityThreshold || translation.x > self.collectionView.frame.size.width/2)
                shouldDelete = YES;
                
            self.collectionView.scrollEnabled = YES;            
            
            self.listLayout.swipedCardIndexPath = nil;
            if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                gestureRecognizer.enabled = YES;
            }
            if (shouldDelete && [self.collectionView numberOfItemsInSection:0] > 1) {
                [self.listLayout completeDeletion:swipedCardIndexPath
                                       completion:^{
                                           [self deleteCardAtIndexPath:swipedCardIndexPath];
                                           shouldDelete = NO;
                                       }];
            } else {
                // animate the cell back to its orig position
                [self.collectionView performBatchUpdates:nil completion:^(BOOL finished) {
                    // if it didnt delete, make the shadow smaller and un rasterized
                    NoteCollectionViewCell *theCell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:swipedCardIndexPath];
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
            [self.collectionView performBatchUpdates:nil completion:nil];
            
            if (self.twoFingerNoteDeletionBegun)
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

- (IBAction)panCard:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint translation = [panGestureRecognizer translationInView:self.collectionView];
    CGPoint touchLoc = [panGestureRecognizer locationInView:self.collectionView];
    float velocity = [panGestureRecognizer velocityInView:self.collectionView].x;
    BOOL panEnded = NO;
    BOOL doNotRefresh = NO;
    int newIndex = self.pagingLayout.activeCardIndex;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan :
            // check for 2 finger note deletion
            if (panGestureRecognizer.numberOfTouches > 1) {
                [self prepareVisibleNoteForShred];
            }
            
        case UIGestureRecognizerStateChanged :
            
            if (self.twoFingerNoteDeletionBegun) {                
                // check if we should be shredding
                [self shredVisibleNoteByPercent:touchLoc.x/self.collectionView.frame.size.width completion:nil];
                
            } else {
                self.pagingLayout.pannedCardXTranslation = translation.x;
            }
            
            break;
            
        case UIGestureRecognizerStateEnded :
        {
            BOOL shouldDelete = NO;
            // check if translation is past threshold
            if (fabs(translation.x) >= self.collectionView.frame.size.width/2) {
                if (!self.twoFingerNoteDeletionBegun) {
                    // left
                    if (translation.x < 0)
                        newIndex ++ ;
                    else
                        newIndex -- ;
                } else {
                    // two finger swipe ended
                    // left
                    if (translation.x > 0)
                        shouldDelete = YES;
                }
                
            // check for a swipe
            } else if (fabs(velocity) > SwipeVelocityThreshold ) {
                // left
                if (!self.twoFingerNoteDeletionBegun) {
                    // left
                    if (velocity < 0)
                        newIndex ++ ;
                    else
                        newIndex -- ;
                } else {
                    // two finger swipe ended
                    // left
                    if (velocity > 0)
                        shouldDelete = YES;
                }
            }
            
            if (self.twoFingerNoteDeletionBegun) {
                if (shouldDelete) {
                    doNotRefresh = YES;
                    newIndex--;
                }
            }
            
            NSIndexPath *prevVisibleIndexPath = self.visibleIndexPath;
            
            // make sure we stay within bounds
            newIndex = MAX(0, MIN(newIndex, [self.collectionView numberOfItemsInSection:0]-1));
            self.pagingLayout.activeCardIndex = newIndex ;
            
            // update this so we know to animate to resting position
            self.pagingLayout.pannedCardXTranslation = 0;
            
            panEnded = YES;
            
            if (self.twoFingerNoteDeletionBegun) {
                if (shouldDelete) {
                    [self shredVisibleNoteByPercent:1 completion:^{
                        
                        [self.collectionView performBatchUpdates:^{
                            [self deleteCardAtIndexPath:prevVisibleIndexPath];
                        } completion:^(BOOL finished) {
                            [self.collectionView reloadData];
                        }];
                    }];

                } else {
                    [self cancelShredForVisibleNote];
                }
                self.twoFingerNoteDeletionBegun = NO;
            }
                        
        }
            break;
            
        case UIGestureRecognizerStateFailed :
        case UIGestureRecognizerStateCancelled :
            if (self.twoFingerNoteDeletionBegun)
                [self cancelShredForVisibleNote];
            
            self.twoFingerNoteDeletionBegun = NO;
            
        default:
            
            break;
    }
    
    if (!doNotRefresh) {
        if (panEnded)
            // animate to rest with some added velocity
            [self.pagingLayout finishAnimationWithVelocity:velocity+30 completion:nil];
        else if (!self.twoFingerNoteDeletionBegun)
            [self.pagingLayout invalidateLayout];
    }
    
}

- (IBAction)panCardWhileViewingOptions:(UIPanGestureRecognizer *)panGestureRecognizer
{
    
    CGPoint translation = [panGestureRecognizer translationInView:self.collectionView];
    float velocity = [panGestureRecognizer velocityInView:self.collectionView].x;
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
                [self.pagingLayout hideOptionsWithVelocity:velocity completion:^{
                    panGestureRecognizer.enabled = NO;
                    self.visibleCell.textView.editable = YES;
                    self.pinchToListLayoutGestureRecognizer.enabled = YES;
                    [self.optionsViewController.view removeFromSuperview];
                    [self.optionsViewController reset]; // what does this do?
                }] ;
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
            
            initialContentOffset = self.collectionView.contentOffset;
            [self updateLayout:self.listLayout
                      animated:NO];
            
            [self.collectionView setContentOffset:CGPointZero animated:NO];
            self.collectionView.scrollEnabled = NO;
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGFloat currentDistance = pinchGestureRecognizer.scale * initialDistance;
            CGFloat pinchRatio = (currentDistance - endDistance) / (initialDistance - endDistance);
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
- (void) prepareVisibleNoteForShred {
    self.currentDeletionCell = self.visibleCell;
    self.twoFingerNoteDeletionBegun = YES;
    [self.deletionNoteColumns removeAllObjects];
    
    CGSize sliceSize = CGSizeMake(self.collectionView.frame.size.width / DeletedNoteHorizSliceCount, self.collectionView.frame.size.height / DeletedNoteVertSliceCount);
    CGRect sliceRect = (CGRect){CGPointZero,sliceSize};
    
    UIImage *noteImage = [self imageForView:self.currentDeletionCell];
    
    for (int i=0; i<DeletedNoteHorizSliceCount; i++) {
        // add a column
        ColumnForShredding *currentColumn = [[ColumnForShredding alloc] init];
        currentColumn.percentLeft = (sliceSize.width*i)/self.collectionView.frame.size.width;
        [self.deletionNoteColumns addObject:currentColumn];
        
        // insert the slices
        for (int j=0; j<DeletedNoteVertSliceCount; j++) {
            
            CGRect cropRect = CGRectOffset(sliceRect, i*sliceSize.width, j*sliceSize.height);
                        
            UIImageView *sliceImageView = [[UIImageView alloc] initWithImage:[noteImage crop:cropRect]];
            
            sliceImageView.frame = cropRect;
            sliceImageView.layer.shadowOffset = CGSizeZero;
            sliceImageView.layer.shouldRasterize = YES;
            
            [currentColumn.slices addObject:sliceImageView];
            [self.collectionView insertSubview:sliceImageView belowSubview:self.currentDeletionCell];
        }
    }
    
    // set up a mask for the note. we'll move the mask right as the user swipes right
    
    CAShapeLayer *maskingLayer = [CAShapeLayer layer];
    CGPathRef path = CGPathCreateWithRect(self.visibleCell.bounds, NULL);
    maskingLayer.path = path;
    CGPathRelease(path);
    
    self.currentDeletionCell.layer.mask = maskingLayer;
}

- (void) shredVisibleNoteByPercent:(float)percent completion:(void (^)(void))completionBlock {
    // percent should range between 0.0 and 1.0

    float noteWidth = self.currentDeletionCell.frame.size.width;
        
    NSMutableArray *colsToRemove = [NSMutableArray array];
    __block BOOL useNextPercentForMask = NO;
    __block BOOL removeNextPercentForMask = NO;
    __block BOOL shiftMaskAfterAnimation = NO;
    __block ColumnForShredding *columnForUseAsMaskAfterAnimation = nil;

    // animate them out
    [UIView animateWithDuration:.5 animations:^{
        // fade out
        // decide which rows will be deleted
        for (ColumnForShredding *column in self.deletionNoteColumns) {
            if (column.isDeleted) {
                if (column.percentLeft >= percent) {
                    // begin to animate slices back in
                    // animate un-shredding of the column
                    for (UIImageView *slice in column.slices) {
                        slice.alpha = 1;
                        
                        // set the transform to normal
                        slice.transform = CGAffineTransformIdentity;
                        // give it a lil shadow
                        slice.layer.shadowOffset = CGSizeMake(-1, 0);
                        slice.layer.shadowOpacity = .5;
                        
                        //mask the shadow so it doesn't overlap other slices
                        CAShapeLayer *sliceMask = [CAShapeLayer layer];
                        CGRect sliceMaskRect = (CGRect){{-10, 0},{slice.bounds.size.width+10, slice.bounds.size.height}};
                        sliceMask.path = CGPathCreateWithRect(sliceMaskRect, nil);
                        slice.layer.mask = sliceMask;

                    }
                    
                    column.isDeleted = NO;
                    
                    useNextPercentForMask = YES; // this is really defining the current column to be used
                    shiftMaskAfterAnimation = YES;  // after the cells animate back to position
                }
            }
            
            if (removeNextPercentForMask) { // need to do this for the animating back in
                [column.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                    slice.layer.shadowOpacity = 0;
                }];
                removeNextPercentForMask = NO;
            }
            
            if (useNextPercentForMask) {
                if (shiftMaskAfterAnimation) {
                    columnForUseAsMaskAfterAnimation = column;
                    shiftMaskAfterAnimation = NO;
                    removeNextPercentForMask = YES;
                } else {
                    // shift the mask over
                    [CATransaction begin];
                    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                    self.currentDeletionCell.layer.mask.frame = (CGRect){{column.percentLeft * noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
                    [CATransaction commit];
                    
                    // give it a lil shadow
                    [column.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                        slice.layer.shadowOffset = CGSizeMake(-1, 0);
                        slice.layer.shadowOpacity = .5;
                    }];
                }
                useNextPercentForMask = NO;
            }
            
            if (!column.isDeleted && column.percentLeft < percent) {
                //[colsToRemove addObject:column];
                
                useNextPercentForMask = YES;
                                
                // animate shredding of the column
                for (UIImageView *slice in column.slices) {
                    // remove any mask and set up properties
                    slice.layer.mask = nil;
                    
                    slice.layer.shadowOffset = CGSizeMake(0,0);
                    slice.layer.shadowOpacity = (float)rand()/RAND_MAX * .8;
                    slice.alpha = 0;
                
                    // Rotate some degrees
                    CGAffineTransform rotate = CGAffineTransformMakeRotation((float)rand()/RAND_MAX*M_PI_2 - M_PI_4);
                    
                    // Move to the left
                    CGAffineTransform translate = CGAffineTransformMakeTranslation((float)rand()/RAND_MAX * -100,(float)rand()/RAND_MAX * 100 - 50);
                    
                    // Apply them to a view
                    slice.transform = CGAffineTransformConcat(translate, rotate);
                }
                
                column.isDeleted = YES;
            }
        }
        
        if (useNextPercentForMask && !shiftMaskAfterAnimation) { // the last column was deleted
            // remove the mask
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                self.currentDeletionCell.layer.mask.frame = (CGRect){{noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
            [CATransaction commit];
            
            useNextPercentForMask = NO;
        }
        
        // remove columns from array so they aren't re-animated
        //[self.deletionNoteColumns removeObjectsInArray:colsToRemove];
        
    } completion:^(BOOL finished) {

        for (ColumnForShredding *column in colsToRemove) {
            for (UIImageView *slice in column.slices)
                [slice removeFromSuperview];
        }
        
        // check if we should change the mask after the animation
        if (columnForUseAsMaskAfterAnimation != nil) {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = (CGRect){{columnForUseAsMaskAfterAnimation.percentLeft*noteWidth, 0}, self.visibleCell.layer.mask.frame.size};
            [CATransaction commit];
            
            // give it a lil shadow
            [columnForUseAsMaskAfterAnimation.slices enumerateObjectsUsingBlock:^(UIImageView *slice, NSUInteger idx, BOOL *stop) {
                slice.layer.mask = nil;
            }];
            
        }
        
        if (percent >= 1) {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.currentDeletionCell.layer.mask.frame = (CGRect){{noteWidth, 0}, self.currentDeletionCell.layer.mask.frame.size};
            [CATransaction commit];
        }
            
        if (completionBlock)
            completionBlock();
    }];
}

- (void) cancelShredForVisibleNote {
    
    [self shredVisibleNoteByPercent:0.0 completion:^{
        // remove slices from view
        [self.deletionNoteColumns enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ColumnForShredding *col, NSUInteger idx, BOOL *stop) {
            [col.slices enumerateObjectsUsingBlock:^(UIView *slice, NSUInteger idx, BOOL *stop) {
                [slice removeFromSuperview];
            }];
        }];
        self.currentDeletionCell.layer.mask = nil;

    }];
    
    /*[UIView animateWithDuration:.3 animations:^{
        
        self.currentDeletionCell.layer.mask.frame = self.currentDeletionCell.bounds;
    } completion:^(BOOL finished) {
        // remove unneeded subviews
        
        for (ColumnForShredding *col in self.deletionNoteColumns) {
            for (UIView *slice in col.slices) {
                slice.transform = CGAffineTransformIdentity;
                slice.alpha = 1;
            }
        }
        
        [self.deletionNoteColumns removeAllObjects];
        
        self.currentDeletionCell.layer.mask = nil;
        
    }];*/
}

-(void) didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         NSArray *indexPaths = [self.collectionView indexPathsForVisibleItems];
                         for (NSIndexPath *visibleIndexPath in indexPaths) {
                             NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:visibleIndexPath];
                             if ([visibleIndexPath isEqual:indexPath]) {
                                 cell.$y = self.collectionView.contentOffset.y;
                             } else {
                                 cell.$y = self.collectionView.contentOffset.y + self.collectionView.frame.size.height;
                                 cell.alpha = 0.1;
                             }
                         }
                     } completion:^(BOOL finished) {
                         self.pagingLayout.activeCardIndex = indexPath.row;
                         [self updateLayout:self.pagingLayout
                                   animated:NO];
                     }];
}


- (UIImage *)imageForView:(UIView *)view
{
    // this does not take scale into account on purpose (performance)
    UIGraphicsBeginImageContext(view.frame.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return ret;
}

-(IBAction)showSettings:(id)sender
{
    NoteCollectionViewCell *visibleCell = self.visibleCell;
    
    /* Don't let user interact with anything but our options. */
    visibleCell.textView.editable = NO;
    self.panCardWhileViewingOptionsGestureRecognizer.enabled = YES;
    self.pinchToListLayoutGestureRecognizer.enabled = NO;
    
    self.optionsViewController.view.frame = visibleCell.frame;
    [self.collectionView insertSubview:self.optionsViewController.view belowSubview:visibleCell];
    
    [self.pagingLayout revealOptionsViewWithOffset:InitialNoteOffsetWhenViewingOptions];
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
        
    } else if (layout == self.listLayout) {
        self.selectCardGestureRecognizer.enabled = YES;
        self.removeCardGestureRecognizer.enabled = YES;
        self.panCardGestureRecognizer.enabled = NO;
        
        self.view.$width = [[UIScreen mainScreen] bounds].size.width;
    }
    [self.collectionView reloadData];
}

- (void)insertNewCard
{
    NSIndexPath *newCardIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [[ApplicationModel sharedInstance] createNoteWithCompletionBlock:^(NoteEntry *entry) {
        dispatch_async(dispatch_get_main_queue(), ^{
            entry.noteData.noteColor = [[NTDTheme randomTheme] backgroundColor];
            self.noteCount++;
            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:@[newCardIndexPath]];
            } completion:^(BOOL finished) {
                /* The animation wasn't running, so I added this dispatch call so it would run on 
                 * the next turn of the run loop. */
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self didSelectItemAtIndexPath:newCardIndexPath];
                });
            }];
        });
    }];
}

- (void)deleteCardAtIndexPath:(NSIndexPath *)indexPath
{
    self.noteCount--;
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    ApplicationModel *model = [ApplicationModel sharedInstance];
    [model deleteNoteEntryAtIndex:[self noteEntryIndexForIndexPath:indexPath]
              withCompletionBlock:^{
                  NSLog(@"Note %d deleted", indexPath.item);
              }];
}

- (NSInteger)noteEntryIndexForIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.item;
}

#pragma mark - Notifications
- (void)noteListChanged:(NSNotification *)notification
{
    self.noteCount = [[[ApplicationModel sharedInstance] currentNoteEntries] count];
    [self.collectionView reloadData];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"%@ ----------------------- %@", gestureRecognizer, otherGestureRecognizer);
    if (otherGestureRecognizer == self.collectionView.panGestureRecognizer)
        return YES;
    else
        return NO;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
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

static BOOL shouldCreateNewCard = NO;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView != self.collectionView)
        return;
    
    // re-enable swipe to delete
    self.removeCardGestureRecognizer.enabled = YES;
    
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        shouldCreateNewCard = (scrollView.contentOffset.y <= self.listLayout.pullToCreateCreateCardOffset);
        if (self.noteCount == 0) //hack alert
            shouldCreateNewCard = (scrollView.contentOffset.y <= 0.0);
        if (shouldCreateNewCard && !decelerate) {
            [self insertNewCard];
            shouldCreateNewCard = NO;
        }
    }
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
    } 
}

#pragma mark - UITextViewDelegate
-  (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.visibleCell.settingsButton.hidden = YES;
    self.panCardGestureRecognizer.enabled = NO;
    self.pinchToListLayoutGestureRecognizer.enabled = YES;
    [textView addKeyboardPanningWithActionHandler:nil];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView removeKeyboardControl];
    self.visibleCell.settingsButton.hidden = NO;
    self.panCardGestureRecognizer.enabled = YES;
    self.pinchToListLayoutGestureRecognizer.enabled = YES;

    NoteCollectionViewCell *cell = self.visibleCell;
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

#pragma mark - OptionsViewController Delegate

-(void)changeOptionsViewWidth:(float)width {
    [self.pagingLayout revealOptionsViewWithOffset:width];
}

- (void)setNoteColor:(UIColor *)color textColor:(UIColor *)textColor
{
    NTDTheme *newTheme = [NTDTheme themeForBackgroundColor:color];
    [self.visibleCell applyTheme:newTheme];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:self.visibleCell];
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

- (void)sendEmail
{
    self.mailViewController = [[MFMailComposeViewController alloc] init];        
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
