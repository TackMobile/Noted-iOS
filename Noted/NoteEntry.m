//
//  NoteEntry.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteEntry.h"

@implementation NoteEntry

@synthesize  fileURL = _fileURL;
@synthesize  noteData = _noteData;
@synthesize state = _state;
@synthesize version = _version;
@synthesize typeOfCell = _typeOfCell;

-(id)initWithFileURL:(NSURL *)fileURL noteData:(NoteData *)noteData state:(UIDocumentState)state version:(NSFileVersion *)version {
    if ((self = [super init])) {
        self.fileURL = fileURL;
        self.noteData = noteData;
        self.state = state;
        self.version = version;
    }
    return self;
}

-(NSString*) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

@end
