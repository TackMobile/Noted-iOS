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

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note;

- (NSString *)filename;
- (NSString *)headline;
- (NSString *)bodyText;
- (NTDTheme *)theme;
- (NSDate *)lastModifiedDate;

@end
