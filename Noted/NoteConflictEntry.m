//
//  NoteConflictEntry.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteConflictEntry.h"

@implementation NoteConflictEntry
@synthesize version = _version;
@synthesize noteData = _noteData;

-(id)initWithFileVersion:(NSFileVersion*)version noteData:(NoteData*)noteData {
    if ((self = [super init])) {
        self.version = version;
        self.noteData = noteData;
    }
    return self;
}
@end
