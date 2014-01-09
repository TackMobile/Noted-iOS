//
//  NTDDummyNote.h
//  Noted
//
//  Created by Nick Place on 1/12/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTDNote.h"

@interface NTDDummyNote : NSObject

- (NTDDummyNote *)initWithNote:(NTDNote *)note;

- (NSString *)filename;
- (NSDate *)lastModifiedDate;
- (NTDTheme *)theme;
- (NSString *)text;

@end
