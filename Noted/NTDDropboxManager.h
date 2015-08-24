//
//  NTDDropboxManager.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTDNote.h"

FOUNDATION_EXPORT NSString *const NTDDropboxProductID;

@interface NTDDropboxManager : NSObject

+ (void)linkAccountFromViewController:(UIViewController *)controller;
+ (BOOL)handleOpenURL:(NSURL *)url;
+ (BOOL)isDropboxEnabled;
+ (void)setDropboxEnabled:(BOOL)enabled;
+ (BOOL)isDropboxLinked;
+ (void)unlinkDropbox;
+ (NSString *)getDropboxPrice;
+ (BOOL)isDropboxPurchased;
+ (void)setPurchased:(BOOL)purchased;
+ (void)purchaseDropbox;
+ (void)showErrorMessageAndDismiss:(NSString*)msg;
+ (void)dismissModalIfShowing;
+ (void)syncNotes;
+ (void)deleteNoteFromDropbox:(NTDNote *)note;
+ (void)uploadNewNoteToDropbox:(NTDNote *)note;

@end
