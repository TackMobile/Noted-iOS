//
//  NTDDropboxRestClient.m
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import "NTDDropboxRestClient.h"
#import "NTDNoteDocument.h"
#import "NTDNote.h"

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

- (void)uploadFileToDropbox:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  NSLog(@"uploadFileToDropbox: Uploading %@ to dropbox", note.filename);
  [self.restClient uploadFile:note.filename toPath:dropboxRoot withParentRev:rev fromPath:note.fileURL.path];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
  NSLog(@"Note %@ uploaded successfully to path: %@", metadata.filename, metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
  NSLog(@"Note upload failed for with error: %@", error);
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
  [self.restClient loadMetadata:dropboxRoot];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
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
    
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
      
      for (DBMetadata *file in metadata.contents) {
        NSLog(@"compareDropboxWithLocal:Dropbox %@ - %@", file.filename, file.lastModifiedDate);
        NTDNote *note = [self localContainsFilename:file.filename inLocalMetadataArray:notes];
        if (note != nil) {
          // Local file exists. Compare last modified.
          if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedDescending) {
            // Dropbox file modified after local note
          } else if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedAscending) {
            // Local note modified after dropbox file
            [self uploadFileToDropbox:note withDropboxFileRev:file.rev];
          } else {
            // Dropbox file last modified equals note last modified
            // Do nothing
          }
        } else {
          // Local does not contain file. Download and save dropbox file to local storage.
          NSLog(@"Need to download %@", file.filename);
        }
      }
      
      for (NTDNote *note in notes) {
        NSLog(@"compareDropboxWithLocal:Local %@ - %@", note.filename, note.lastModifiedDate);
        DBMetadata *dropboxFile = [self dropboxContainsFilename:note.filename inDropboxMetadataArray:metadata.contents];
        if (dropboxFile == nil) {
          [self uploadFileToDropbox:note withDropboxFileRev:nil];
        }
        // Don't need to cover the else case where the file is in dropbox because it is covered in the first loop through the dropbox files
      }
    }];
    
  } else {
    NSLog(@"restClient laodedMetadata: path must be directory");
    self.syncInProgress = NO;
  }
}

#pragma mark - Helpers

- (NTDNote *)localContainsFilename:(NSString *)filename inLocalMetadataArray:(NSArray *)array {
  for (int i = 0; i < array.count; i++) {
    NTDNote *note = (NTDNote *)[array objectAtIndex:i];
    if ([filename isEqualToString:note.filename]) {
      return note;
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
