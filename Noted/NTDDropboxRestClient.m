//
//  NTDDropboxRestClient.m
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import "NTDDropboxRestClient.h"

@interface NTDDropboxRestClient () <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;
@end

@implementation NTDDropboxRestClient

NSString *dropboxRoot = @"/";

- (id)init {
  if (self = [super init]) {
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
  }
  return self;
}

#pragma mark - Upload

- (void)uploadFileToDropbox:(NSString *)filename {
  NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *localPath = [localDir stringByAppendingPathComponent:filename];
  
  NSString *destinationDirectory = dropboxRoot;
  
  [self.restClient uploadFile:filename toPath:destinationDirectory withParentRev:nil fromPath:localPath];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
  NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
  NSLog(@"File upload failed with error: %@", error);
}

#pragma mark - Download

- (void)downloadDropboxFile:(NSString *)dropboxPath intoPath:(NSString *)localPath {
  [self.restClient loadFile:dropboxPath atRev:nil intoPath:localPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
  NSLog(@"File loaded into path: %@", localPath);
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
  NSLog(@"There was an error loading the file: %@", error);
}

#pragma mark - Metadata

- (void)listDropboxDirectory {
  [self.restClient loadMetadata:dropboxRoot];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
  
  // Currently lists contents of directory
  if (metadata.isDirectory) {
    NSLog(@"Folder '%@' contains:", metadata.path);
    for (DBMetadata *file in metadata.contents) {
      NSLog(@"	%@", file.filename);
    }
  }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
  NSLog(@"Error loading metadata: %@", error);
}

@end
