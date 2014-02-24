//
//  NTDDropboxNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTDNote, DBFile, DBFileInfo;
@interface NTDDropboxNote : NSObject

+ (instancetype)noteFromFileInfo:(DBFileInfo *)fileinfo;

- (void)copyFromNote:(NTDNote *)note file:(DBFile *)file;
+ (void)clearExistingMetadataWithCompletionBlock:(NTDVoidBlock)completionBlock;
@end
