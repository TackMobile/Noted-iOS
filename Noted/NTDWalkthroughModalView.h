//
//  NTDWalkthroughModalView.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDWalkthrough.h"

typedef void(^NTDWalkthroughPromptHandler)(BOOL userClickedYes);
FOUNDATION_EXPORT UIColor *WalkthroughModalBackgroundColor;

@interface NTDWalkthroughModalView : UIView

-(id)initWithStep:(NTDWalkthroughStep)step;
-(id)initWithStep:(NTDWalkthroughStep)step handler:(NTDWalkthroughPromptHandler)handler;

@end
