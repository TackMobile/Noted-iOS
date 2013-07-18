//
//  NoteCollectionViewLayoutAttributes.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/13/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewLayoutAttributes.h"

@implementation NTDCollectionViewLayoutAttributes

-(id)init
{
    if (self = [super init]) {
        self.transform2D = CGAffineTransformIdentity;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NTDCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    copy.transform2D = self.transform2D;
    return copy;
}

@end
