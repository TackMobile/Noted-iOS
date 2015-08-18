//
//  NTDDropboxManager.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const NTDDropboxProductID;

@interface NTDDropboxManager : NSObject

+ (void)linkAccountFromViewController:(UIViewController *)controller;
+ (BOOL)handleOpenURL:(NSURL *)url;
+ (BOOL)isDropboxEnabled;
+ (void)setDropboxEnabled:(BOOL)enabled;
+ (BOOL)isDropboxLinked;
+ (NSString *)getDropboxPrice;
+ (BOOL)isDropboxPurchased;
+ (void)setPurchased:(BOOL)purchased;
+ (void)purchaseDropbox;
+ (void)showErrorMessageAndDismiss:(NSString*)msg;
+ (void)syncNotes;

//+(void)setup;
//+(void)importDropboxNotes;
@end
