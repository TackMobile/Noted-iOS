//
//  ICloudManager.h
//  singleton-proxy for iCloud access
//  Noted
//
//  Created by Ben Pilcher on 9/6/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^iCloudAvailableBlock)(BOOL available);
typedef void(^iCloudLoadingComplete)(NSMutableOrderedSet *note,NSMutableOrderedSet *noteDocs);
typedef void(^iCloudLoadingFailed)();

@interface CloudManager : NSObject

+ (CloudManager *)sharedInstance;
- (void)initializeiCloudAccessWithCompletion:(iCloudAvailableBlock)available;
- (void)refreshWithCompleteBlock:(iCloudLoadingComplete)complete failBlock:(iCloudLoadingFailed)failed;
- (void)insertNewEntryAtIndex:(int)index completion:(void(^)())completion;

@end
