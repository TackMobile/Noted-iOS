//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "AppDelegate.h"

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
        NSLog(@"%s iCloud availability check done [%d]",__PRETTY_FUNCTION__,__LINE__);
       
    }];
        
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"did become active");
    
    
    
}

@end
