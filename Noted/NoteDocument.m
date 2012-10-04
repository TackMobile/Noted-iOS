//
//  NoteDocument.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteDocument.h"
#import "NoteData.h"
#import "NoteEntry.h"
#import "NSString+Digest.h"

// file extension for NSFileWrapper directory
NSString *const kNoteExtension = @"ntd";
// filename for the single sub-file that
// will be inside our directory/NSFileWrapper
NSString *const kDataFilename = @"note.data";

@interface NoteDocument ()

@property (strong, nonatomic) NSFileWrapper *fileWrapper;

@end

@implementation NoteDocument

@synthesize data = _data;
@synthesize fileWrapper = _fileWrapper;
//@synthesize noteEntry = _noteEntry;


- (id)initWithFileURL:(NSURL *)url
{
    if (self = [super initWithFileURL:url]) {
        
        //NoteData *noteData = [[NoteData alloc] init];
        //NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:url];
        /*
         NoteEntry *entry = [[NoteEntry alloc] initWithFileURL:url noteData:noteData state:self.documentState version:version];
         
         entry.fileURL = url;
         entry.adding = YES;
         
         [entry setNoteData:noteData];
         
         */
        //self.noteEntry = entry;
    }
    
    return self;
}

/*
 - (NoteEntry *)noteEntry
 {
 if (!_noteEntry) {
 NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:self.fileURL];
 _noteEntry = [[NoteEntry alloc] initWithFileURL:self.fileURL noteData:nil state:self.documentState version:version];
 
 }
 
 return _noteEntry;
 }
 */

/*
 - (void)setEntryClosed
 {
 self.noteEntry.state = self.documentState;
 self.noteEntry.version = [NSFileVersion currentVersionOfItemAtURL:self.fileURL];
 self.noteEntry.adding = NO;
 }
 */

// code to write the UIDocument to disk
- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary*)wrappers preferredFilename:(NSString*)preferredFilename {
    @autoreleasepool {            
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

// Called whenever the application (auto)saves the content of a note
// Returns a snapshot of the document’s data to UIDocument, which then writes it to the document file
- (id)contentsForType:(NSString *)typeName error:(NSError*__autoreleasing*)outError {

    if (self.data == nil) {
        return nil;
    }
    
    NSMutableDictionary *wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.data toWrappers:wrappers preferredFilename:kDataFilename];   
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    
    return fileWrapper;
}

// Reading data from file wrapper
- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString*)preferredFilename {
    
    NSFileWrapper *fileWrapper = [self.fileWrapper.fileWrappers objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData *data = [fileWrapper regularFileContents];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
}

- (NoteData*)data {
    if (_data == nil) {
        if (self.fileWrapper != nil) {
            self.data = [self decodeObjectFromWrapperWithPreferredFilename:kDataFilename];
        } else {
            // brand new object
            self.data = [NoteData noteDataWithLocation:@"0"];
        }
    }
    return _data;
}

// called by the background queue whenever the read operation has been completed.
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    self.fileWrapper = (NSFileWrapper*) contents;    
    
    // The rest will be lazy loaded...
    self.data = nil;
    
    return YES;
}

#pragma mark Accessors

- (NSDate *)dateCreated
{
    return self.data.dateCreated;
}

-(NSString*)text {
    return self.data.noteText;
}

-(void)setText:(NSString *)text {
    if([self.data.noteText isEqual:text]) return;
    NSString *oldText = self.data.noteText;
    self.data.noteText = text;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setText:) object:oldText];
}

-(UIColor*)color {
    return self.data.noteColor;
}

-(void)setColor:(UIColor*)color {
    if([self.data.noteColor isEqual:color]) return;
    UIColor *oldColor = self.data.noteColor;
    self.data.noteColor = color;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setColor:) object:oldColor];
}

-(NSString*)location {
    return self.data.noteLocation;
}

-(void)setLocation:(NSString *)location {
    if ([self.data.noteLocation isEqual:location]) return;
    NSString *oldLocation = self.data.noteLocation;
    self.data.noteLocation = location;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setLocation:) object:oldLocation];
}

#pragma mark Helpers

- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

+ (NSString *)uniqueNoteName
{
    NSString *uniqueName = [NSString stringWithFormat:@"%@.%@", [NSString randomSHA1], kNoteExtension];
    
    return uniqueName;
}

+ (NSString *)stringForState:(UIDocumentState)state
{
    NSMutableArray * states = [NSMutableArray array];
    if (state == 0) {
        [states addObject:@"Normal"];
    }
    if (state & UIDocumentStateClosed) {
        [states addObject:@"Closed"];
    }
    if (state & UIDocumentStateInConflict) {
        [states addObject:@"In Conflict"];
    }
    if (state & UIDocumentStateSavingError) {
        [states addObject:@"Saving error"];
    }
    if (state & UIDocumentStateEditingDisabled) {
        [states addObject:@"Editing disabled"];
    }
    return [states componentsJoinedByString:@", "];
}

@end
