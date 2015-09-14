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
#import "NTDDropboxManager.h"

@interface NTDDropboxRestClient () <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;
@property BOOL syncInProgress;

@property NSMutableArray *filesToUpload;
@property NSMutableArray *filesToUploadDropboxRev;

@property NSMutableArray *filesToDownload;
@property NSMutableArray *filesToDownloadCorrespondingNote;
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
    [NTDDropboxManager dismissModalIfShowing];
    NSLog(@"syncWithDropbox: Sync in progress. Do nothing.");
  }
}

- (void)compareDropboxWithLocal:(DBMetadata *)metadata {
  if (metadata.isDirectory) {
    NSArray *dropboxFiles = metadata.contents;
    
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
      
      self.filesToUpload = [[NSMutableArray alloc] init];
      self.filesToUploadDropboxRev = [[NSMutableArray alloc] init];
      self.filesToDownload = [[NSMutableArray alloc] init];
      self.filesToDownloadCorrespondingNote = [[NSMutableArray alloc] init];
      
      for (DBMetadata *file in dropboxFiles) {
        if ([self localContainsDropboxFilename:file inLocalMetadataArray:notes] == nil && !file.isDeleted && file.totalBytes < 5000) {
          [[self filesToDownload] addObject:file];
          [[self filesToDownloadCorrespondingNote] addObject:@""];
        }
      }
      
      for (NTDNote *note in notes) {
        DBMetadata *dropboxFile = [self dropboxContainsNoteFilename:note inDropboxMetadataArray:dropboxFiles];
        if (dropboxFile == nil) {
          [[self filesToUpload] addObject:note];
          [[self filesToUploadDropboxRev] addObject:@""];
        } else if (dropboxFile.isDeleted) {
          // Dropbox file has been deleted. Delete local file as well.
          dispatch_async(dispatch_get_main_queue(), ^(void){
            [NTDNote getNoteByFilename:dropboxFile.filename andCompletionHandler:^(NTDNote *note) {
              if (note != nil) {
                [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasDeletedNotification object:dropboxFile.filename];
                NSLog(@"%@ deleted locally due to Dropbox deletion.", dropboxFile.filename);
              }
            }];
          });
        } else if ([note.dropboxRev isEqualToString:dropboxFile.rev] && [note.lastModifiedDate compare:dropboxFile.lastModifiedDate] == NSOrderedDescending) {
          // Local note modified after dropbox file. Rev IDs match.
          // Upload local note to dropbox.
          [[self filesToUpload] addObject:note];
          [[self filesToUploadDropboxRev] addObject:dropboxFile.rev];
        } else if (![note.dropboxRev isEqualToString:dropboxFile.rev]) {
          // Modified dates do not match and rev IDs do not match.
          // Upload note to dropbox and download updated file from dropbox.
          [[self filesToUpload] addObject:note];
          [[self filesToUploadDropboxRev] addObject:@""];
          [[self filesToDownload] addObject:dropboxFile];
          [[self filesToDownloadCorrespondingNote] addObject:@""];
        }
      }
      
      // At this point array of files to upload and download should be compiled
      [self performSync];
    }];
    
  } else {
    NSLog(@"restClient laodedMetadata: path must be directory");
    self.syncInProgress = NO;
    [NTDDropboxManager dismissModalIfShowing];
  }
}

- (void)performSync {
  if (self.filesToUpload.count > 0) {
    NTDNote *noteToUpload = (NTDNote *)[[self filesToUpload] lastObject];
    NSString *uploadRev = (NSString *)[[self filesToUploadDropboxRev] lastObject];
    [self uploadFileToDropbox:noteToUpload withDropboxFileRev:(uploadRev == nil || [uploadRev length] == 0) ? nil : uploadRev];
  } else if (self.filesToDownload.count > 0) {
    DBMetadata *fileToDownload = (DBMetadata *)[[self filesToDownload] lastObject];
    if ([[[self filesToDownloadCorrespondingNote] firstObject] isKindOfClass:[NSString class]]) { // Empty string for 
      [self downloadDropboxFile:fileToDownload toNote:nil];
    } else {
      NTDNote *noteToUpdate = (NTDNote *)[[self filesToDownloadCorrespondingNote] lastObject];
      [self downloadDropboxFile:fileToDownload toNote:noteToUpdate];
    }
  } else {
    self.syncInProgress = NO;
    [NTDDropboxManager dismissModalIfShowing];
  }
}

#pragma mark - Upload

- (void)uploadFileToDropbox:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient uploadFile:note.filename toPath:dropboxRoot withParentRev:rev fromPath:note.fileURL.path];
  });
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    NSLog(@"Note uploaded successfully to dropbox: %@", metadata.filename);
    [NTDNote updateNoteWithDropboxMetadata:[srcPath lastPathComponent] newFilename:metadata.filename rev:metadata.rev clientMtime:metadata.clientMtime lastModifiedDate:metadata.lastModifiedDate completionHandler:^(NTDNote *note) {}];
    [[self filesToUpload] removeLastObject];
    [[self filesToUploadDropboxRev] removeLastObject];
    [self performSync];
  });
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    NSString *destinationPath = (NSString *)[[error userInfo] objectForKey:@"destinationPath"];
    NSString *sourcePath = (NSString *)[[error userInfo] objectForKey:@"sourcePath"];
    NSString* filename = [sourcePath lastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) {
      NSLog(@"Note upload failed to dropbox with filename: %@. Retrying.", filename);
      [self performSync];
    } else {
      NSLog(@"Note upload failed to dropbox with filename: %@ and file does not exist.", filename);
      [[self filesToUpload] removeLastObject];
      [[self filesToUploadDropboxRev] removeLastObject];
      [self performSync];
    }
  });
}

#pragma mark - Download

- (void)downloadDropboxFile:(DBMetadata *)file toNote:(NTDNote *)note {
  NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *localPath = [localDir stringByAppendingPathComponent:[file.filename stringByAppendingString:@".TMP"]];
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient loadFile:file.path atRev:nil intoPath:localPath];
  });
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    // Grab tmp file content and then delete
    NSString *dropboxFileText = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
    [self deleteFileAtLocalPath:localPath];
    
    [NTDNote getNoteByFilename:metadata.filename andCompletionHandler:^(NTDNote *note) {
      if (note == nil) {
        // Note does not exist. Create a new note with contents of file saved at localPath.
        [NTDNote newNoteWithText:dropboxFileText theme:[NTDTheme randomTheme] lastModifiedDate:metadata.lastModifiedDate filename:metadata.filename dropboxRev:metadata.rev dropboxClientMtime:metadata.clientMtime completionHandler:^(NTDNote *note) {
          dispatch_async(dispatch_get_main_queue(), ^(void){
            NSLog(@"New note created with filename %@", note.filename);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasAddedNotification object:note];
          });
          [[self filesToDownload] removeLastObject];
          [[self filesToDownloadCorrespondingNote] removeLastObject];
          [self performSync];
        }];
        
        // If different rev IDs, duplicate document. Otherwise update note.
      } else if ([note.dropboxRev isEqualToString:metadata.rev]) {
        // Update note
        [NTDNote updateNoteWithText:dropboxFileText filename:note.filename completionHandler:^(NTDNote *note) {
          dispatch_async(dispatch_get_main_queue(), ^(void){
            NSLog(@"Note updated with filename %@", note.filename);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasChangedNotification object:note];
          });
          
          [[self filesToDownload] removeLastObject];
          [[self filesToDownloadCorrespondingNote] removeLastObject];
          [self performSync];
        }];
      } else {
        // Create new note
        [NTDNote newNoteWithText:dropboxFileText theme:[NTDTheme randomTheme] lastModifiedDate:metadata.lastModifiedDate filename:metadata.filename dropboxRev:metadata.rev dropboxClientMtime:metadata.clientMtime completionHandler:^(NTDNote *note) {
          dispatch_async(dispatch_get_main_queue(), ^(void){
            NSLog(@"New note created with filename %@", note.filename);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasAddedNotification object:note];
          });
          
          [[self filesToDownload] removeLastObject];
          [[self filesToDownloadCorrespondingNote] removeLastObject];
          [self performSync];
        }];
      }
    }];
  });
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    NSString *dropboxPath = (NSString *)[[error userInfo] objectForKey:@"path"];
    NSString *dropboxError = (NSString *)[[error userInfo] objectForKey:@"error"];
    NSString *destinationPath = (NSString *)[[error userInfo] objectForKey:@"destinationPath"];
    NSString *filename = [dropboxPath lastPathComponent];
    if (dropboxError != nil && [dropboxError rangeOfString:@"delete"].location != NSNotFound) {
      // File has been deleted on dropbox. Need to delete locally.
      dispatch_async(dispatch_get_main_queue(), ^(void){
        [NTDNote getNoteByFilename:filename andCompletionHandler:^(NTDNote *note) {
          if (note != nil) {
            NSLog(@"%@ deleted locally due to Dropbox deletion.", filename);
            [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasDeletedNotification object:filename];
          }
        }];
      });
      
      [[self filesToDownload] removeLastObject];
      [[self filesToDownloadCorrespondingNote] removeLastObject];
      [self performSync];
    } else {
      // Other error. Retry.
      NSLog(@"There was an error loading the file: %@. Retrying.", error);
      [self performSync];
    }
  });
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
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient loadMetadata:dropboxRoot withParams:[NSDictionary dictionaryWithObject:@"true" forKey:@"include_deleted"]];
  });
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self compareDropboxWithLocal:metadata];
  });
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
  NSString *dropboxPath = (NSString *)[[error userInfo] objectForKey:@"path"];
  NSString *dropboxError = (NSString *)[[error userInfo] objectForKey:@"error"];
  if (dropboxError != nil && [dropboxError rangeOfString:@"removed"].location != NSNotFound) {
    // The user has removed/deleted the Noted app folder, making it impossible to sync. Dropbox must be unlinked and then re-linked to fix.
    NSLog(@"loadMetadataFailedWithError: %@ at %@. Unlinking dropbox", dropboxError, dropboxPath);
    [NTDDropboxManager unlinkDropbox];
  } else {
    NSLog(@"loadMetadataFailedWithError: Error loading metadata: %@", error);
  }
  self.syncInProgress = NO;
}

#pragma mark - Rename

- (void)renameDropboxFile:(NSString *)existingPath newPath:(NSString *)newPath {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient moveFrom:existingPath toPath:newPath];
  });
}

- (void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result {
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    NSLog(@"Dropbox file moved from path %@ to path %@", from_path, result.path);
    [[self filesToDownload] removeLastObject];
    [[self filesToDownloadCorrespondingNote] removeLastObject];
    [self performSync];
  });
}

- (void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error {
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    NSLog(@"movePathFailedWithError: Error moving dropbox file: %@", error);
    [self performSync];
  });
}
  
#pragma mark - Helpers

- (NTDNote *)localContainsDropboxFilename:(DBMetadata *)file inLocalMetadataArray:(NSArray *)array {
  for (NTDNote *note in array) {
    if ([file.filename isEqualToString:note.filename]) {
      return note;
    }
  }
  return nil;
}

- (DBMetadata *)dropboxContainsNoteFilename:(NTDNote *)note inDropboxMetadataArray:(NSArray *)array {
  for (DBMetadata *file in array) {
    if ([note.filename isEqualToString:file.filename]) {
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