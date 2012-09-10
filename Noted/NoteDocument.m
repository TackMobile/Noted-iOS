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

NSString *const kNoteExtension = @"ntd";
NSString *const kDataFilename = @"note.data";

@interface NoteDocument ()

@property (strong, nonatomic) NoteData *data;
@property (strong, nonatomic) NSFileWrapper *fileWrapper;
@end

@implementation NoteDocument

@synthesize data = _data;
@synthesize fileWrapper = _fileWrapper;

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
- (id)contentsForType:(NSString *)typeName error:(NSError*__autoreleasing*)outError {
    NSLog(@"Saving current Document");
    if (self.data == nil) {        
        return nil;    
    }
        
    NSMutableDictionary *wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.data toWrappers:wrappers preferredFilename:kDataFilename];   
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    
    return fileWrapper;
}

- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString*)preferredFilename {
    
    NSFileWrapper *fileWrapper = [self.fileWrapper.fileWrappers objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData *data = [fileWrapper regularFileContents];
    if (!data){
        NSLog(@"data was nil %s [%d]",__PRETTY_FUNCTION__,__LINE__);
    }
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
}

- (NoteData*)data {    
    if (_data == nil) {
        if (self.fileWrapper != nil) {
            self.data = [self decodeObjectFromWrapperWithPreferredFilename:kDataFilename];
        } else {
            self.data = [[NoteData alloc] init];
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


- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)debugDescription
{
    NoteEntry *entry = self.noteEntry;
    return [NSString stringWithFormat:@"\n\ntext: %@, color: %@, abs time: %@",self.text,self.color,entry.absoluteDateString];
}

#pragma mark Accessors

-(NSString*)text {
    return self.data.noteText;
}
-(UIColor*)color {
    return self.data.noteColor;
}
-(NSString*)location {
    return self.data.noteLocation;
}

-(void)setText:(NSString *)text {
    if([self.data.noteText isEqual:text]) return;
    NSString *oldText = self.data.noteText;
    self.data.noteText = text;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setText:) object:oldText];
}

-(void)setColor:(UIColor*)color {
    if([self.data.noteColor isEqual:color]) return;
    UIColor *oldColor = self.data.noteColor;
    self.data.noteColor = color;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setColor:) object:oldColor];
}

-(void)setLocation:(NSString *)location {
    if ([self.data.noteLocation isEqual:location]) return;
    NSString *oldLocation = self.data.noteLocation;
    self.data.noteLocation = location;
    [self.undoManager registerUndoWithTarget:self selector:@selector(setLocation:) object:oldLocation];
}

+ (NSString *)uniqueNoteName
{
    NSString *uniqueName = [NSString stringWithFormat:@"%@.%@", [NSString randomSHA1], kNoteExtension];
    
    return uniqueName;
}

- (NoteEntry *)noteEntry
{
    NoteData * noteData = [NoteData new];
    noteData.noteText = self.text;
    noteData.noteLocation = self.location;
    noteData.noteColor = self.color;
    
    NSURL * fileURL = self.fileURL;
    UIDocumentState state = self.documentState;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
    NSLog(@"Loaded File URL: %@, State: %@, Last Modified: %@", [self.fileURL lastPathComponent], [NoteDocument stringForState:state], [dateFormatter stringFromDate:version.modificationDate]);
    
    NoteEntry *entry = [[NoteEntry alloc] initWithFileURL:fileURL noteData:noteData state:state version:version];
    
    return entry;
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
