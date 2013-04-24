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

-(NSString*) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

#pragma mark Metadata

- (NSString *) title {
    
    NSString *titleText = self.noteData.noteText;
    if (!IsEmpty(titleText)){
        // remove newline if necessary
        titleText = [self removeLeadingNewline:titleText];
        
        NSArray *components = [titleText componentsSeparatedByString:@"\n"];
        titleText = [components objectAtIndex:0];
    }     
    return titleText;
}

- (NSString *)removeLeadingNewline:(NSString *)text
{
    if ([text hasPrefix:@"\n"]) {
        text = [text substringFromIndex:1];
    }
    
    return text;
}

- (NSString *) relativeDateString {
    return (adding) ? @"..." : [Utilities formatRelativeDate:self.version.modificationDate];
}

- (NSString *) absoluteDateString {
    return (adding) ? @"..." : [Utilities formatDate:self.version.modificationDate];
}

- (NSString *) text {
    return self.noteData.noteText;
}

- (NSString *)displayText
{
    NSString *text = nil;
    if (![self.noteData.noteText hasPrefix:@"\n"]) {
        text = [NSString stringWithFormat:@"\n%@", self.noteData.noteText];
    }
    
    return text;
}

- (UIColor *)noteColor
{
    return self.noteData.noteColor;
}

- (NSDate *)dateCreated
{
    return self.noteData.dateCreated;
}

@end
