//
//  NTDDummyNote.m
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDDummyNote.h"

@interface NTDDummyNote ()

@property (nonatomic, strong) NSString *_filename;
@property (nonatomic, strong) NSDate *_lastModifiedDate;
@property (nonatomic, strong) NTDTheme *_theme;
@property (nonatomic, strong) NSString *_text;

@end

@implementation NTDDummyNote

- (NTDDummyNote *)initWithNote:(NTDNote *)note {
    self._filename = [note filename];
    self._lastModifiedDate = [note lastModifiedDate];
    self._theme = [note theme];
    self._text = [note text];
    
    NSLog(@"dummy note with text: %@", self._text);
    
    return self;
}

- (NSString *)filename {
    return self._filename;
}
- (NSDate *)lastModifiedDate {
    return self._lastModifiedDate;
}
- (NTDTheme *)theme {
    return self._theme;
}
- (NSString *)text {
    return self._text;
}

@end
