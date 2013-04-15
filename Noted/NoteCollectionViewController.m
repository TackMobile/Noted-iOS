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

@interface NoteCollectionViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NoteListCollectionViewLayout *listLayout;
@property (nonatomic, strong) UICollectionViewFlowLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *removeCardGestureRecognizer;
@property (nonatomic, assign) NSUInteger noteCount;
@end

NSString *const NoteCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";

@implementation NoteCollectionViewController

- (id)init
{
    NoteListCollectionViewLayout *initialLayout = [[NoteListCollectionViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:initialLayout];
    if (self) {
        self.listLayout = initialLayout;
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier];
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
    
    self.noteCount = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteListChanged:)
                                                 name:kNoteListChangedNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // All of the initial cells have been created (occurs after viewWillAppear:),
    // so this call is safe.
    [self.collectionView sendSubviewToBack:self.pullToCreateLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1 + self.noteCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    [cell.actionButton addTarget:self
                          action:@selector(actionButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    
    NSInteger noteCount = [self collectionView:collectionView numberOfItemsInSection:0];
    if (indexPath.item == 0 || indexPath.item == 1 || indexPath.item == (noteCount-1))
        [cell applyCornerMask];
    else
        [cell removeCornerMask];
    
    if (indexPath.item == 0) {
        cell.titleLabel.text = @"Release to create note";
        cell.relativeTimeLabel.text = @"";
    } else {
        NoteEntry *entry = [[ApplicationModel sharedInstance] noteAtIndex:(indexPath.item - 1)];
        cell.titleLabel.text = entry.text;
        cell.relativeTimeLabel.text = entry.relativeDateString;
        [cell applyTheme:[NTDTheme themeForBackgroundColor:entry.noteColor]];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView performBatchUpdates:^{
        self.listLayout.selectedCardIndexPath = indexPath;
        NoteCollectionViewCell *cell = (NoteCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.actionButton.hidden = NO;
    }
                             completion:NULL];
}

#pragma mark - Actions
- (IBAction)actionButtonPressed:(UIButton *)actionButton
{
    actionButton.hidden = YES;
    self.listLayout.selectedCardIndexPath = nil;
    [self.collectionView performBatchUpdates:NULL completion:NULL];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.bounds.origin.y;
    if (y < -self.pullToCreateLabel.$height) {
        self.pullToCreateLabel.$y = y;
    } else {
        self.pullToCreateLabel.$y = -self.pullToCreateLabel.$height;
    }
}

- (void)handleRemoveCardGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint initialPoint = [gestureRecognizer locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:initialPoint];
            if (indexPath) {
                self.listLayout.swipedCardIndexPath = indexPath;
                self.listLayout.swipedCardOffset = 0.0;
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gestureRecognizer translationInView:self.collectionView];
            if (self.collectionView.dragging || fabs(translation.x) < 5.0)
                break;
            self.collectionView.scrollEnabled = NO;
            self.listLayout.swipedCardOffset = translation.x;
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            self.collectionView.scrollEnabled = YES;
            [self.collectionView performBatchUpdates:^{
                self.listLayout.swipedCardIndexPath = nil;
            } completion:^(BOOL finished) {
            }];
            
            break;
        }
        default:
            break;
    }
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

#pragma mark - Notifications
- (void)noteListChanged:(NSNotification *)notification
{
    self.noteCount = [[[ApplicationModel sharedInstance] currentNoteEntries] count];
    [self.collectionView reloadData];
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
@end
