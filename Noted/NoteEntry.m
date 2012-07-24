//
//  NoteEntry.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NoteEntry.h"
#import "Utilities.h"
#import "NoteData.h"

@implementation NoteEntry

@synthesize fileURL;
@synthesize noteData;
@synthesize state;
@synthesize version;
@synthesize typeOfCell;
@synthesize adding;
@synthesize moving;

-(id)initWithFileURL:(NSURL *)furl noteData:(NoteData *)ndata state:(UIDocumentState)st version:(NSFileVersion *)v {
    if ((self = [super init])) {
        self.fileURL = furl;
        self.noteData = ndata;
        self.state = st;
        self.version = v;
    }
    return self;
}

- (NSString *) title {
    return [[self.noteData.noteText componentsSeparatedByString:@"\n"] objectAtIndex:0];
}

- (NSString *) relativeDateString {
    return [Utilities formatRelativeDate:self.version.modificationDate];
}

- (NSString *) absoluteDateString {
    return [Utilities formatDate:self.version.modificationDate];
}

-(NSString*) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

@end
