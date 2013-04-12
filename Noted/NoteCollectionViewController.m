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

NSInteger PullToCreateLabelTag = 500;

@interface NoteCollectionViewController ()
@property (nonatomic, strong) NoteListCollectionViewLayout *listLayout;
@property (nonatomic, strong) UICollectionViewFlowLayout *pagingLayout;
@property (nonatomic, strong) UILabel *pullToCreateLabel;
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
    self.pullToCreateLabel.tag = PullToCreateLabelTag;
    [self.collectionView addSubview:self.pullToCreateLabel];
    [self.pullToCreateLabel sizeToFit];
    CGRect frame = CGRectMake(14.0,
                              -self.pullToCreateLabel.bounds.size.height,
                              self.collectionView.bounds.size.width,
                              self.pullToCreateLabel.bounds.size.height);
    self.pullToCreateLabel.frame = frame;
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

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NoteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    [cell.actionButton addTarget:self
                          action:@selector(actionButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    cell.layer.borderWidth = 1.0;
    if (indexPath.item == 0) {
        cell.titleLabel.text = @"Release to create note";
        cell.relativeTimeLabel.text = @"";
    } else {
        cell.titleLabel.text = @"Test Note";
        cell.relativeTimeLabel.text = @"a few seconds ago";
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    void (^update)() = ^{
//        NSArray *visibleItems = [collectionView indexPathsForVisibleItems];
//        for (NSIndexPath *visibleItemIndexPath in visibleItems) {
//            if ([indexPath isEqual:visibleItemIndexPath])
//                continue;
//            
//            UICollectionViewLayoutAttributes *layoutAttributes = [collectionView layoutAttributesForItemAtIndexPath:visibleItemIndexPath];
//            CGRect frame = layoutAttributes.frame;
//            frame.origin.y += [[UIScreen mainScreen] bounds].size.height;
//            layoutAttributes.frame = frame;
//        }
//    };
//    update();
//    [collectionView performBatchUpdates:NULL completion:NULL];
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
//    NSLog(@"content offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
//    NSLog(@"center: %@", NSStringFromCGPoint(scrollView.center));
//    NSLog(@"bounds: %@", NSStringFromCGRect(scrollView.bounds));
//    NSLog(@"frame: %@", NSStringFromCGRect(scrollView.frame));
}
@end
