//
//  NTDDropboxManager.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDDropboxManager.h"
#import <Dropbox/Dropbox.h>

static NSString *kDropboxEnabledKey = @"kDropboxEnabledKey";
@implementation NTDDropboxManager

+(void)initialize
{
    DBAccountManager *accountMangager = [[DBAccountManager alloc] initWithAppKey:@"dbq94n6jtz5l4n0" secret:@"3fo991ft5qzgn10"];
    [DBAccountManager setSharedManager:accountMangager];
}

// Stub to make sure +initialize gets called
+(void)setup
{
    
}

+(void)linkAccountFromViewController:(UIViewController *)controller
{
    [[DBAccountManager sharedManager] linkFromController:controller];
}

+(BOOL)handleOpenURL:(NSURL *)url
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    BOOL success = (account != nil);
    [self setDropboxEnabled:success];
    return success;
}

+(BOOL)isDropboxEnabled
{
    return [NSUserDefaults.standardUserDefaults boolForKey:kDropboxEnabledKey];
}

+(void)setDropboxEnabled:(BOOL)enabled
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kDropboxEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}
@end
