//
//  NoteDocument.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteData;
@class NoteEntry;

extern NSString *const kNoteExtension;

@interface NoteDocument : UIDocument

@property (strong, nonatomic) NoteData *data;
//@property (nonatomic, strong) NoteEntry *noteEntry;

// proxy to NoteData
- (NSString*)text;
- (void)setText:(NSString*)text;
- (UIColor*)color;
- (void)setColor:(UIColor*)color;
- (NSString*)location;
- (void)setLocation:(NSString*)location;
- (NSDate *)dateCreated;// no getter needed

// helpers
- (NSString*)description;
+ (NSString *)uniqueNoteName;
+ (NSString *)stringForState:(UIDocumentState)state;

//#warning TODO: get rid of this
// update the entry's state after closing doc
//- (void)setEntryClosed;

@end
