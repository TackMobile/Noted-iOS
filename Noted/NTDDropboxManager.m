//
//  NTDDropboxManager.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//
#import <Dropbox/Dropbox.h>
#import <FlurrySDK/Flurry.h>
#import <IAPHelper/IAPShare.h>
#import "NTDThemesTableViewController.h"
#import "NTDDropboxManager.h"
#import "NTDModalView.h"
#import "NTDNote.h"
#import "NTDDropboxNote.h"
#import "NTDCollectionViewController+Walkthrough.h"

NSString *const NTDDropboxProductID = @"com.tackmobile.noted.dropbox";
static NSString *kDropboxEnabledKey = @"kDropboxEnabledKey";
static NSString *kDropboxError = @"DropboxError";
static NTDModalView *modalView;
static NSString *dropboxPrice = @"";
@implementation NTDDropboxManager

+(void)initialize
{
    if ( self != [NTDDropboxManager class] ) {
        return;
    }
    //DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"dbq94n6jtz5l4n0" secret:@"3fo991ft5qzgn10"];
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"lwscmn1v79cbgag" secret:@"rqoh5v4tjvztg9a"];
    [DBAccountManager setSharedManager:accountManager];
    
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
         if(response > 0 ) {
             // get Dropbox price
             SKProduct* product = IAPShare.sharedHelper.iap.products[0];
             NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
             [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
             [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
             [numberFormatter setLocale:product.priceLocale];
             if ([product.price isEqualToNumber:[NSNumber numberWithFloat:0]])
                 dropboxPrice = @"free.";
             else
                 dropboxPrice = [numberFormatter stringFromNumber:product.price];
         } else {
             dropboxPrice = @"...";
         }
     }];
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

+ (void)setPurchased:(BOOL)purchased {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:purchased] forKey:NTDDropboxProductID];
}

+(BOOL)handleOpenURL:(NSURL *)url
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    BOOL success = (account != nil);
    if (success) {
        
        [self setDropboxEnabled:YES];
        [self setPurchased:YES];
        
        modalView = [[NTDModalView alloc] init];
        modalView.message = @"Syncing. Hold up a second...";
        modalView.type = NTDWalkthroughModalTypeMessage;
        [modalView show];
        
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        if ([DBFilesystem sharedFilesystem] == nil) {
            [DBFilesystem setSharedFilesystem:filesystem];
        }
        [filesystem addObserver:self block:^{
            if ([DBFilesystem sharedFilesystem].completedFirstSync)  {
                [self importExistingFiles];
                [[DBFilesystem sharedFilesystem] removeObserver:self];
            }
            [modalView dismiss];
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

+(BOOL)isDropboxPurchased
{
    return [NSUserDefaults.standardUserDefaults boolForKey:NTDDropboxProductID];
}

+(void)setDropboxEnabled:(BOOL)enabled
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kDropboxEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    // this is to actually stop or start syncing
    if (enabled) {
        DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        if ([DBFilesystem sharedFilesystem] == nil) {
            [DBFilesystem setSharedFilesystem:filesystem];
        }
    } else {
        [DBFilesystem setSharedFilesystem:nil]; // this is Dropbox's official response to stop syncing
    }
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
            [NTDDropboxNote syncMetadataWithCompletionBlock:^{
                for (NTDNote *note in notes) {
                    DBError __autoreleasing *error;
                    NSString *filename = note.filename;
                    DBFileInfo *fileinfo;
                    DBPath *path;
                    do {
                        path = [[DBPath root] childPath:filename];
                        fileinfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:path error:nil];
                    } while (fileinfo && (filename = IncrementIndexOfFilename(filename)));
                    
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
            }];
        });
    }];
}

#pragma mark - Helpers
static NSString *IncrementIndexOfFilename(NSString *path)
{
    NSRegularExpression *matcher = [NSRegularExpression regularExpressionWithPattern:@".*([0-9])+.*"
                                                                             options:0
                                                                               error:nil];
    NSString *filename = [path stringByDeletingPathExtension], *incrementedFilename;
    NSRange filenameRange = NSMakeRange(0, filename.length);
    NSTextCheckingResult *textCheckingResult = [matcher firstMatchInString:filename options:0 range:filenameRange];
    NSRange textCheckingResultRange = [textCheckingResult rangeAtIndex:1];
    if (textCheckingResultRange.location == NSNotFound) {
        incrementedFilename = [filename stringByAppendingString:@"-1"];
    } else {
        NSInteger index = [[filename substringWithRange:textCheckingResultRange] integerValue];
        index++;
        incrementedFilename = [filename stringByReplacingCharactersInRange:textCheckingResultRange withString:[@(index) stringValue]];
    }
    return [incrementedFilename stringByAppendingPathExtension:[path pathExtension]];
}

#pragma mark - Options menu
+(NSString *)DropboxPriceString
{
    return dropboxPrice;
}

- (void) purchaseDropboxPressed {
    [NTDThemesTableViewController showWaitingModal];
    
    //initate the purchase request
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response) {
        if ( response > 0 ) {
            // purchase Dropbox
            SKProduct* product = [[IAPShare sharedHelper].iap.products objectAtIndex:0];
            
            IAPbuyProductCompleteResponseBlock buyProductCompleteResponceBlock = ^(SKPaymentTransaction* transaction){
                if (transaction.error) {
                    NSLog(@"Failed to complete purchase: %@", [transaction.error localizedDescription]);
                    //[self showErrorMessageAndDismiss:transaction.error.localizedDescription];
                } else {
                    switch (transaction.transactionState) {
                        case SKPaymentTransactionStatePurchased:
                        {
                            // check the receipt
                            [[IAPShare sharedHelper].iap checkReceipt:transaction.transactionReceipt
                                                         onCompletion:^(NSString *response, NSError *error) {
                                                             NSDictionary *receipt = [IAPShare toJSON:response];
                                                             if ([receipt[@"status"] integerValue] == 0) {
                                                                 NSString *pID = transaction.payment.productIdentifier;
                                                                 [[IAPShare sharedHelper].iap provideContent:pID];
                                                                 NSLog(@"Success: %@",response);
                                                                 NSLog(@"Pruchases: %@",[IAPShare sharedHelper].iap.purchasedProducts);
                                                                 //[self purchaseThemesSuccess];
                                                             } else {
                                                                 NSLog(@"Receipt Invalid");
                                                                 //[self showErrorMessageAndDismiss:error.localizedDescription];
                                                             }
                                                         }];
                            break;
                        }
                            
                        default:
                        {
                            NSLog(@"Purchase Failed");
                            //[self purchaseThemesFailure];
                            break;
                        }
                    }
                }
            };
            
            // attempt to buy the product
            [[IAPShare sharedHelper].iap buyProduct:product
                                       onCompletion:buyProductCompleteResponceBlock];
        }
    }];
}
@end
