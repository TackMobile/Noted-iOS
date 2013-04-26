//
//  NTDPagingCollectionViewLayout.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NTDPagingDirection) {
    NTDPagingDirectionInvalidDirection = 0,
    NTDPagingDirectionLeftToRight,
    NTDPagingDirectionRightToLeft
};
UIKIT_EXTERN NSString * const NTDCollectionElementKindDuplicateCard;

@interface NTDPagingCollectionViewLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) NSIndexPath *pannedCardIndexPath, *stationaryCardIndexPath;
@property (nonatomic, assign) CGFloat pannedCardXTranslation;
@property (nonatomic, assign) NTDPagingDirection pagingDirection;
- (void)completePanGesture:(BOOL)shouldReplaceStationaryCard;

@end
