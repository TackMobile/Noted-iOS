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

@property (nonatomic, assign) NSIndexPath *selectedCardIndexPath;

@property (nonatomic, assign) CGFloat pullToCreateShowCardOffset;
@property (nonatomic, assign) CGFloat pullToCreateScrollCardOffset;
@property (nonatomic, assign) CGFloat pullToCreateCreateCardOffset;
@property (nonatomic, assign) BOOL shouldShowCreateableCard;
@end
