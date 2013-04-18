//
//  NoteCollectionViewController.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NoteCollectionViewController.h"
#import "NoteListCollectionViewLayout.h"
#import "NoteCollectionViewCell.h"
#import "UIView+FrameAdditions.h"
#import "ApplicationModel.h"
#import "NoteEntry.h"
#import "NTDPagingCollectionViewLayout.h"
#import "NTDCrossDetectorView.h"

@interface NoteCollectionViewController () <UIGestureRecognizerDelegate, NTDCrossDetectorViewDelegate>
@property (nonatomic, strong) NoteListCollectionViewLayout *listLayout;
@property (nonatomic, strong) NTDPagingCollectionViewLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *removeCardGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *selectCardGestureRecognizer;
@property (nonatomic, assign) NSUInteger noteCount;
@property (nonatomic, strong) NSIndexPath *pullToCreateCardIndexPath;
@property (nonatomic, assign) BOOL shouldShowPullToCreateCard;
@end

NSString *const NoteCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";

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
        self.collectionView.alwaysBounceVertical = YES;
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier];

        self.pullToCreateCardIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        self.shouldShowPullToCreateCard = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.pullToCreateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pullToCreateLabel.text = @"Pull to create a new note.";
    self.pullToCreateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    self.pullToCreateLabel.backgroundColor = [UIColor blackColor];
    self.pullToCreateLabel.textColor = [UIColor whiteColor];
    self.pullToCreateLabel.layer.zPosition = -10000;
    [self.collectionView addSubview:self.pullToCreateLabel];
    [self.pullToCreateLabel sizeToFit];
    CGRect frame = CGRectMake(14.0,
                              -self.pullToCreateLabel.bounds.size.height,
                              self.collectionView.bounds.size.width,
                              self.pullToCreateLabel.bounds.size.height);
    self.pullToCreateLabel.frame = frame;
    
    SEL selector = @selector(handleRemoveCardGesture:);
    self.removeCardGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                               action:selector];
    self.removeCardGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.removeCardGestureRecognizer];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handleCardTap:)];
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.selectCardGestureRecognizer = tapGestureRecognizer;
    
    self.noteCount = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (int)self.shouldShowPullToCreateCard + self.noteCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    cell.crossDetectorView.delegate = self;
    
    [cell.actionButton addTarget:self
                          action:@selector(actionButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        
    if (indexPath.item == 0 && self.shouldShowPullToCreateCard) {
        cell.titleLabel.text = @"Release to create note";
        cell.relativeTimeLabel.text = @"";
        [cell applyTheme:[NTDTheme themeForColorScheme:NTDColorSchemeWhite]];        
    } else {
        NSInteger index = [self noteEntryIndexForIndexPath:indexPath];
        NoteEntry *entry = [[ApplicationModel sharedInstance] noteAtIndex:index];
        cell.titleLabel.text = entry.text;
        cell.relativeTimeLabel.text = entry.relativeDateString;
        [cell applyTheme:[NTDTheme themeForBackgroundColor:entry.noteColor]];
    }
    return cell;
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

#pragma mark - Actions
- (IBAction)actionButtonPressed:(UIButton *)actionButton
{
    NSIndexPath *topCardIndexPath = [self.collectionView indexPathsForVisibleItems][0];
    self.listLayout.selectedCardIndexPath = [NSIndexPath indexPathForItem:topCardIndexPath.item + 1
                                                                inSection:topCardIndexPath.section];
    [self updateLayout:self.listLayout animated:NO];
    [self.collectionView performBatchUpdates:^{
        self.listLayout.selectedCardIndexPath = nil;
//        NSIndexPath *previousCardIndexPath = [NSIndexPath indexPathForItem:topCardIndexPath.item-1 inSection:0];
//        UICollectionViewLayoutAttributes *layoutAttributes = [self.listLayout layoutAttributesForItemAtIndexPath:previousCardIndexPath];
//        CGFloat offset = layoutAttributes.frame.origin.y + self.listLayout.cardOffset;
        CGFloat offset = (topCardIndexPath.item - 1) * self.listLayout.cardOffset;
        CGFloat y = fmaxf(0.0, offset - (self.collectionView.$height / 2));
//        NSLog(@"y: %f, frame; %@", y, NSStringFromCGRect(frame));
        [self.collectionView setContentOffset:CGPointMake(0.0, y) animated:NO];
    } completion:^(BOOL finished) {
        
    }];
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
#pragma mark - Helpers
- (void)updateLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated
{
    [self.collectionView setCollectionViewLayout:layout animated:animated];
    if (layout == self.pagingLayout) {
        self.selectCardGestureRecognizer.enabled = NO;
        self.removeCardGestureRecognizer.enabled = NO;

        self.collectionView.directionalLockEnabled = YES;
        self.collectionView.pagingEnabled = YES;
        CGFloat padding = self.pagingLayout.minimumLineSpacing;
        self.view.$width += padding;

        self.shouldShowPullToCreateCard = NO;
        self.pullToCreateLabel.text = @"Pull to return to cards.";

    } else if (layout == self.listLayout) {
        self.selectCardGestureRecognizer.enabled = YES;
        self.removeCardGestureRecognizer.enabled = YES;
        
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
    [self actionButtonPressed:nil];
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
    if (otherGestureRecognizer == self.collectionView.panGestureRecognizer)
        return YES;
    else
        return NO;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.bounds.origin.y;
    if (y < -self.pullToCreateLabel.$height) {
        self.pullToCreateLabel.$y = y;
    } else {
        self.pullToCreateLabel.$y = -self.pullToCreateLabel.$height;
    }
    
    CGFloat x = scrollView.bounds.origin.x;
    if (self.collectionView.collectionViewLayout == self.pagingLayout) {
        self.pullToCreateLabel.$x = x;
    } else {
        self.pullToCreateLabel.$x = 0;
    }
    NSLog(@"Bounds: %@", NSStringFromCGRect(scrollView.bounds));
//    NSLog(@"Content Offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

//static BOOL shouldPan = YES;
//
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//{
//    NSLog(@"scrollViewWillBeginDragging");
//    shouldPan = NO;
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    NSLog(@"scrollViewDidEndDragging:willDecelerate:%@", (decelerate ? @"YES" : @"NO"));
//
//    if(!decelerate) shouldPan = YES;
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    NSLog(@"scrollViewDidEndDecelerating");
//    shouldPan = YES;
//}

static BOOL shouldCreateNewCard = NO, shouldReturnToListLayout = NO;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
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
    }
}

#pragma mark - Cross detection
-(void)crossDetectorViewDidDetectCross:(NTDCrossDetectorView *)view
{
    NSLog(@"cross detected");
}

@end
