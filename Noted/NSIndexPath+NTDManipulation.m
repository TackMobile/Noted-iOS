//
//  NSIndexPath+NTDManipulation.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/30/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NSIndexPath+NTDManipulation.h"

@implementation NSIndexPath (NTDManipulation)

- (NSIndexPath *)ntd_indexPathForPreviousItem
{
    NSParameterAssert(self.item > 0);
    return [NSIndexPath indexPathForItem:(self.item - 1) inSection:self.section];
}

- (NSIndexPath *)ntd_indexPathForNextItem
{
    return [NSIndexPath indexPathForItem:(self.item + 1) inSection:self.section];
}

@end
