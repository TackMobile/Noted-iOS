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
        
        if (![self fileHasValidExtension:file.path andIsDirectory:file.isDirectory]) {
          // Invalid file type. Ignore and move to next file
          continue;
        }
        
        NSLog(@"compareDropboxWithLocal:Dropbox %@ - %@", file.filename, file.lastModifiedDate);
        NTDNote *note = [self localContainsFilename:file.filename inLocalMetadataArray:notes];
        if (note != nil) {
          // Local file exists. Compare last modified.
          if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedDescending) {
            // Dropbox file modified after local note
            [self downloadDropboxFile:file toNote:note];
          } else if ([file.lastModifiedDate compare:note.lastModifiedDate] == NSOrderedAscending) {
            // Local note modified after dropbox file
            [self uploadFileToDropbox:note withDropboxFileRev:file.rev];
          } else {
            // Do nothing. Dropbox file last modified equals note last modified
          }
        } else {
          // Local does not contain file. Download and save dropbox file to local storage.
          [self downloadDropboxFile:file toNote:nil];
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
      
      self.syncInProgress = NO;
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

- (void)downloadDropboxFile:(DBMetadata *)file toNote:(NTDNote *)note {
  NSString *localPath;
  if (note == nil) {
    // New note - send file to tmp directory in documents
    NSURL *url = [[NTDNote notesDirectoryURL] URLByAppendingPathComponent:file.filename];
    localPath = url.path;
  } else {
    // Update existing note - use existing note's path
    localPath = note.fileURL.path;
  }
  [self.restClient loadFile:file.path atRev:nil intoPath:localPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
  
  // Check for valid content type
  if (![self fileHasValidExtension:localPath andIsDirectory:false]) {
    [self deleteFileAtLocalPath:localPath];
    return;
  }
  
  [NTDNote getNoteByFilename:metadata.filename andCompletionHandler:^(NTDNote *note) {
    if (note == nil) {
      // Note does not exist. Create a new note with contents of file saved at localPath.
      
      [NTDNote newNoteWithPath:localPath filename:metadata.filename theme:[NTDTheme randomTheme] completionHandler:^(NTDNote *note) {
        
        NSLog(@"New note created with filename %@ at path %@", note.filename, note.fileURL.path);
        
        // Reload notes in main collection view controller
        NTDCollectionViewController *controller = (NTDCollectionViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [controller reloadNotes];
      }];
    } else {
      // Note already exists. Update existing note.
      [NTDNote updateNote:note.filename andCompletionHandler:^(NTDNote *note) {
        NSLog(@"%@ updated.", note.filename);
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
  [self.restClient deletePath:[dropboxRoot stringByAppendingPathComponent:filename]];
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
  
- (void)deleteFileAtLocalPath:(NSString *)localPath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error;
  if ([fileManager fileExistsAtPath:localPath]) {
    if (![fileManager removeItemAtPath:localPath error:&error]) {
      NSLog(@"Failed to delete TMP file: %@", [error localizedDescription]);
    } else {
      NSLog(@"Successfully deleted TMP file at %@", localPath);
    }
  }
}

- (BOOL)fileHasValidExtension:(NSString *)path andIsDirectory:(BOOL)isDirectory{
  NSArray* validExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", nil];
  NSString* extension = [[path pathExtension] lowercaseString];
  return isDirectory || [validExtensions indexOfObject:extension] == NSNotFound;
}

@end
