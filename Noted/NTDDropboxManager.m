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
#import "NTDDropboxManager.h"
#import "NTDModalView.h"
#import "NTDNote.h"
#import "NTDDropboxNote.h"
#import "NTDCollectionViewController+Walkthrough.h"
#import "WaitingAnimationLayer.h"

NSString *const NTDDropboxProductID = @"com.tackmobile.noted.dropbox";
static NSString *kDropboxEnabledKey = @"kDropboxEnabledKey";
static NSString *kDropboxPurchasedKey = @"kDropboxPurchasedKey";
static NSString *kDropboxError = @"DropboxError";
static NTDModalView *modalView;
NSString *dropboxPrice = @"...";
@interface NTDDropboxManager()
@property (nonatomic, strong) __block NTDModalView *modalView;
@end

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
             if (IAPShare.sharedHelper.iap.products.count > 0) {
                 //SKProduct* product = IAPShare.sharedHelper.iap.products[1];
                 
                 SKProduct* product = nil;
                 
                 for (int i = 0; i < IAPShare.sharedHelper.iap.products.count; i++) {
                     SKProduct *temp = IAPShare.sharedHelper.iap.products[i];
                     if ([temp.productIdentifier isEqualToString:NTDDropboxProductID])
                         product = temp;
                 }
                 
                 if (product != nil) {
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                     [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                     [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:product.priceLocale];
                     if ([product.price isEqualToNumber:[NSNumber numberWithFloat:0]])
                         dropboxPrice = @"free.";
                     else
                         dropboxPrice = [numberFormatter stringFromNumber:product.price];
                 }
             }
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
    [[NSUserDefaults standardUserDefaults] setBool:purchased forKey:NTDDropboxProductID];
}

+(BOOL)handleOpenURL:(NSURL *)url
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    BOOL success = (account != nil);
    if (success) {
        modalView = [[NTDModalView alloc] init];
        modalView.message = @"Syncing. Hold up a second...";
        modalView.type = NTDWalkthroughModalTypeMessage;
        [modalView show];
        
        // in the event we try to link after we have already linked
        if ([DBFilesystem sharedFilesystem]) {
            [modalView dismiss];
            return success;
        }
        
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
        
        [filesystem addObserver:self block:^{
            if ([DBFilesystem sharedFilesystem].completedFirstSync)  {
                [self importExistingFiles];
                [self setDropboxEnabled:YES];
                [[DBFilesystem sharedFilesystem] removeObserver:self];
            }
        }];
    }
    return success;
}

+(void) showWaitingModal {
    // display a "waiting" modal which replaces the old one
    [self dismissModalIfShowing];
    
    WaitingAnimationLayer *animatingLayer = [WaitingAnimationLayer layer];
    animatingLayer.frame = (CGRect){{0, 0}, {220, 190}};
    NSString *msg = @"Waiting for a response from the App Store.";
    modalView = [[NTDModalView alloc] initWithMessage:msg
                                                     layer:animatingLayer
                                           backgroundColor:[UIColor blackColor]
                                                   buttons:@[]
                                          dismissalHandler:nil];
    [animatingLayer setNeedsLayout];
    [modalView show];
}

+(void)showErrorMessageAndDismiss:(NSString*)msg
{
    // display a "failure" modal
    [self dismissModalIfShowing];
    
    NTDModalView *modalView = [[NTDModalView alloc] initWithMessage:msg
                                                              layer:nil
                                                    backgroundColor:[UIColor blackColor]
                                                            buttons:@[@"OK"]
                                                   dismissalHandler:^(NSUInteger index) {
                                                       [self dismissModalIfShowing];
                                                   }];
    
    [modalView show];
}

+(void)dismissModalIfShowing {
    if (modalView != nil)
        [modalView dismiss];
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

+(NSString *)getDropboxPrice
{
    return dropboxPrice;
}

+(void)setDropboxEnabled:(BOOL)enabled
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kDropboxEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+(void)setDropoboxPurchased:(BOOL)purchased
{
    [NSUserDefaults.standardUserDefaults setBool:purchased forKey:NTDDropboxProductID];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+(void)purchaseDropbox
{
    [self showWaitingModal];
    //initate the purchase request
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response) {
        if ( response > 0 ) {
            // purchase Dropbox
            if (IAPShare.sharedHelper.iap.products.count > 0) {
                //SKProduct* product = IAPShare.sharedHelper.iap.products[1];
                
                SKProduct* product = nil;
                
                for (int i = 0; i < IAPShare.sharedHelper.iap.products.count; i++) {
                    SKProduct *temp = IAPShare.sharedHelper.iap.products[i];
                    if ([temp.productIdentifier isEqualToString:NTDDropboxProductID])
                        product = temp;
                }
                
                if (product == nil) {
                    [self showErrorMessageAndDismiss:@"Unable to reach iTunes store."];
                    return;
                }
            
                IAPbuyProductCompleteResponseBlock buyProductCompleteResponceBlock = ^(SKPaymentTransaction* transaction){
                    if (transaction.error) {
                        NSLog(@"Failed to complete purchase: %@", [transaction.error localizedDescription]);
                        [self showErrorMessageAndDismiss:transaction.error.localizedDescription];
                    } else {
                        switch (transaction.transactionState) {
                            case SKPaymentTransactionStatePurchased:
                            {
                                // check the receipt
                                [[IAPShare sharedHelper].iap checkReceipt:transaction.transactionReceipt
                                                             onCompletion:^(NSString *response, NSError *error) {
                                                                 NSDictionary *receipt = [IAPShare toJSON:response];
                                                                 // We never get a valid receipt from Apple, leave it for now
                                                                 //if ([receipt[@"status"] integerValue] == 0) {
                                                                     NSString *pID = transaction.payment.productIdentifier;
                                                                     [[IAPShare sharedHelper].iap provideContent:pID];
                                                                     NSLog(@"Success: %@",response);
                                                                     NSLog(@"Purchases: %@",[IAPShare sharedHelper].iap.purchasedProducts);
                                                                     [NTDDropboxManager setPurchased:YES];
                                                                     [NTDDropboxManager setDropboxEnabled:YES];
                                                                     [NTDDropboxManager linkAccountFromViewController:nil];
                                                                     [self dismissModalIfShowing];
                                                                 /*} else {
                                                                     NSLog(@"Receipt Invalid");
                                                                     [self showErrorMessageAndDismiss:error.localizedDescription];
                                                                 }*/
                                                             }];
                                break;
                            }
                                
                            default:
                            {
                                NSLog(@"Purchase Failed");
                                break;
                            }
                        }
                    }
                };
                
                // attempt to buy the product
                [[IAPShare sharedHelper].iap buyProduct:product
                                           onCompletion:buyProductCompleteResponceBlock];
            } else {
                [self showErrorMessageAndDismiss:@"Unable to reach iTunes store."];
                return;
            }
        }
    }];
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
@end
