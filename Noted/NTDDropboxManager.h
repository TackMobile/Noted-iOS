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

+(void)setup;
+(void)setPurchased:(BOOL)purchased;
+(void)linkAccountFromViewController:(UIViewController *)controller;
+(BOOL)handleOpenURL:(NSURL *)url;
+(BOOL)isDropboxEnabled;
+(BOOL)isDropboxLinked;
+(BOOL)isDropboxPurchased;
+(void)setDropboxEnabled:(BOOL)enabled;
+(NSString *)DropboxPriceString;
@end
