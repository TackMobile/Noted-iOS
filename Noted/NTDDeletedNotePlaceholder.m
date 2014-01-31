//
//  NTDDummyNote.m
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDDeletedNotePlaceholder.h"

@interface NTDDeletedNotePlaceholder ()

@property (nonatomic, strong) NSString *_filename;
@property (nonatomic, strong) NSString *_bodyText;
@property (nonatomic, strong) NSString *_headline;
@property (nonatomic) NTDColorScheme _colorScheme;;
@property (nonatomic, strong) NSDate *_lastModifiedDate;

@end

@implementation NTDDeletedNotePlaceholder

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note {
    self._filename = [[note filename] copy];
    self._headline = [[note headline] copy];
    self._bodyText = [[note text] copy];
    self._lastModifiedDate = [note.lastModifiedDate copy];
    self._colorScheme = [[note theme] colorScheme];
    
    return self;
}
- (NSString *)filename {
    return self._filename;
}
- (NSString *)headline {
    return self._headline;
}
- (NSString *)bodyText {
    return self._bodyText;
}
- (NTDTheme *)theme {
    return [NTDTheme themeForColorScheme:self._colorScheme];
}
- (NSDate *)lastModifiedDate {
    return self._lastModifiedDate;
}


@end
