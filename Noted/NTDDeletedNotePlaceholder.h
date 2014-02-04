//
//  NTDDummyNote.h
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTDNote.h"

@interface NTDDeletedNotePlaceholder : NSObject

@property (nonatomic, strong, readonly) NSString *filename, *headline, *bodyText;
@property (nonatomic, strong, readonly) NTDTheme *theme;
@property (nonatomic, strong, readonly) NSDate *lastModifiedDate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSMutableArray *savedColumnsForDeletion; // comes from the shredding category. these columns contain slices that are fully transformed and invisible.

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note;

@end