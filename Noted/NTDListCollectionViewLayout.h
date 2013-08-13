//
//  NoteListCollectionViewLayout.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const NTDCollectionElementKindPullToCreateCard;

@interface NTDListCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign) CGSize cardSize;
@property (nonatomic, assign) CGFloat cardOffset;
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, strong) NSIndexPath *selectedCardIndexPath;

@property (nonatomic, strong) NSIndexPath *swipedCardIndexPath;
@property (nonatomic, assign) CGFloat swipedCardOffset;

@property (nonatomic, assign) CGFloat pullToCreateCreateCardOffset;
@property (nonatomic, assign, readonly) BOOL shouldShowCreateableCard;
@property (nonatomic, assign) BOOL pullToCreateEnabled;
@property (nonatomic, strong) NSIndexPath *pinchedCardIndexPath;
@property (nonatomic, assign) CGFloat pinchRatio;

- (void) completeDeletion:(NSIndexPath *)cardIndexPath completion:(void (^)(void))completionBlock;

@end
