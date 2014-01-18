//
//  NTDTextView.m
//  Noted
//
//  Created by Vladimir Fleurima on 9/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDTextView.h"

@implementation NTDTextView

static CGFloat heightDifference;
-(void)setContentOffset:(CGPoint)contentOffset
{
//    NSLog(@"%p Existing Offset: %@ New Offset: %@ Height Difference: %.2f", self, NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(contentOffset), self.contentOffset.y - contentOffset.y);
    CGFloat offsetDifference = self.contentOffset.y - contentOffset.y;
    if (heightDifference != 0 &&
        offsetDifference != 0 && /* Don't bother if vertical offset hasn't changed. */
        SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && /* <3 iOS 7 */
        !self.dragging && /* Otherwise this triggers while the keyboard is scrolling. */
        ABS(offsetDifference - heightDifference) < 0.01) /* Ghetto tolerance check */
    {
//        NSLog(@"[RESET] %p Existing Offset: %@ New Offset: %@ Height Difference: %.2f", self, NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(contentOffset), offsetDifference);
        contentOffset = CGPointZero;
    }
    [super setContentOffset:contentOffset];
}

-(void)setContentSize:(CGSize)contentSize
{
    heightDifference = self.contentSize.height - contentSize.height;
//    NSLog(@"%p Existing Size: %@ New Size: %@ Height Difference: %.2f", self, NSStringFromCGSize(self.contentSize), NSStringFromCGSize(contentSize), self.contentSize.height - contentSize.height);
    [super setContentSize:contentSize];
}

@end
