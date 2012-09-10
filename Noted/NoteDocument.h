//
//  NoteDocument.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteEntry;

extern NSString *const kNoteExtension;

@interface NoteDocument : UIDocument

- (NSString*)description;
- (NSString*)text;
- (UIColor*)color;
- (NSString*)location;
- (void)setText:(NSString*)text;
- (void)setColor:(UIColor*)color;
- (void)setLocation:(NSString*)location;

+ (NSString *)uniqueNoteName;
+ (NSString *)stringForState:(UIDocumentState)state;

- (NoteEntry *)noteEntry;
- (NSString *)debugDescription;

@end
