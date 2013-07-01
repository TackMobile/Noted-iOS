//
//  NTDPagingCollectionViewLayout.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTDPagingCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign) CGFloat pannedCardXTranslation;
@property (nonatomic) int activeCardIndex;
@property (nonatomic, readonly) CGFloat currentOptionsOffset;

@property (nonatomic, strong) UIView *settingsView;

- (void) finishAnimationWithVelocity:(CGFloat)velocity completion:(void (^)(void))completionBlock ;
- (void) revealOptionsViewWithOffset:(CGFloat)offset;
- (void) hideOptionsWithVelocity:(CGFloat)velocity completion:(void (^)(void))completionBlock;
@end
