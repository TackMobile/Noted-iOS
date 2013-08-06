//
//  NTDWalkthroughModalView.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDWalkthrough.h"

@interface NTDWalkthroughModalView : UIView

-(id)initWithStep:(NTDWalkthroughStep)step;
-(id)initWithStep:(NTDWalkthroughStep)step handler:(void(^)(BOOL userClickedYes))handler;

@end
