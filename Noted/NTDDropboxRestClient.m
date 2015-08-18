//
//  NTDDropboxRestClient.m
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import "NTDDropboxRestClient.h"
#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"

@interface NTDDropboxRestClient () <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;
@property BOOL syncInProgress;
@end

@implementation NTDDropboxRestClient

NSString *dropboxRoot = @"/";

- (id)init {
  if (self = [super init]) {
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    self.syncInProgress = NO;
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

- (void)fetchDropboxMetadata {
  NSLog(@"fetchDropboxMetadata enter");
  [self.restClient loadMetadata:dropboxRoot];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
  NSLog(@"loadedMetadata: Folder '%@' contains:", metadata.path);
  [self compareDropboxWithLocal:metadata];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
  NSLog(@"loadMetadataFailedWithError: Error loading metadata: %@", error);
  self.syncInProgress = NO;
}

#pragma mark - Syncing

- (void)syncWithDropbox {
  NSLog(@"syncWithDropbox enter");
  if (!self.syncInProgress) {
    self.syncInProgress = YES;
    [self fetchDropboxMetadata];
  } else {
    NSLog(@"syncWithDropbox: Sync in progress. Do nothing.");
  }
}

- (void)compareDropboxWithLocal:(DBMetadata *)metadata {
  NSLog(@"compareDropboxWithLocal enter");
  if (metadata.isDirectory) {
    
    [NTDNoteDocument listNotesWithCompletionHandler:^(NSArray *notes) {
      
      for (DBMetadata *file in metadata.contents) {
        NSLog(@"compareDropboxWithLocal:Dropbox %@ - %@", file.filename, file.lastModifiedDate);
        NTDNoteMetadata *note = [self localContainsFilename:file.filename inLocalMetadataArray:notes];
        if (note != nil) {
          // Local file exists. Compare last modified.
          if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedDescending) {
            // Dropbox file modified after local note
          } else if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedAscending) {
            // Local note modified after dropbox file
          } else {
            // Dropbox file last modified equals note last modified
            // Do nothing
          }
        } else {
          // Local does not contain file. Download and save dropbox file to local storage.
          NSLog(@"Need to download %@", file.filename);
        }
      }
      
      for (NTDNoteMetadata *note in notes) {
        NSLog(@"compareDropboxWithLocal:Local %@ - %@", note.filename, note.lastModifiedDate);
        DBMetadata *dropboxFile = [self dropboxContainsFilename:note.filename inDropboxMetadataArray:metadata.contents];
        if (dropboxFile == nil) {
          NSLog(@"Need to upload %@ to dropbox", note.filename);
        } // Don't need to cover the else case where the file is in dropbox because it is covered in the first loop through the dropbox files
      }
    }];
    
  } else {
    NSLog(@"restClient laodedMetadata: path must be directory");
    self.syncInProgress = NO;
  }
}

#pragma mark - Helpers

- (NTDNoteMetadata *)localContainsFilename:(NSString *)filename inLocalMetadataArray:(NSArray *)array {
  for (int i = 0; i < array.count; i++) {
    NTDNoteMetadata *file = (NTDNoteMetadata *)[array objectAtIndex:i];
    if ([filename isEqualToString:file.filename]) {
      return file;
    }
  }
  return nil;
}

- (DBMetadata *)dropboxContainsFilename:(NSString *)filename inDropboxMetadataArray:(NSArray *)array {
  for (int i = 0; i < array.count; i++) {
    DBMetadata *file = (DBMetadata *)[array objectAtIndex:i];
    if ([filename isEqualToString:file.filename]) {
      return file;
    }
  }
  return nil;
}

@end
