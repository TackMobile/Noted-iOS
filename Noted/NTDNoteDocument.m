//
//  NTDNoteDocument.m
//  Noted
//
//  Created by Vladimir Fleurima on 7/12/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

//TODO: better error handling in callbacks

#import "NTDNoteDocument.h"
#import "NTDNoteMetadata.h"
#import "NTDNote.h"
#import "NTDCoreDataStore.h"

static NSString *const FileExtension = @"txt";
static const NSUInteger HeadlineLength = 80;

@interface NTDNoteDocument ()
@property (nonatomic, strong) NSString *bodyText;
@property (nonatomic, strong) NTDNoteMetadata *metadata;
@end

@implementation NTDNoteDocument

#pragma mark - Helpers
+ (NSURL*)localDocumentsDirectoryURL
{
    static NSURL *localDocumentsDirectoryURL = nil;
    if (localDocumentsDirectoryURL == nil) {
        NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                                                NSUserDomainMask, YES ) objectAtIndex:0];
        localDocumentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectoryPath];
    }
    return localDocumentsDirectoryURL;
}

+ (NSURL *)newFileURL
{
    static NSDateFormatter *filenameDateFormatter = nil;
    if (!filenameDateFormatter) {
        NSString *format = @"yyyy-MM-dd HH_mm_ss";
        filenameDateFormatter = [[NSDateFormatter alloc] init];
        [filenameDateFormatter setDateFormat:format];
    }
    NSString *now = [filenameDateFormatter stringFromDate:[NSDate date]];
    NSString *basename = [NSString stringWithFormat:@"Note %@", now];
    NSString *filename = [basename stringByAppendingPathExtension:FileExtension];
    return [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:filename];
}

+ (instancetype)documentFromMetadata:(NTDNoteMetadata *)metadata
{
    NSURL *fileURL = [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:metadata.filename];
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:fileURL];
    document.metadata = metadata;
    return document;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    return [[NTDCoreDataStore sharedStore] persistingManagedObjectContext];
}

#pragma mark - UIDocument
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    if ([contents length] > 0) {
        self.bodyText = [[NSString alloc] initWithData:(NSData *)contents encoding:NSUTF8StringEncoding];
    } else {
        self.bodyText = @"";
    }
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    if (!self.bodyText) {
        self.bodyText = @"";
    }
    NSData *docData = [self.bodyText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    return docData;
}

- (BOOL)writeContents:(id)contents toURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError **)outError
{
    BOOL didSaveFile = [super writeContents:contents
                                      toURL:url
                           forSaveOperation:saveOperation
                        originalContentsURL:originalContentsURL
                                      error:outError];
    if (!didSaveFile) return NO;
    
    NSManagedObjectContext *context = [[self class] managedObjectContext];
//    if (![context hasChanges]) return didSaveFile;
    __block BOOL didSaveMetadata = YES;
    [context performBlockAndWait:^{
        self.metadata.lastModifiedDate = [NSDate date];
        [context save:outError];
        if (*outError) {
            [self revertToContentsOfURL:originalContentsURL completionHandler:NULL];
            didSaveMetadata = NO;
        }
    }];
    return didSaveMetadata;
}

#pragma mark - NTDNote

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *))handler
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NTDNoteMetadata"];
    NSSortDescriptor *filenameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:NO];
    fetchRequest.sortDescriptors = @[filenameSortDescriptor];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[results count]];
    for (NTDNoteMetadata *metadata in results) {
        [notes addObject:[self documentFromMetadata:metadata]];
    }
    handler(notes);
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *))handler
{
    NTDNoteDocument *document = [[NTDNoteDocument alloc] initWithFileURL:[self newFileURL]];
    document.metadata = [NSEntityDescription insertNewObjectForEntityForName:@"NTDNoteMetadata"
                                                      inManagedObjectContext:[self managedObjectContext]];
    document.metadata.filename = [document.fileURL lastPathComponent];
    document.metadata.lastModifiedDate = [NSDate date];
    [document saveToURL:document.fileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          (success) ? handler((NTDNote *)document) : handler(nil);
      }];
}

- (NSString *)filename
{
    return self.metadata.filename;
}

- (NSString *)headline
{
    return self.metadata.headline;
}

- (NSDate *)lastModifiedDate
{
    return self.metadata.lastModifiedDate;
}

- (NTDNoteFileState)fileState
{
    switch (self.documentState) {
        case UIDocumentStateNormal:
            return NTDNoteFileStateOpened;
        case UIDocumentStateClosed:
            return NTDNoteFileStateClosed;
        default:
            return NTDNoteFileStateError;
    }
}

- (NTDTheme *)theme
{
    return [NTDTheme themeForColorScheme:self.metadata.colorScheme];
}

- (NSString *)text
{
    return self.bodyText;
}

// Needs to: update change count; maybe notify app
- (void)setTheme:(NTDTheme *)theme
{
    if (theme.colorScheme != self.metadata.colorScheme) {
        self.metadata.colorScheme = theme.colorScheme;
        [self updateChangeCount:UIDocumentChangeDone];
    }
}
 
// Needs to: update change count; maybe notify app; update headline
- (void)setText:(NSString *)text
{
    if (![text isEqualToString:self.bodyText]) {
        self.bodyText = text;
        if (text.length < HeadlineLength) {
            self.metadata.headline = text;
        } else {
            self.metadata.headline = [text substringToIndex:HeadlineLength];
        }
        [self updateChangeCount:UIDocumentChangeDone];
    }
}
@end
