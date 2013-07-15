//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "AppDelegate.h"
#import "UIView+position.h"
#import "FileStorageState.h"
#import "NSUserDefaults+Convenience.h"
#import "NoteListViewController.h"
#import "NoteFileManager.h"
#import "TestFlight.h"
#import "ApplicationModel.h"
#import "CloudManager.h"
#import "WalkThroughViewController.h"
#import "DCIntrospect.h"
#import "NoteCollectionViewController.h"

NSString *const kTestflightToken = @"8c164a2e084013eae880e49cf6a4e005_NTU1MTAyMDEyLTAzLTIyIDE4OjE2OjE5LjAzNzQ2OA";

@interface AppDelegate()

@property (strong, nonatomic) WalkThroughViewController *tourVC;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize tourVC;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

#if !DEBUG
    [TestFlight takeOff:kTestflightToken];
#else
#if TARGET_IPHONE_SIMULATOR
    [[DCIntrospect sharedIntrospector] start];
#endif
#endif

//    self.window.rootViewController = [[NoteListViewController alloc] init];
    self.window.rootViewController = [[NoteCollectionViewController alloc] init];
    self.window.frame = CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, [[UIScreen mainScreen]bounds].size.height);
    [self.window makeKeyAndVisible];
    
    /*
    [[CloudManager sharedInstance] initializeiCloudAccessWithCompletion:nil];
    if ([FileStorageState isFirstUse]) {
        [[NSUserDefaults standardUserDefaults] saveBool:YES forKey:USE_STANDARD_SYSTEM_KEYBOARD];
        [[NSUserDefaults standardUserDefaults] saveBool:YES forKey:HIDE_STATUS_BAR];
        
    }*/
    
    if (!tourVC) {
        tourVC = tourVC = [[WalkThroughViewController alloc] init];
    }
    
    return YES;
}

- (void)resumeWalkthroughWithView:(UIView *)view
{
    if ([tourVC shouldResume]) {
        float activeYLoc = CGRectGetMaxY(self.window.frame)-tourVC.view.frame.size.height;
        if (tourVC.view.frame.origin.y == activeYLoc) {
            return;
        }
        [self.window addSubview:tourVC.view];
        [tourVC.view setFrameY:CGRectGetMaxY(self.window.frame)];
        [UIView animateWithDuration:0.5
                         animations:^{
                             [tourVC.view setFrameY:CGRectGetMaxY(self.window.frame)-tourVC.view.frame.size.height];
                         }
                         completion:^(BOOL finished){
                             [tourVC resumeWithCompletionBlock:nil];
                         }];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    BOOL hideStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_STATUS_BAR];
    [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar withAnimation:NO];
    
    self.window.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
    
//    if (![FileStorageState isFirstUse]) {
//        [[ApplicationModel sharedInstance] refreshNotes];
//        if ([tourVC shouldResume]) {
//            [tourVC resumeWithCompletionBlock:nil];
//        }
//    } else {
//        int64_t delayInSeconds = 2.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            [[ApplicationModel sharedInstance] refreshNotes];
//        });
//    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] saveBool:NO forKey:kFirstUse];
}


@end
