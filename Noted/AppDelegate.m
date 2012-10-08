//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "AppDelegate.h"
#import "FileStorageState.h"
#import "NSUserDefaults+Convenience.h"
#import "NoteListViewController.h"
#import "MasterViewController.h"
#import "NoteFileManager.h"
#import "TestFlight.h"
#import "ApplicationModel.h"
#import "CloudManager.h"

NSString *const kTestflightToken = @"8c164a2e084013eae880e49cf6a4e005_NTU1MTAyMDEyLTAzLTIyIDE4OjE2OjE5LjAzNzQ2OA";

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize masterViewController = _masterViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [TestFlight takeOff:kTestflightToken];
    
    self.window.rootViewController = [[NoteListViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    [[CloudManager sharedInstance] initializeiCloudAccessWithCompletion:^(BOOL available){
        
        if ([FileStorageState isFirstUse]) {
            [[NSUserDefaults standardUserDefaults] saveBool:NO forKey:USE_STANDARD_SYSTEM_KEYBOARD];
            [[NSUserDefaults standardUserDefaults] saveBool:YES forKey:HIDE_STATUS_BAR];
            
        }
        
    }];
        
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[ApplicationModel sharedInstance] refreshNotes];
    BOOL hideStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_STATUS_BAR];
    [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar withAnimation:NO];
    
    self.window.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] saveBool:NO forKey:kFirstUse];
}


@end
