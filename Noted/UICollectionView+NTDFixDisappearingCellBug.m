//
//  UICollectionView+NTDFixDisappearingCellBug.m
//  Noted
//
//  Created by Vladimir Fleurima on 9/17/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "UICollectionView+NTDFixDisappearingCellBug.h"
#import "NTDListCollectionViewLayout.h"
#import <objc/runtime.h>

/* References:
 http://stackoverflow.com/questions/14254222/large-uicollectionviewcell-stopped-being-displayed-when-scrolling
 http://stackoverflow.com/questions/1637604/method-swizzle-on-iphone-device
 */
@implementation UICollectionView (NTDFixDisappearingCellBug)

void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

+ (void)load {
    NSString *visibleBoundsSelector = [NSString stringWithFormat:@"%@isib%@unds", @"_v",@"leBo"];
    Swizzle([self class], NSSelectorFromString(visibleBoundsSelector), @selector(ntd_visibleBounds));
}

- (CGRect)ntd_visibleBounds {
    CGRect rect = [self ntd_visibleBounds];
    if ([self.collectionViewLayout isKindOfClass:[NTDListCollectionViewLayout class]]) {
        NTDListCollectionViewLayout *listLayout = (NTDListCollectionViewLayout *)self.collectionViewLayout;
        if (listLayout.swipedCardOffset < 0 && listLayout.swipedCardIndexPath)
            rect.origin.x = listLayout.swipedCardOffset;
        else
            rect.origin.x = 0;
    }
    return rect;

}

@end
