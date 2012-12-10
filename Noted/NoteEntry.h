//
//  NoteEntry.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NoteData;

@interface NoteEntry : NSObject

@property (strong) NSURL *fileURL;
@property (strong) NoteData *noteData;
@property (assign) UIDocumentState state;
@property (strong) NSFileVersion *version;
@property (strong) NSString *typeOfCell;
@property BOOL adding;
@property BOOL moving;

- (id)initWithFileURL:(NSURL*)fileURL noteData:(NoteData*)noteData state:(UIDocumentState) state version:(NSFileVersion*)version;

// metadata
- (NSString *)title;
- (NSString *)displayText;
- (NSString *)relativeDateString;
- (NSString *)absoluteDateString;

// so our main list can imitate the document
// without loading it into memory
- (NSString *)text;
- (UIColor *)noteColor;
- (NSDate *)dateCreated;

@end
