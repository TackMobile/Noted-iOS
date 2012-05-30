//
//  KeyboardKey.h
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeyboardKey : UIView

@property (nonatomic, retain) NSString* label;


- (NSString*) description;
- (KeyboardKey*) initWithLabel:(NSString*)label
                         frame:(CGRect)frame;



@end