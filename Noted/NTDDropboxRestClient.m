//
//  NTDDropboxRestClient.m
//  Noted
//
//  Created by Kelvin Kosbab on 8/17/15.
//  Copyright (c) 2015 Tack Mobile. All rights reserved.
//

#import "NTDDropboxRestClient.h"
#import "NTDNote.h"
#import "NTDTheme.h"
#import "NTDCollectionViewController.h"

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

#pragma mark - Syncing

- (void)syncWithDropbox {
  if (!self.syncInProgress) {
    self.syncInProgress = YES;
    [self fetchDropboxMetadata];
  } else {
    NSLog(@"syncWithDropbox: Sync in progress. Do nothing.");
  }
}

- (void)compareDropboxWithLocal:(DBMetadata *)metadata {
  if (metadata.isDirectory) {
    NSArray *dropboxFiles = metadata.contents;
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
      
      for (NTDNote *note in notes) {
        DBMetadata *dropboxFile = [self dropboxContainsFilename:note.filename inDropboxMetadataArray:dropboxFiles];
        if (dropboxFile == nil) {
          [self uploadFileToDropbox:note withDropboxFileRev:nil];
        } else if ([note.lastModifiedDate compare:dropboxFile.lastModifiedDate] == NSOrderedDescending) {
          // Local note modified after dropbox file
          [self uploadFileToDropbox:note withDropboxFileRev:dropboxFile.rev];
        } else if ([note.lastModifiedDate compare:dropboxFile.lastModifiedDate] == NSOrderedAscending) {
          // Dropbox file modified after local note
          [self downloadDropboxFile:dropboxFile toNote:note];
        }
      }
      
      for (DBMetadata *file in dropboxFiles) {
        if ([self localContainsFilename:file.filename inLocalMetadataArray:notes] == nil) {
          [self downloadDropboxFile:file toNote:nil];
        }
      }
      
      self.syncInProgress = NO;
    }];
    
  } else {
    NSLog(@"restClient laodedMetadata: path must be directory");
    self.syncInProgress = NO;
  }
}

#pragma mark - Upload

- (void)uploadFileToDropbox:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  [self.restClient uploadFile:note.filename toPath:dropboxRoot withParentRev:rev fromPath:note.fileURL.path];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
  NSLog(@"Note uploaded successfully to dropbox: %@", metadata.filename);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
  NSLog(@"Note upload failed to dropbox with error: %@", error);
}

#pragma mark - Download

- (void)downloadDropboxFile:(DBMetadata *)file toNote:(NTDNote *)note {
  NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *localPath = [localDir stringByAppendingPathComponent:[file.filename stringByAppendingString:@".TMP"]];
  [self.restClient loadFile:file.path atRev:nil intoPath:localPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
  
  // Grab tmp file content and then delete
  NSString *dropboxFileText = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
  [self deleteFileAtLocalPath:localPath];
  
  [NTDNote getNoteByFilename:metadata.filename andCompletionHandler:^(NTDNote *note) {
    if (note == nil) {
      // Note does not exist. Create a new note with contents of file saved at localPath.
      [NTDNote newNoteWithText:dropboxFileText theme:[NTDTheme randomTheme] filename:metadata.filename completionHandler:^(NTDNote *note) {
        NSLog(@"New note created with filename %@", note.filename);
        [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasAddedNotification object:note];
      }];
    } else {
      // Note already exists. Note's stored file was updated. Need to reload notes in main collection view controller.
      [NTDNote updateNoteWithText:dropboxFileText filename:metadata.filename completionHandler:^(NTDNote *note) {
        NSLog(@"Note updated with filename %@", note.filename);
        [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasChangedNotification object:note];
      }];
    }
  }];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
  NSLog(@"There was an error loading the file: %@", error);
}

#pragma mark - Delete

- (void)deleteDropboxFile:(NSString *)filename {
  self.syncInProgress = YES;
//  [self.restClient deletePath:[dropboxRoot stringByAppendingPathComponent:filename]];
}

- (void) restClient:(DBRestClient *)client deletedPath:(NSString *)path {
  NSLog(@"Dropbox file deleted from path: %@", path);
  self.syncInProgress = NO;
}

- (void) restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
  NSLog(@"There was an error deleting the file: %@", error);
  self.syncInProgress = NO;
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
  
- (void)deleteFileAtLocalPath:(NSString *)localPath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error;
  if ([fileManager fileExistsAtPath:localPath]) {
    if (![fileManager removeItemAtPath:localPath error:&error]) {
      NSLog(@"Failed to delete TMP file: %@", [error localizedDescription]);
    }
  }
}

@end
