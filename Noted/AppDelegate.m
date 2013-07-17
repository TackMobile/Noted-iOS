//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "NoteCollectionViewController.h"

@interface AppDelegate()
@end

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[NoteCollectionViewController alloc] init];
    self.window.frame = CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, [[UIScreen mainScreen]bounds].size.height);
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    BOOL hideStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_STATUS_BAR];
    [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar withAnimation:NO];
    
    self.window.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
 
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [NSUserDefaults.standardUserDefaults setBool:NO forKey:kFirstUse];
    [NSUserDefaults.standardUserDefaults synchronize];
}


@end
