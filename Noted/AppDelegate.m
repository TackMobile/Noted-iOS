//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import <FlurrySDK/Flurry.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "NTDCollectionViewController.h"
#import "NTDWalkthrough.h"

@interface AppDelegate()
@end

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Flurry setSecureTransportEnabled:YES];
    [Flurry setCrashReportingEnabled:NO];
    [Flurry startSession:@"F9R3ZM7J2KWNPCGR6XBF"];
    [Crashlytics startWithAPIKey:@"74274da5058ac773f4834d2aedc44eac0555edcd"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[NTDCollectionViewController alloc] init];
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
