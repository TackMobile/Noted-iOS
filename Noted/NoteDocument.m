//
//  NoteDocument.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteDocument.h"
#import "NoteData.h"

#define DATA_FILENAME @"note.data"


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

- (id)contentsForType:(NSString *)typeName error:(NSError*__autoreleasing*)outError {
    NSLog(@"Saving current Document");
    if (self.data == nil) {        
        return nil;    
    }
    
    NSMutableDictionary *wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.data toWrappers:wrappers preferredFilename:DATA_FILENAME];   
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
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
    
}


- (NoteData*)data {    
    if (_data == nil) {
        if (self.fileWrapper != nil) {
            self.data = [self decodeObjectFromWrapperWithPreferredFilename:DATA_FILENAME];
        } else {
            self.data = [[NoteData alloc] init];
        }
    }    
    return _data;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    self.fileWrapper = (NSFileWrapper*) contents;    
    
    // The rest will be lazy loaded...
    self.data = nil;
    
    return YES;
    
}


- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
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



@end
