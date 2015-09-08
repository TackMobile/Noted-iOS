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
#import "NTDNoteDocument.h"
#import "NTDCollectionViewController+Walkthrough.h"
#import "WaitingAnimationLayer.h"
#import "NTDDropboxRestClient.h"
#import "NTDWalkthrough.h"

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
  // Kelvin's temp keys:  AppKey:@"wuctk62vh1yamo7" secret:@"t9mo61046gzn3tb"
  // New keys (current):  AppKey:@"uoi2t5ruoykgrdy" secret:@"7z7j97bs2fh07g9"
  
  DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"uoi2t5ruoykgrdy" appSecret:@"7z7j97bs2fh07g9" root:kDBRootAppFolder];
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
  if (![self isDropboxEnabled] && [self isDropboxLinked]) {
    [self setDropboxEnabled:NO];
    [self unlinkDropbox];
  }
  
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
      [self syncNotes];
    }
    
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

+ (void)unlinkDropbox
{
  if ([self isDropboxLinked]) {
    [[DBSession sharedSession] unlinkAll];
    [self setDropboxEnabled:false];
  }
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

+ (void)dismissModalIfShowing
{
  dispatch_async(dispatch_get_main_queue(), ^(void){
    if (modalView != nil)
      [modalView dismiss];
  });
}

#pragma mark - File operations

+ (void)syncNotes {
  if ([self isDropboxEnabledAndLinked]) {
    
    if ([[NTDWalkthrough sharedWalkthrough] isActive]) {
      [[NTDWalkthrough sharedWalkthrough] endWalkthrough:NO];
      NSLog(@"Walkthrough is active. Ending walkthrough and aborting dropbox sync.");
    } else {
      if (!restClient) {
        restClient = [[NTDDropboxRestClient alloc] init];
      }
      [restClient syncWithDropbox];
    }
  }
}

+ (void)deleteNoteFromDropbox:(NTDNote *)note {
  if ([self isDropboxEnabledAndLinked] && ![[NTDWalkthrough sharedWalkthrough] isActive]) {
    if (!restClient) {
      restClient = [[NTDDropboxRestClient alloc] init];
    }
    [restClient deleteDropboxFile:note.filename];
  }
}

+ (void)uploadNoteToDropbox:(NTDNote *)note {
  if ([self isDropboxEnabledAndLinked] && ![[NTDWalkthrough sharedWalkthrough] isActive]) {
    if (!restClient) {
      restClient = [[NTDDropboxRestClient alloc] init];
    }
    NSString *rev = (note.dropboxRev == nil || [note.dropboxRev length] == 0) ? nil : note.dropboxRev;
    [restClient uploadFileToDropbox:note withDropboxFileRev:rev];
  }
}

#pragma mark - Helpers

+ (BOOL)isDropboxEnabledAndLinked {
  if (![self isDropboxEnabled] && [self isDropboxLinked]) {
    [self unlinkDropbox];
  }
  return [self isDropboxEnabled] && [self isDropboxLinked];
}

@end