//
//  NTDDropboxRestClient.h
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "NTDNote.h"

@interface NTDDropboxRestClient : NSObject

- (void)syncWithDropbox;
- (void)uploadFileToDropbox:(NTDNote *)note withDropboxFileRev:(NSString *)rev;
- (void)deleteDropboxFile:(NSString *)filename;

@end
