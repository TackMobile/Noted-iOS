//
//  NTDDropboxObserver.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/20/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTDDropboxNote, DBPath;
@interface NTDDropboxObserver : NSObject

+ (instancetype)sharedObserver;
- (BOOL)observeNote:(NTDDropboxNote *)note;
- (BOOL)observeRootPath:(DBPath *)path;
- (void)stopObserving:(id)observed;
- (void)removeAllObservers;

@end
