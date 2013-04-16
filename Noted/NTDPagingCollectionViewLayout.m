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

@end
