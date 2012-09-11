//
//  NoteData.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "NoteData.h"

@implementation NoteData

@synthesize noteColor,noteText,noteLocation,dateCreated;

- (id)init
{
    if (self = [super init]) {
        //
        self.noteColor = [UIColor whiteColor];
        self.noteText = @"lorem ipsum";
        self.dateCreated = [NSDate date];
        self.noteLocation = @"0";
    }
    
    return self;
}

#pragma mark NSCoding

#define kVersionKey @"Version"
#define kTextKey @"Text"
#define kColorKey @"Color"
#define kLocationKey @"Location"
#define kDateCreatedKey @"Created"

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:1 forKey:kVersionKey];
    [encoder encodeObject:self.noteText forKey:kTextKey];
    [encoder encodeObject:self.noteColor forKey:kColorKey];
    [encoder encodeObject:self.noteLocation forKey:kLocationKey];
    [encoder encodeObject:self.dateCreated forKey:kDateCreatedKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    [decoder decodeIntForKey:kVersionKey];
    
    NoteData *data = [self init];
    
    data.noteText = [decoder decodeObjectForKey:kTextKey];
    data.noteColor = [decoder decodeObjectForKey:kColorKey];
    data.noteLocation = [decoder decodeObjectForKey:kLocationKey];
    data.dateCreated = [decoder decodeObjectForKey:kDateCreatedKey];
    
    return data;
}

@end
