//
//  NTDNoteMetadata.h
//  Noted
//
//  Created by Vladimir Fleurima on 7/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NTDTheme.h"

@interface NTDNoteMetadata : NSManagedObject

@property (nonatomic, retain) NSString * filename;
@property (nonatomic) NTDColorScheme colorScheme;
@property (nonatomic, retain) NSString * headline;
@property (nonatomic, retain) NSDate *lastModifiedDate;
@property (nonatomic, retain) NSDate *dropboxClientMtime;
@property (nonatomic, retain) NSString * dropboxRev;

@end
