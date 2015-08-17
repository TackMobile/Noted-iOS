//
//  NTDDropboxRestClient.h
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>

@interface NTDDropboxRestClient : NSObject

- (void)uploadFileToDropbox:(NSString *)filename;
- (void)downloadDropboxFile:(NSString *)dropboxPath intoPath:(NSString *)localPath;
- (void)listDropboxDirectory;

@end
