//
//  NoteData.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tackmobile. All rights reserved.
//

#import "NoteData.h"

@implementation NoteData

@synthesize dateCreated;
@synthesize noteColor,noteText,noteLocation;

-(id)initWithText:(NSString*)text color:(UIColor*)color location:(NSString*)location {
    if ((self = [super init])) {
        self.noteText = text;
        self.noteColor = color;
        self.noteLocation = location;
        self.dateCreated = [NSDate date];
    }
    return self;
}

-(id)init {
    return [self initWithText:@"" color:[UIColor whiteColor] location:nil];
}

#pragma mark NSCoding

#define kVersionKey @"Version"
#define kTextKey @"Text"
#define kColorKey @"Color"
#define kLocationKey @"Location"
#define kDateCreatedKey @"Created"

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:1 forKey:kVersionKey];
    [encoder encodeObject:self.noteText forKey:kTextKey];
    [encoder encodeObject:self.noteColor forKey:kColorKey];
    [encoder encodeObject:self.noteLocation forKey:kLocationKey];
    [encoder encodeObject:self.dateCreated forKey:kDateCreatedKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    [decoder decodeIntForKey:kVersionKey];
    NSString *text = [decoder decodeObjectForKey:kTextKey];
    NSLog(@"unarchiving note with text:%@ [%d]",text,__LINE__);
    UIColor *color = [decoder decodeObjectForKey:kColorKey];
    NSString *location = [decoder decodeObjectForKey:kLocationKey];
    NSDate *created = [decoder decodeObjectForKey:kDateCreatedKey];
    
    NoteData *data = [self initWithText:text color:color location:location];
    [data setDateCreated:created];
    
    return data;
}

@end
