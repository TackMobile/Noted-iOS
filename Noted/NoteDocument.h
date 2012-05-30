//
//  NoteDocument.h
//  Noted
//
//  Created by James Bartolotta on 5/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteData;

#define NOTE_EXTENSION @"ntd"

@interface NoteDocument : UIDocument

-(NSString*)description;
-(NSString*)text;
-(UIColor*)color;
-(NSString*)location;
-(void)setText:(NSString*)text;
-(void)setColor:(UIColor*)color;
-(void)setLocation:(NSString*)location;

@end
