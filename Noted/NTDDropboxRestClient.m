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
@property (nonatomic) BOOL syncInProgress;

@property (nonatomic, strong) NSMutableArray *filesToUploadArray;
@property (nonatomic, strong) NSMutableArray *filesToUploadDropboxRevArray;

@property (nonatomic, strong) NSMutableArray *filesToDownloadArray;
@property (nonatomic, strong) NSMutableArray *filesToDownloadCorrespondingNoteArray;

@property (nonatomic, strong) NSMutableArray *filesToDeleteArray;

@property (nonatomic, strong) dispatch_queue_t concurrentDropboxManagerQueue;

@end

@implementation NTDDropboxRestClient

NSString *dropboxRoot = @"/";

- (id)init {
  if (self = [super init]) {
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    self.syncInProgress = NO;
    self.filesToUploadArray = [[NSMutableArray alloc] init];
    self.filesToUploadDropboxRevArray = [[NSMutableArray alloc] init];
    self.filesToDownloadArray = [[NSMutableArray alloc] init];
    self.filesToDownloadCorrespondingNoteArray = [[NSMutableArray alloc] init];
    self.filesToDeleteArray = [[NSMutableArray alloc] init];
    self.concurrentDropboxManagerQueue = dispatch_queue_create("com.tackmobile.noted.concurrentDropboxManagerQueue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

#pragma mark - files to upload arrays

- (NSArray *)filesToUpload {
  return [NSArray arrayWithArray:self.filesToUploadArray];
}

- (NSArray *)filesToUploadDropboxRev {
  return [NSArray arrayWithArray:_filesToUploadDropboxRevArray];;
}

- (void)addFileToUpload:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  [_filesToUploadArray addObject:note];
  [_filesToUploadDropboxRevArray addObject:rev == nil ? @"" : rev];
}

- (void)removeLastFileToUpload {
  [_filesToUploadArray removeLastObject];
  [_filesToUploadDropboxRevArray removeLastObject];
}

#pragma mark - files to download arrays

- (NSArray *)filesToDownload {
  return [NSArray arrayWithArray:_filesToDownloadArray];;
}

- (NSArray *)filesToDownloadCorrespondingNote {
  return [NSArray arrayWithArray:_filesToDownloadCorrespondingNoteArray];
}

- (void)addFileToDownload:(DBMetadata *)file toNote:(NTDNote *)note {
  [_filesToDownloadArray addObject:file];
  [_filesToDownloadCorrespondingNoteArray addObject:note];
}

- (void)removeLastFileToDownload {
  [_filesToDownloadArray removeLastObject];
  [_filesToDownloadCorrespondingNoteArray removeLastObject];
}

#pragma mark - files to delete arrays

- (NSArray *)filesToDelete {
  return [NSArray arrayWithArray:_filesToDeleteArray];;
}

- (void)addFileToDelete:(NSString *)filename {
  [_filesToDeleteArray addObject:filename];
}

#pragma mark - sycing values

- (void)removeLastFileToDelete {
  [_filesToDeleteArray removeLastObject];
}

- (void)setSyncing:(BOOL)syncing {
  self.syncInProgress = syncing;
}

- (BOOL)syncing {
  return self.syncInProgress;
}

#pragma mark - Syncing

- (void)syncWithDropbox {
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void) {
    if (![self syncing]) {
      [self setSyncing:YES];
      [self fetchDropboxMetadata];
    } else {
      dispatch_async(dispatch_get_main_queue(), ^(void){
        [NTDDropboxManager dismissModalIfShowing];
        NSLog(@"syncWithDropbox: Sync in progress. Do nothing.");
      });
    }
  });
}

- (void)compareDropboxWithLocal:(DBMetadata *)metadata {
  if (metadata.isDirectory) {
    NSArray *dropboxFiles = metadata.contents;
    
    [NTDNote listNotesWithCompletionHandler:^(NSArray *notes) {
      
      for (DBMetadata *file in dropboxFiles) {
        if ([self localContainsDropboxFilename:file inLocalMetadataArray:notes] == nil && !file.isDeleted && file.totalBytes < 5000) {
          [self addFileToDownload:file toNote:@""];
        }
      }
      
      for (NTDNote *note in notes) {
        DBMetadata *dropboxFile = [self dropboxContainsNoteFilename:note inDropboxMetadataArray:dropboxFiles];
        if (dropboxFile == nil) {
          [self addFileToUpload:note withDropboxFileRev:nil];
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
          [self addFileToUpload:note withDropboxFileRev:dropboxFile.rev];
        } else if (![note.dropboxRev isEqualToString:dropboxFile.rev]) {
          // Modified dates do not match and rev IDs do not match.
          // Upload note to dropbox and download updated file from dropbox.
          [self addFileToUpload:note withDropboxFileRev:@""];
          [self addFileToDownload:dropboxFile toNote:@""];
        }
      }
      
      // At this point array of files to upload and download should be compiled
      [self performSync];
    }];
    
  } else {
    NSLog(@"restClient laodedMetadata: path must be directory");
    [self setSyncing:NO];
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
    if ([[[self filesToDownloadCorrespondingNote] firstObject] isKindOfClass:[NSString class]]) { // If string then note does not exist locally
      [self downloadDropboxFile:fileToDownload toNote:nil];
    } else {
      NTDNote *noteToUpdate = (NTDNote *)[[self filesToDownloadCorrespondingNote] lastObject];
      [self downloadDropboxFile:fileToDownload toNote:noteToUpdate];
    }
  } else if (self.filesToDelete.count > 0) {
    NSString *filenameToDelete = (NSString *)[[self filesToDelete] lastObject];
    [self deleteDropboxFile:filenameToDelete];
  } else {
    [self setSyncing:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
      [NTDDropboxManager dismissModalIfShowing];
    });
  }
}

#pragma mark - Upload

- (void)uploadFile:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  [self addFileToUpload:note withDropboxFileRev:rev];
  if (![self syncing]) {
    [self setSyncing:YES];
    [self performSync];
  }
}

- (void)uploadFileToDropbox:(NTDNote *)note withDropboxFileRev:(NSString *)rev {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient uploadFile:note.filename toPath:dropboxRoot withParentRev:rev fromPath:note.fileURL.path];
  });
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
  NSLog(@"Note uploaded successfully to dropbox: %@", metadata.filename);
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [NTDNote updateNoteWithDropboxMetadata:[srcPath lastPathComponent] newFilename:metadata.filename rev:metadata.rev clientMtime:metadata.clientMtime lastModifiedDate:metadata.lastModifiedDate completionHandler:^(NTDNote *note) {}];
  });
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    [self removeLastFileToUpload];
    [self performSync];
  });
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    NSString *sourcePath = (NSString *)[[error userInfo] objectForKey:@"sourcePath"];
    NSString* filename = [sourcePath lastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) {
      NSLog(@"Note upload failed to dropbox with filename: %@. Retrying.", filename);
      [self performSync];
    } else {
      NSLog(@"Note upload failed to dropbox with filename: %@ and file does not exist.", filename);
      [self removeLastFileToUpload];
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
  // Grab tmp file content and then delete
  NSString *dropboxFileText = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
  [self deleteFileAtLocalPath:localPath];
  
  [NTDNote getNoteByFilename:metadata.filename andCompletionHandler:^(NTDNote *note) {
    if (note == nil) {
      // Note does not exist. Create a new note with contents of file saved at localPath.
      [NTDNote newNoteWithText:dropboxFileText theme:[NTDTheme randomTheme] lastModifiedDate:metadata.lastModifiedDate filename:metadata.filename dropboxRev:metadata.rev dropboxClientMtime:metadata.clientMtime completionHandler:^(NTDNote *note) {
        NSLog(@"New note created with filename %@", note.filename);
        [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasAddedNotification object:note];
        
        dispatch_async(self.concurrentDropboxManagerQueue, ^(void){});
        [self removeLastFileToDownload];
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
        
        dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
          [self removeLastFileToDownload];
          [self performSync];
        });
      }];
    } else {
      // Create new note
      dispatch_async(dispatch_get_main_queue(), ^(void){
        [NTDNote newNoteWithText:dropboxFileText theme:[NTDTheme randomTheme] lastModifiedDate:metadata.lastModifiedDate filename:metadata.filename dropboxRev:metadata.rev dropboxClientMtime:metadata.clientMtime completionHandler:^(NTDNote *note) {
          NSLog(@"New note created with filename %@", note.filename);
          [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasAddedNotification object:note];
          
          dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
            [self removeLastFileToDownload];
            [self performSync];
          });
        }];
      });
    }
    
  }];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
  NSString *dropboxPath = (NSString *)[[error userInfo] objectForKey:@"path"];
  NSString *dropboxError = (NSString *)[[error userInfo] objectForKey:@"error"];
  NSString *filename = [dropboxPath lastPathComponent];
  if (dropboxError != nil && [dropboxError rangeOfString:@"delete"].location != NSNotFound) {
    // File has been deleted on dropbox. Need to delete locally.
    [NTDNote getNoteByFilename:filename andCompletionHandler:^(NTDNote *note) {
      if (note != nil) {
        NSLog(@"%@ deleted locally due to Dropbox deletion.", filename);
        [NSNotificationCenter.defaultCenter postNotificationName:NTDNoteWasDeletedNotification object:filename];
      }
    }];
    
    dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
      [self removeLastFileToDownload];
      [self performSync];
    });
  } else {
    // Other error. Retry.
    NSLog(@"There was an error loading the file: %@. Retrying.", error);
    dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
      [self performSync];
    });
  }
}

#pragma mark - Delete

- (void)deleteFile:(NSString *)filename {
  [self addFileToDelete:filename];
  if (![self syncing]) {
    [self setSyncing:YES];
    [self performSync];
  }
}

- (void)deleteDropboxFile:(NSString *)filename {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient deletePath:[dropboxRoot stringByAppendingPathComponent:filename]];
  });
}

- (void) restClient:(DBRestClient *)client deletedPath:(NSString *)path {
  NSLog(@"Dropbox file deleted from path: %@", path);
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    [self removeLastFileToDelete];
    [self performSync];
  });
}

- (void) restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
  NSLog(@"There was an error deleting the file: %@", error);
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    [self removeLastFileToDelete];
    [self performSync];
  });
}

#pragma mark - Metadata

- (void)fetchDropboxMetadata {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient loadMetadata:dropboxRoot withParams:[NSDictionary dictionaryWithObject:@"true" forKey:@"include_deleted"]];
  });
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
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
  
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    [self setSyncing:NO];
  });
}

#pragma mark - Rename

- (void)renameDropboxFile:(NSString *)existingPath newPath:(NSString *)newPath {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.restClient moveFrom:existingPath toPath:newPath];
  });
}

- (void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result {
  NSLog(@"Dropbox file moved from path %@ to path %@", from_path, result.path);
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
    [self removeLastFileToDownload];
    [self performSync];
  });
}

- (void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error {
  NSLog(@"movePathFailedWithError: Error moving dropbox file: %@", error);
  dispatch_async(self.concurrentDropboxManagerQueue, ^(void){
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
