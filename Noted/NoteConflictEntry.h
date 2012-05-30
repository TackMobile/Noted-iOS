//
//  NoteConflictEntry.h
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NoteData;

@interface NoteConflictEntry : NSObject

@property (strong) NoteData *noteData;
@property (strong) NSFileVersion *version;

-(id)initWithFileVersion:(NSFileVersion*)version noteData:(NoteData*)noteData;

@end
