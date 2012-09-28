//
//  StorageSettingsManager.h
//  Noted
//
//  Created by Ben Pilcher on 9/5/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kFirstUse;

typedef enum {
    kTKiCloud,
    kTKlocal
} TKPreferredStorage;

@interface FileStorageState : NSObject

+ (TKPreferredStorage)preferredStorage;
+ (void)setPreferredStorage:(TKPreferredStorage)storage;
+ (BOOL)preferredStoragePrompted;
+ (void)setPreferredStoragePrompted:(BOOL)prompted;
+ (BOOL)shouldPrompt;
+ (BOOL)isFirstUse;

+ (BOOL)iCloudOn;
+ (void)setiCloudOn:(BOOL)on;

+ (BOOL)iCloudWasOn;
+ (void)setiCloudWasOn:(BOOL)on;

+ (BOOL)iCloudPrompted;
+ (void)setiCloudPrompted:(BOOL)prompted;

@end
