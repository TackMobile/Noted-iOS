//
//  NTDDummyNote.h
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDNote.h"

@interface NTDDeletedNotePlaceholder : NSObject

@property (nonatomic, strong, readonly) NSString *filename, *headline, *bodyText, *dropboxRev;
@property (nonatomic, strong, readonly) NTDTheme *theme;
@property (nonatomic, strong, readonly) NSDate *lastModifiedDate, *dropboxClientMtime;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSMutableArray *savedColumnsForDeletion; // comes from the shredding category. these columns contain slices that are fully transformed and invisible.
@property (nonatomic, assign) NTDDeletionDirection deletionDirection;

- (NTDDeletedNotePlaceholder *)initWithNote:(NTDNote *)note;

@end
