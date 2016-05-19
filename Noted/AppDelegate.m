//
//  AppDelegate.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import <Crashlytics/Crashlytics.h>
#import <FlurrySDK/Flurry.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "NTDCollectionViewController.h"
#import "NTDWalkthrough.h"
#import "NTDDropboxManager.h"
#import <IAPHelper/IAPShare.h>

NSString *const NTDInitialVersionKey = @"NTDInitialVersionKey";
NSString *const NTDInitialLaunchDateKey = @"NTDInitialLaunchDateKey";

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
    
    if ( ! IAPShare.sharedHelper.iap ) {
        NSSet *dataSet = [[NSSet alloc] initWithObjects:NTDNoteThemesProductID, NTDDropboxProductID, nil];
        IAPShare.sharedHelper.iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];
    }
    
    IAPShare.sharedHelper.iap.production = NO;
    
    [self customizeAppearance];
    [self recordInitialLaunchData];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[NTDCollectionViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    BOOL hideStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_STATUS_BAR];
    [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar withAnimation:NO];
    
    self.window.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  
  // Sync dropbox notes
  [NTDDropboxManager syncNotes];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Notify collection view if necessary
  [NSNotificationCenter.defaultCenter postNotificationName:@"applicationWillResignActive" object:nil];
  
  // Sync dropbox notes
  [NTDDropboxManager syncNotes];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Sync dropbox notes
  [NTDDropboxManager syncNotes];
}

- (void)customizeAppearance
{
    ModalBackgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation
{
    return [NTDDropboxManager handleOpenURL:url];
}

- (void)recordInitialLaunchData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:NTDInitialVersionKey]) {
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        [defaults setObject:version forKey:NTDInitialVersionKey];
    }
    if (![defaults objectForKey:NTDInitialLaunchDateKey]) {
        [defaults setObject:[NSDate date] forKey:NTDInitialLaunchDateKey];
    }
    [defaults synchronize];
    [[Crashlytics sharedInstance] setObjectValue:[defaults objectForKey:NTDInitialVersionKey]  forKey:NTDInitialVersionKey];
    [[Crashlytics sharedInstance] setObjectValue:[defaults objectForKey:NTDInitialLaunchDateKey] forKey:NTDInitialLaunchDateKey];
}
@end
