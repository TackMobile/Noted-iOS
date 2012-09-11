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

@property (nonatomic, strong) NoteEntry *noteEntry;

- (NSString*)description;
- (NSString*)text;
- (UIColor*)color;
- (NSString*)location;
- (NSDate *)dateCreated;// no getter needed
- (void)setText:(NSString*)text;
- (void)setColor:(UIColor*)color;
- (void)setLocation:(NSString*)location;

+ (NSString *)uniqueNoteName;
+ (NSString *)stringForState:(UIDocumentState)state;

// update the entry's state after closing doc
- (void)setEntryClosed;

- (NSString *)debugDescription;

@end
