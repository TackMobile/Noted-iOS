//
//  NoteCollectionViewLayoutAttributes.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/13/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, assign) CGAffineTransform transform2D;
@property (nonatomic, assign) BOOL shouldApplyCornerMask;

@end
