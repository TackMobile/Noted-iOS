//
//  NoteCollectionViewLayoutAttributes.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/13/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NoteCollectionViewLayoutAttributes.h"

@implementation NoteCollectionViewLayoutAttributes

-(id)init
{
    if (self = [super init]) {
        self.transform2D = CGAffineTransformIdentity;
        self.shouldApplyCornerMask = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NoteCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    copy.transform2D = self.transform2D;
    copy.shouldApplyCornerMask = self.shouldApplyCornerMask;
    return copy;
}

@end
