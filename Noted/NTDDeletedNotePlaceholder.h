//
//  NTDDummyNote.h
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTDNote.h"
#import "NTDNoteMetadata.h"

@interface NTDDeletedNotePlaceholder : NSObject

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSMutableArray *savedColumnsForDeletion; // comes from the shredding category. these columns contain slices that are fully transformed and invisible.

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note;

- (NSString *)filename;
- (NSString *)headline;
- (NSString *)bodyText;
- (NTDTheme *)theme;
- (NSDate *)lastModifiedDate;

@end
