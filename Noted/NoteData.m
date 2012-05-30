//
//  NoteData.m
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NoteData.h"

@implementation NoteData
@synthesize  noteColor,noteText,noteLocation;

-(id)initWithText:(NSString*)text color:(UIColor*)color location:(NSString*)location {
    if ((self = [super init])) {
        self.noteText = text;
        self.noteColor = color;
        self.noteLocation = location;
    }
    return self;
}

-(id)init {
    return [self initWithText:nil color:nil location:nil];
}

#pragma mark NSCoding

#define kVersionKey @"Version"
#define kTextKey @"Text"
#define kColorKey @"Color"
#define kLocationKey @"Location"

- (void)encodeWithCoder:(NSCoder *)encoder {
[encoder encodeInt:1 forKey:kVersionKey];
[encoder encodeObject:self.noteText forKey:kTextKey];
[encoder encodeObject:self.noteColor forKey:kColorKey];
[encoder encodeObject:self.noteLocation forKey:kLocationKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
[decoder decodeIntForKey:kVersionKey];
NSString *text = [decoder decodeObjectForKey:kTextKey];
UIColor *color = [decoder decodeObjectForKey:kColorKey];
NSString *location = [decoder decodeObjectForKey:kLocationKey];
return [self initWithText:text color:color location:location];
}


@end
