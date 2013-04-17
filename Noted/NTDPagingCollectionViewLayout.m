//
//  NTDPagingCollectionViewLayout.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDPagingCollectionViewLayout.h"
#import "NoteCollectionViewLayoutAttributes.h"

@implementation NTDPagingCollectionViewLayout

-(id)init
{
    if (self = [super init]) {
        self.minimumLineSpacing = 20.0;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, self.minimumLineSpacing);

    }
    return self;
}

+ (Class)layoutAttributesClass
{
    return [NoteCollectionViewLayoutAttributes class];
}

//-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
//{
//    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
//    [attributesArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
//        if (0 == layoutAttributes.indexPath.item) {
//            layoutAttributes.hidden = YES;
//        }
//    }];
//    return attributesArray;
//}
//
//-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
//    if (0 == indexPath.item) {
//        layoutAttributes.hidden = YES;
//    }
//    return layoutAttributes;
//}
//
-(CGSize)collectionViewContentSize
{
    CGSize size = [super collectionViewContentSize];
    return CGSizeMake(size.width, 40+size.height);
}
@end
