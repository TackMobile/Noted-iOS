//
//  NTDWalkthroughGestureIndicator.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "NTDWalkthrough.h"

@interface NTDWalkthroughGestureIndicatorView : UIView

+ (void)bindGestureRecognizer:(UIGestureRecognizer *)recognizer
                      forStep:(NTDWalkthroughStep)step;
+ (void)bindControl:(UIControl *)control
             events:(UIControlEvents)controlEvents
            forStep:(NTDWalkthroughStep)step;
+ (instancetype)gestureIndicatorViewForStep:(NTDWalkthroughStep)step;

@property (nonatomic, assign) CAAnimation *mainAnimation;
- (void)handleGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleAction:(UIControl *)control;
@end
