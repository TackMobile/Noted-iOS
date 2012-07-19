//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "NoteListViewController.h"
#import "MasterViewController.h"
#import "TestFlight.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize masterViewController = _masterViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [TestFlight takeOff:@"8c164a2e084013eae880e49cf6a4e005_NTU1MTAyMDEyLTAzLTIyIDE4OjE2OjE5LjAzNzQ2OA"];
    
    self.window.rootViewController = [[NoteListViewController alloc] initWithNibName:@"NoteListViewController" bundle:nil];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
