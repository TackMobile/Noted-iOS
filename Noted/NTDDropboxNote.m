//
//  NTDDropboxNote.m
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "NTDDropboxManager.h"
#import "NTDDropboxNote.h"
#import "NTDNote+ImplUtils.h"
#import "NTDTheme.h"
#import "NTDDropboxObserver.h"

static dispatch_queue_t background_dispatch_queue, main_dispatch_queue;
static NSUInteger filenameCounter = 1;
static DBDatastore *datastore;

@interface NTDDropboxNote ()

@property (nonatomic, strong) DBFile *file;
@property (nonatomic, strong) DBFileInfo *fileinfo;
@property (nonatomic, strong) DBRecord *metadata;
@property (nonatomic, strong) NSString *bodyText;

@end

@implementation NTDDropboxNote

+(void)initialize
{
    background_dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    main_dispatch_queue = dispatch_get_main_queue();
}

+(instancetype)noteFromFileInfo:(DBFileInfo *)fileinfo
{
    NTDDropboxNote *note = [[NTDDropboxNote alloc] init];
    note.fileinfo = fileinfo;
    return note;
}

#pragma mark - Properties
-(void)setFile:(DBFile *)file
{
    _file = file;
    if (file != nil)
        self.fileinfo = file.info;
}

-(void)setFileinfo:(DBFileInfo *)fileinfo
{
    _fileinfo = fileinfo;
    if (fileinfo != nil) {
        [self refreshMetadata];
    }
}

#pragma mark - Helpers
+ (DBPath *)rootPath
{
    return [DBPath root];
}

+ (DBPath *)pathForNewNote
{
    DBFileInfo *fileinfo;
    DBPath *path;
    do
    {
        NSString *basename = [NSString stringWithFormat:@"Note %d", filenameCounter];
        NSString *filename = [basename stringByAppendingPathExtension:NTDNoteFileExtension];
        path = [[self rootPath] childPath:filename];
        fileinfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:path error:nil];
        filenameCounter++;
    }
    while (fileinfo);

    return path;
}

#pragma mark - NTDNote
+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler
{
    dispatch_async(background_dispatch_queue, ^{
        [NTDDropboxManager setup];
        DBError __autoreleasing *error;
        NSArray *fileinfoArray = [[DBFilesystem sharedFilesystem] listFolder:[self rootPath] error:&error];
        if (error) {
            [NTDNote logError:error withMessage:@"Couldn't list files!"];
            dispatch_async(main_dispatch_queue, ^{
                handler(nil);
            });
            return;
        }

        BOOL isOK = [[NTDDropboxObserver sharedObserver] observeRootPath:[self rootPath]];
        if (!isOK) {
            NSLog(@"Couldn't observe path: %@", [self rootPath].stringValue);
        }
        datastore = [DBDatastore openDefaultStoreForAccount:[[DBAccountManager sharedManager] linkedAccount]
                                                      error:&error];
        if (error || !datastore) [NTDNote logError:error withMessage:@"Couldn't open default datastore."];
        
        NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[fileinfoArray count]];
        for (DBFileInfo *fileinfo in fileinfoArray) {
            NTDDropboxNote *note = [[NTDDropboxNote alloc] init];
            note.fileinfo = fileinfo;
            [notes addObject:note];
            [[NTDDropboxObserver sharedObserver] observeNote:note];
            filenameCounter = MAX(filenameCounter, [NTDNote indexFromFilename:note.filename]);
        }
        
        [notes sortUsingComparator:[NTDNote comparatorUsingFilenames]];
        
        if (error) [NTDNote logError:error withMessage:@"Couldn't open datastore for metadata!"];
        
        dispatch_async(main_dispatch_queue, ^{
            handler(notes);
        });
    });
}


+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler
{
    dispatch_async(background_dispatch_queue, ^{
        DBPath *path = [self pathForNewNote];
        NTDDropboxNote *note = [[NTDDropboxNote alloc] init];
        DBError __autoreleasing *error;
        note.file = [[DBFilesystem sharedFilesystem] createFile:path error:&error];
        if (error) {
            [NTDNote logError:error withMessage:@"Couldn't create file!"];
            note = nil;
        };
        dispatch_async(main_dispatch_queue, ^{
            handler((NTDNote *)note);
        });
    });
}

//+ (void)backupNotesWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;
//+ (void)restoreNotesFromBackupWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler;

- (void)openWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    dispatch_async(background_dispatch_queue, ^{
        DBError __autoreleasing *error;
        BOOL success = YES;
        
        /* open file */
        if (self.fileState != NTDNoteFileStateOpened) {
            self.file = [[DBFilesystem sharedFilesystem] openFile:self.fileinfo.path error:&error];
            if (error) [NTDNote logError:error withMessage:@"Couldn't open file!"];
            success = (error == nil);
        }
        
        /* read text from file */
        if (success) {
            self.bodyText = [self.file readString:&error];
            if (error) [NTDNote logError:error withMessage:@"Couldn't read text from file!"]; success = NO;
        }
        
        /* return results */
        handler(success);
    });
}

- (void)closeWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    dispatch_async(background_dispatch_queue, ^{
        //TODO force save
        [self.file close];
        self.file = nil;
        handler(YES);
    });
}

- (void)deleteWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    dispatch_async(background_dispatch_queue, ^{
        DBError __autoreleasing *error;
        BOOL success = [[DBFilesystem sharedFilesystem] deletePath:self.fileinfo.path error:&error];
        if (error)
            [NTDNote logError:error withMessage:@"Couldn't delete file!"];
        else {
            //TODO think about what else needs to be cleared here.
            [self.metadata deleteRecord];
            self.file = nil;
        }
        handler(success);
    });
}

- (NSURL *)fileURL
{
    //TODO does this even work?
    NSString *path = [self.fileinfo.path stringValue];
    return [NSURL URLWithString:path];
}

- (NSString *)filename
{
    return self.fileinfo.path.name;
}


- (NSDate *)lastModifiedDate
{
    return self.fileinfo.modifiedTime;
}

- (NTDNoteFileState)fileState
{
    if (!self.file)
        return NTDNoteFileStateClosed;
    else
        return NTDNoteFileStateOpened;
}

#pragma mark Datastore-backed properties

static NSString *const kMetadataTableName = @"metadata";
static const NSString *kHeadlineKey = @"headline";
static const NSString *kThemeKey = @"theme";
static const NSString *kFilenameKey = @"filename";

- (NSString *)headline
{
    if (self.file) {
        return [NTDNote headlineForString:self.bodyText];
    } else {
        return self.metadata[kHeadlineKey];
    }
}

- (NTDTheme *)theme
{
    NTDColorScheme scheme = [self.metadata[kThemeKey] intValue];
    return [NTDTheme themeForColorScheme:scheme];
}

- (NSString *)text
{
    return self.bodyText;
}

- (void)setTheme:(NTDTheme *)theme
{
    self.metadata[kThemeKey] = @(theme.colorScheme);
    [datastore sync:nil];
}

- (void)setHeadline:(NSString *)newHeadline
{
    if (![newHeadline isEqualToString:self.metadata[kHeadlineKey]]) {
        self.metadata[kHeadlineKey] = newHeadline;
        [datastore sync:nil];
    }
}

- (void)setText:(NSString *)text
{
    if ([self.bodyText isEqualToString:text]) return;

    //TODO autosave intelligently
    DBError __autoreleasing *error;
    [self.file writeString:text error:&error];
    if (error) {
        [NTDNote logError:error withMessage:@"Couldn't save file!"];
        return;
    }
    self.bodyText = text;
    NSString *newHeadline = [NTDNote headlineForString:text];
    [self setHeadline:newHeadline];
}

-(void)refreshMetadata
{
    DBTable *table = [datastore getTable:kMetadataTableName];
    if (!table) return;
    NSArray *results = [table query:@{kFilenameKey : self.filename} error:nil];
    if (results && results.count > 0) {
        self.metadata = results[0];
    } else {
        self.metadata = [table insert:@{kFilenameKey : self.filename,
                                        kHeadlineKey : [NTDNote headlineForString:self.bodyText],
                                        kThemeKey    : @(NTDColorSchemeWhite)}];
    }
}

#pragma  mark - Import
-(void)copyFromNote:(NTDNote *)note file:(DBFile *)file
{
    self.file = file;
    self.theme = note.theme;
    self.headline = note.headline;
}

+ (void)clearExistingMetadata
{
    DBDatastore *datastore = [DBDatastore openDefaultStoreForAccount:[[DBAccountManager sharedManager] linkedAccount]
                                                  error:nil];
    if (!datastore) return;
    
    DBTable *table = [datastore getTable:kMetadataTableName];
    for (DBRecord *record in [table query:nil error:nil])
        [record deleteRecord];

    table = [datastore getTable:@"noted_metadata"];
    for (DBRecord *record in [table query:nil error:nil])
        [record deleteRecord];

    [datastore sync:nil];
}
@end
