//
//  NoteData.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NoteData : NSObject <NSCoding>

@property (strong) UIColor *noteColor;
@property (strong) NSString *noteText;
@property (strong) NSString *noteLocation;

@end
