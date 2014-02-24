//
//  NTDDummyNote.m
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDDeletedNotePlaceholder.h"
#import "NTDTheme.h"

@interface NTDDeletedNotePlaceholder ()

@property (nonatomic, strong) NSString *filename, *headline, *bodyText;
@property (nonatomic, strong) NTDTheme *theme;
@property (nonatomic, strong) NSDate *lastModifiedDate;

@end

@implementation NTDDeletedNotePlaceholder

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note {
    if (self = [super init]) {
        self.filename = note.filename;
        self.headline = note.headline;
        self.lastModifiedDate = note.lastModifiedDate;
        self.theme = note.theme;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(flushSavedColumns:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        /* In theory, this should run before (and not concurrently with) the deletion that will happen
         * after our init method returns */
        [note openWithCompletionHandler:^(BOOL success) {
           if (success) self.bodyText = note.text;
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)flushSavedColumns:(NSNotification *)notfication
{
    self.savedColumnsForDeletion = nil;
}
@end
