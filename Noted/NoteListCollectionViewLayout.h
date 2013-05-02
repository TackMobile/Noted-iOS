//
//  NoteListCollectionViewLayout.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/11/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteListCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign) CGSize cardSize;
@property (nonatomic, assign) CGFloat cardOffset;
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, strong) NSIndexPath *selectedCardIndexPath;

@property (nonatomic, strong) NSIndexPath *swipedCardIndexPath;
@property (nonatomic, assign) CGFloat swipedCardOffset;

@property (nonatomic, assign) CGFloat pullToCreateShowCardOffset;
@property (nonatomic, assign) CGFloat pullToCreateScrollCardOffset;
@property (nonatomic, assign) CGFloat pullToCreateCreateCardOffset;
@property (nonatomic, assign) BOOL shouldShowCreateableCard;

@property (nonatomic, strong) NSIndexPath *pinchedCardIndexPath;
@property (nonatomic, assign) CGFloat pinchRatio;

@end
