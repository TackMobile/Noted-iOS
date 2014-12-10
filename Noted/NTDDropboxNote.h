//
//  NTDDropboxNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTDTheme.h"

@class NTDNote, DBFile, DBFileInfo, DBRecord;
@interface NTDDropboxNote : NSObject

/* These properties and methods are only to be used by other Dropbox-related classes
 * and NOT the application at large. */
@property (nonatomic, strong) DBFile *file;
@property (nonatomic, strong) DBFileInfo *fileinfo;
@property (nonatomic, strong) DBRecord *metadata;
@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, strong) NSString *bodyText;
@property (nonatomic, strong) NTDTheme *theme;
@property (nonatomic, strong) NSString *headline;

+ (instancetype)noteFromFileInfo:(DBFileInfo *)fileinfo;

- (void)copyFromNote:(NTDNote *)note file:(DBFile *)file;
+ (void)syncMetadataWithCompletionBlock:(NTDVoidBlock)completionBlock;
+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler;
@end
