//
//  NTDWalkthroughModalView.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/26/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDWalkthrough.h"
#import "NTDModalView.h"

@interface NTDWalkthroughModalView : NTDModalView

-(id)initWithStep:(NTDWalkthroughStep)step;
-(id)initWithStep:(NTDWalkthroughStep)step handler:(NTDWalkthroughPromptHandler)handler;

@end
