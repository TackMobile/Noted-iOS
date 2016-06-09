//
//  NTDWalkthroughViewController.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/24/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDWalkthrough.h"

@interface NTDWalkthroughViewController : UIViewController
- (void)beginDisplayingViewsForStep:(NTDWalkthroughStep)step;
- (void)endDisplayingViewsForStep:(NTDWalkthroughStep)step;
@end