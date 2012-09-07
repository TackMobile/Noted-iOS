//
//  StorageSettingsManager.m
//  Noted
//
//  Created by Ben Pilcher on 9/5/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "FileStorageState.h"

NSString *const kPreferredStorage =         @"preferredStorage";
NSString *const kPreferredStoragePrompted = @"preferredStoragePrompted";

@implementation FileStorageState

#pragma mark iCloud state

+ (BOOL)iCloudOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudOn"];
}

+ (void)setiCloudOn:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)iCloudWasOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudWasOn"];
}

+ (void)setiCloudWasOn:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudWasOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)iCloudPrompted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudPrompted"];
}

+ (void)setiCloudPrompted:(BOOL)prompted {
    [[NSUserDefaults standardUserDefaults] setBool:prompted forKey:@"iCloudPrompted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Preferred storage

+ (BOOL)shouldPrompt
{
    return ![self preferredStoragePrompted] && [self iCloudOn];
}

+ (TKPreferredStorage)preferredStorage
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kPreferredStorage] integerValue];
}

+ (void)setPreferredStorage:(TKPreferredStorage)storage
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:storage] forKey:kPreferredStorage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)preferredStoragePrompted
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferredStoragePrompted];
}

+ (void)setPreferredStoragePrompted:(BOOL)prompted
{
    [[NSUserDefaults standardUserDefaults] setBool:prompted forKey:kPreferredStoragePrompted];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
