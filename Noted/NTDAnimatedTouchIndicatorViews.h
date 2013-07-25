//
//  NTDAnimatedTouchIndicatorViews.h
//  Noted
//
//  Created by Nick Place on 7/25/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTDAnimatedTouchIndicatorViews : UIView

@end

@interface NTDAnimatedTouchIndicatorView : UIView

+(instancetype)animatedTouchIndicatorViewWithStart:(CGPoint)start end:(CGPoint)end duration:(NSTimeInterval)duration;

@end