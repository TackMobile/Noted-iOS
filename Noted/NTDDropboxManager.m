//
//  NTDDropboxManager.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//
#import <Dropbox/Dropbox.h>
#import <FlurrySDK/Flurry.h>
#import "NTDDropboxManager.h"
#import "NTDModalView.h"
#import "NTDNote.h"
#import "NTDDropboxNote.h"
#import "NTDCollectionViewController+Walkthrough.h"

static NSString *kDropboxEnabledKey = @"kDropboxEnabledKey";
static NSString *kDropboxError = @"DropboxError";
static NTDModalView *modalView;
@implementation NTDDropboxManager

+(void)initialize
{
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"dbq94n6jtz5l4n0" secret:@"3fo991ft5qzgn10"];
    [DBAccountManager setSharedManager:accountManager];
}

+(void)setup
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account && ![DBFilesystem sharedFilesystem]) {
        [DBFilesystem setSharedFilesystem:[[DBFilesystem alloc] initWithAccount:account]];
    }
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
    if (success) {
        modalView = [[NTDModalView alloc] init];
        modalView.message = @"Syncing. Hold up a second...";
        modalView.type = NTDWalkthroughModalTypeMessage;
        [modalView show];
        [DBFilesystem setSharedFilesystem:[[DBFilesystem alloc] initWithAccount:account]];
        __weak DBFilesystem *filesystem = [DBFilesystem sharedFilesystem];
        [filesystem addObserver:self block:^{
            if (filesystem.completedFirstSync) [self importExistingFiles];
        }];
    }
    return success;
}

+(BOOL)isDropboxEnabled
{
    return [NSUserDefaults.standardUserDefaults boolForKey:kDropboxEnabledKey];
}

+(BOOL)isDropboxLinked
{
    return [[DBAccountManager sharedManager] linkedAccount] != nil;
}

+(void)setDropboxEnabled:(BOOL)enabled
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kDropboxEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

#pragma mark - Importing
/* This method should be more or less idempotent. */
+ (void)importExistingFiles
{
    static BOOL didImportExistingFiles = NO;
    if (didImportExistingFiles) return;
    
    NTDCollectionViewController *controller = (NTDCollectionViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller returnToListLayout];
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NTDDropboxNote clearExistingMetadata];
            for (NTDNote *note in notes) {
                DBError __autoreleasing *error;
                DBPath *path = [[DBPath root] childPath:note.filename];
                DBFile *file = [[DBFilesystem sharedFilesystem] createFile:path error:&error];
                if (error) {
                    NSString *errorMsg = [NSString stringWithFormat:@"Error creating file named %@: %@", note.filename, error];
                    [Flurry logError:kDropboxError message:errorMsg error:error];
                    continue;
                }
                [file writeContentsOfFile:note.fileURL.path shouldSteal:NO error:&error];
                if (error) {
                    NSString *errorMsg = [NSString stringWithFormat:@"Error copying contents of file named %@: %@", note.filename, error];
                    [Flurry logError:kDropboxError message:errorMsg error:error];
                    continue;
                }
                NTDDropboxNote *dropboxNote = [[NTDDropboxNote alloc] init];
                [dropboxNote copyFromNote:note file:file];
            }

            didImportExistingFiles = YES;
            [NTDNote refreshStoragePreferences];
            [modalView dismissWithCompletionHandler:^{
                modalView = [[NTDModalView alloc] init];
                modalView.message = @"Dropbox Sync enabled. All of your existing notes are now inside the “Apps/TakeNoted” folder of your Dropbox.";
                modalView.type = NTDWalkthroughModalTypeDismiss;
                modalView.promptHandler = ^(BOOL userClickedYes) {
                    [controller reloadNotes];
                    [modalView dismiss];
                    modalView = nil;
                };
                [modalView show];
            }];
        });
    }];
}
@end
