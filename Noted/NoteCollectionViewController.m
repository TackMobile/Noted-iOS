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

@interface NoteCollectionViewController ()

@end

NSString *const NoteCollectionViewCellReuseIdentifier = @"NoteCollectionViewCellReuseIdentifier";

@implementation NoteCollectionViewController

- (id)init
{
    UICollectionViewLayout *initialLayout = [[NoteListCollectionViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:initialLayout];
    if (self) {
        [self.collectionView registerNib:[UINib nibWithNibName:@"NoteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:NoteCollectionViewCellReuseIdentifier];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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

    cell.titleLabel.text = @"Test Note";
    cell.relativeTimeLabel.text = @"a few seconds ago";
    cell.layer.borderWidth = 1.0;
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    void (^update)() = ^{
        NSArray *visibleItems = [collectionView indexPathsForVisibleItems];
        for (NSIndexPath *visibleItemIndexPath in visibleItems) {
            if ([indexPath isEqual:visibleItemIndexPath])
                continue;
            
            UICollectionViewLayoutAttributes *layoutAttributes = [collectionView layoutAttributesForItemAtIndexPath:visibleItemIndexPath];
            CGRect frame = layoutAttributes.frame;
            frame.origin.y += [[UIScreen mainScreen] bounds].size.height;
            layoutAttributes.frame = frame;
        }
    };
    update();
    [collectionView performBatchUpdates:NULL completion:NULL];
}
@end
