//
//  ICloudManager.h
//  singleton-proxy for iCloud access
//  Noted
//
//  Created by Ben Pilcher on 9/6/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NoteEntry;
@class NoteDocument;

typedef void(^iCloudAvailableBlock)(BOOL available);
typedef void(^iCloudLoadingComplete)(NSMutableOrderedSet *note,NSMutableOrderedSet *noteDocs);
typedef void(^iCloudLoadingFailed)();

@interface CloudManager : NSObject

+ (CloudManager *)sharedInstance;
- (void)initializeiCloudAccessWithCompletion:(iCloudAvailableBlock)available;
- (void)refreshWithCompleteBlock:(iCloudLoadingComplete)complete failBlock:(iCloudLoadingFailed)failed;
- (NoteDocument *)insertNewEntryAtIndex:(int)index completion:(void(^)(NoteDocument *))completion;
- (void)deleteEntry:(NoteEntry *)entry withCompletion:(void (^)())completion;
- (NSURL *)getDocURL:(NSString *)filename;

@end
