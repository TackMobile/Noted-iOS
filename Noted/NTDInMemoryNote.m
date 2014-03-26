//
//  NTDInMemoryNote.m
//  Noted
//
//  Created by Vladimir Fleurima on 3/26/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"
#import "NTDNote+ImplUtils.h"
#import "NTDInMemoryNote.h"
#import "NTDDeletedNotePlaceholder.h"
#import "NTDTheme.h"

@interface NTDInMemoryNote ()

@property (nonatomic, strong) NSString *headline, *text;
@property (nonatomic, strong) NTDTheme *theme;
@property (nonatomic, strong) NSDate *lastModifiedDate;

@end

static NSMutableArray *notes;
@implementation NTDInMemoryNote

+(void)initialize
{
    [self reset];
}

+ (void)listNotesWithCompletionHandler:(void(^)(NSArray *notes))handler
{
    handler(notes);
}

+ (void)newNoteWithCompletionHandler:(void(^)(NTDNote *note))handler
{
    NTDInMemoryNote *note = [NTDInMemoryNote new];
    [notes addObject:note];
    handler((NTDNote *)note);
}

+ (void)restoreNote:(NTDDeletedNotePlaceholder *)deletedNote completionHandler:(void(^)(NTDNote *note))handler
{
    [self newNoteWithCompletionHandler:^(NTDNote *note) {
        [note setTheme:deletedNote.theme];
        [note setLastModifiedDate:deletedNote.lastModifiedDate];
        [note setText:deletedNote.bodyText];
        
        if (deletedNote.indexPath.item <= notes.count) {
            [notes removeObject:note];
            [notes insertObject:note atIndex:deletedNote.indexPath.item];
        }
        
        handler(note);
    }];
}

+(void)reset
{
    notes = [NSMutableArray new];
}

-(id)init
{
    if (self = [super init]) {
        self.lastModifiedDate = [NSDate date];
        self.theme = [NTDTheme themeForColorScheme:NTDColorSchemeWhite];
    }
    return self;
}

-(void)setText:(NSString *)text
{
    _text = text;
    _headline = [NTDNote headlineForString:_text];
}

- (NSURL *)fileURL
{
    return nil;
}

- (NSString *)filename
{
    return [NSString stringWithFormat:@"Note %d.txt", [notes indexOfObject:self] + 1];
}

- (NTDNoteFileState)fileState
{
    return NTDNoteFileStateOpened;
}

- (void)openWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

- (void)closeWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

- (void)deleteWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    [notes removeObject:self];
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

- (void)updateWithCompletionHandler:(NTDNoteDefaultCompletionHandler)handler
{
    handler = [NTDNote handlerDispatchedToMainQueue:handler];
    handler(YES);
}

@end
