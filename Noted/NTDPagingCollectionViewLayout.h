//
//  NTDPagingCollectionViewLayout.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *NTDMayShowNoteAtIndexPathNotification;

@interface NTDPagingCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign) CGFloat pannedCardXTranslation;
@property (nonatomic, assign) CGFloat pannedCardYTranslation;

@property (nonatomic) BOOL deletedLastNote; /* we never truly delete last note. We just clear it, hide it, and fade it back in */
@property (nonatomic) int activeCardIndex;
@property (nonatomic, readonly) CGFloat currentOptionsOffset;

@property (nonatomic, strong) UIView *settingsView;

- (void) finishAnimationWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock;
- (void) completePullAnimationWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock ;

- (void) revealOptionsViewWithOffset:(CGFloat)offset;
- (void) revealOptionsViewWithOffset:(CGFloat)offset completion:(NTDVoidBlock)completionBlock;
- (void) hideOptionsWithVelocity:(CGFloat)velocity completion:(NTDVoidBlock)completionBlock;
@end
