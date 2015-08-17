//
//  NTDDropboxManager.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//
#import <DropboxSDK/DropboxSDK.h>
#import <FlurrySDK/Flurry.h>
#import <IAPHelper/IAPShare.h>
#import "NTDDropboxManager.h"
#import "NTDModalView.h"
#import "NTDNote.h"
#import "NTDDropboxNote.h"
#import "NTDNoteDocument.h"
#import "NTDCollectionViewController+Walkthrough.h"
#import "WaitingAnimationLayer.h"
#import "NTDDropboxRestClient.h"

NSString *const NTDDropboxProductID = @"com.tackmobile.noted.dropbox";
static NSString *kDropboxEnabledKey = @"kDropboxEnabledKey";
static NSString *kDropboxPurchasedKey = @"kDropboxPurchasedKey";
static NSString *kDropboxError = @"DropboxError";
static NTDModalView *modalView;
NSString *dropboxPrice = @"...";

@interface NTDDropboxManager()
@property (nonatomic, strong) __block NTDModalView *modalView;
@end

static NTDDropboxRestClient *restClient = nil;

@implementation NTDDropboxManager

+ (void)initialize
{
  if ( self != [NTDDropboxManager class] ) {
    return;
  }
  
  // Old keys:            AppKey:@"dbq94n6jtz5l4n0" secret:@"3fo991ft5qzgn10"
  // Jaclyn's temp keys:  AppKey:@"lwscmn1v79cbgag" secret:@"rqoh5v4tjvztg9a"
  // New keys (current):  AppKey:@"uoi2t5ruoykgrdy" secret:@"7z7j97bs2fh07g9"
  
  DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"uoi2t5ruoykgrdy" appSecret:@"7z7j97bs2fh07g9" root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
  [DBSession setSharedSession:dbSession];
  
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

+ (void)linkAccountFromViewController:(UIViewController *)controller
{
  if (![self isDropboxLinked]) {
    [[DBSession sharedSession] linkFromController:controller];
  }
}

+ (BOOL)handleOpenURL:(NSURL *)url
{
  BOOL success = [[DBSession sharedSession] handleOpenURL:url];
  if (success) {
    
    [self setDropboxEnabled:YES];
    [self setPurchased:YES];
    
    modalView = [[NTDModalView alloc] init];
    modalView.message = @"Syncing. Hold up a second...";
    modalView.type = NTDWalkthroughModalTypeMessage;
    [modalView show];
    
    if ([self isDropboxLinked]) {
      NSLog(@"App linked successfully!");
    }
    
//    DBFilesystem *oldshared = [DBFilesystem sharedFilesystem];
//    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
//    [DBFilesystem setSharedFilesystem:filesystem];
//    
//    if (oldshared == filesystem) {
//      [self importExistingFiles];
//      [modalView dismiss];
//    } else {
//      [filesystem addObserver:self block:^{
//        if ([DBFilesystem sharedFilesystem].completedFirstSync)  {
//          [self importExistingFiles];
//          [[DBFilesystem sharedFilesystem] removeObserver:self];
//        }
//        [modalView dismiss];
//      }];
//    }
    
    
  } else { // the user cancelled or this somehow otherwise failed
    NTDModalView *modalView = [[NTDModalView alloc] initWithMessage:@"Unable to link with Dropbox at this time. Please try again later."
                                                              layer:nil
                                                    backgroundColor:[UIColor blackColor]
                                                            buttons:@[@"OK"]
                                                   dismissalHandler:^(NSUInteger index) {
                                                     [self dismissModalIfShowing];
                                                   }];
    
    [modalView show];
    [self setDropboxEnabled:NO];
  }
  return success;
}

+ (BOOL)isDropboxEnabled
{
  return [NSUserDefaults.standardUserDefaults boolForKey:kDropboxEnabledKey];
}

+ (void)setDropboxEnabled:(BOOL)enabled
{
  [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kDropboxEnabledKey];
  [NSUserDefaults.standardUserDefaults synchronize];
}

+ (BOOL)isDropboxLinked
{
  return [[DBSession sharedSession] isLinked];
}

#pragma mark - Dropbox purchase

+ (NSString *)getDropboxPrice
{
  return dropboxPrice;
}

+ (BOOL)isDropboxPurchased
{
  return [NSUserDefaults.standardUserDefaults boolForKey:NTDDropboxProductID];
}

+ (void)setPurchased:(BOOL)purchased {
  [[NSUserDefaults standardUserDefaults] setBool:purchased forKey:NTDDropboxProductID];
}

+ (void)purchaseDropbox
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
                                               if ([receipt[@"status"] integerValue] == 0) {
                                                 NSString *pID = transaction.payment.productIdentifier;
                                                 [[IAPShare sharedHelper].iap provideContent:pID];
                                                 NSLog(@"Success: %@",response);
                                                 NSLog(@"Purchases: %@",[IAPShare sharedHelper].iap.purchasedProducts);
                                                 [NTDDropboxManager setPurchased:YES];
                                                 [NTDDropboxManager setDropboxEnabled:YES];
                                                 [NTDDropboxManager linkAccountFromViewController:nil];
                                                 [self dismissModalIfShowing];
                                               } else {
                                                 NSLog(@"Receipt Invalid");
                                                 [self showErrorMessageAndDismiss:error.localizedDescription];
                                               }
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

#pragma mark - Modal view

+ (void) showWaitingModal
{
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

+ (void)showErrorMessageAndDismiss:(NSString*)msg
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

+ (void)dismissModalIfShowing {
  if (modalView != nil)
    [modalView dismiss];
}

#pragma mark - File operations

+ (void)testDropbox
{
//  if ([self isDropboxEnabled] && [self isDropboxLinked]) {
  if ([self isDropboxLinked]) {
    if (!restClient) {
      restClient = [[NTDDropboxRestClient alloc] init];
    }
    [restClient listDropboxDirectory];
  } else {
    NSLog(@"Dropbox not linked");
  }
}

+ (void)syncNotes {
  //  if ([self isDropboxEnabled] && [self isDropboxLinked]) {
  if ([self isDropboxLinked]) {
    if (!restClient) {
      restClient = [[NTDDropboxRestClient alloc] init];
    }
    [restClient listDropboxDirectory];
  }
}

@end

/*

@implementation NTDDropboxManager



+(void)setup
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account && ![DBFilesystem sharedFilesystem]) {
        [DBFilesystem setSharedFilesystem:[[DBFilesystem alloc] initWithAccount:account]];
    }
}

#pragma mark - Importing
// This method should be more or less idempotent.
+ (void)importExistingFiles
{
  
  ////////////////////////////////////////////////////////////
  //// KAK THIS vvv NEEDS TO BE REMOVED vvv
  ////////////////////////////////////////////////////////////
  
    static BOOL didImportExistingFiles = NO;
    // This is to prevent a Dropbox related crash, which happens sometimes, sometimes not
    if (didImportExistingFiles) {
        NTDModalView *modalView = [[NTDModalView alloc] initWithMessage:@"Unable to link with Dropbox at this time. Please try again later."
                                                                  layer:nil
                                                        backgroundColor:[UIColor blackColor]
                                                                buttons:@[@"OK"]
                                                       dismissalHandler:^(NSUInteger index) {
                                                           [self dismissModalIfShowing];
                                                       }];
        
        [modalView show];
        [self setDropboxEnabled:NO];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[[DBAccountManager sharedManager] linkedAccount] unlink];
        });
        return;
    }
  
  ////////////////////////////////////////////////////////////
  //// KAK THIS ^^^ NEEDS TO BE REMOVED ^^^
  ////////////////////////////////////////////////////////////
  
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
                    modalView.message = @"Dropbox Sync enabled. All of your existing notes are now inside the “Apps/Noted” folder of your Dropbox.";
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

+ (void) importDropboxNotes
{
    if (![DBFilesystem sharedFilesystem])
        return;
    
    NTDCollectionViewController *controller = (NTDCollectionViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller returnToListLayout];
    [NTDDropboxNote listNotesWithCompletionHandler:^(NSArray *notes) {
        for (NTDDropboxNote *note in notes) {
            [NTDNoteDocument newNoteWithCompletionHandler:^(NTDNote *newNote){
                newNote.text = note.headline;
                newNote.theme = note.theme;
            }];
        }
    }];
    [NTDNote refreshStoragePreferences];
    modalView = [[NTDModalView alloc] init];
    modalView.message = @"Dropbox Sync disabled. All of your notes are now stored locally.";
    modalView.type = NTDWalkthroughModalTypeDismiss;
    modalView.promptHandler = ^(BOOL userClickedYes) {
        [controller reloadNotes];
        [modalView dismiss];
        modalView = nil;
    };
    [modalView show];
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

- (void)purchaseDropboxSuccess {
    [NTDDropboxManager setPurchased:YES];
    [NTDDropboxManager linkAccountFromViewController:nil];
    //[NTDThemesTableViewController dismissModalIfShowing];
}

- (void)purchaseDropboxFailure {
    //[NTDThemesTableViewController dismissModalIfShowing];
}

@end
 
 */
