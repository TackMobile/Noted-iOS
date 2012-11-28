//
//  AppDelegate.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"

@class TourViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)resumeWalkthroughWithView:(UIView *)view;

@end
