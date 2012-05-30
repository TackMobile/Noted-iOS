//
//  KeyboardKey.m
//  Noted
//
//  Created by James Bartolotta on 5/25/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "KeyboardKey.h"

@implementation KeyboardKey
@synthesize label;



- (NSString*) description {
	return [NSString stringWithFormat:@"%@", self.label];
}

- (KeyboardKey*) initWithLabel:(NSString *)_label frame:(CGRect)frame {
	
    self = [super initWithFrame:frame];
    self.label = _label;
    return self;
}

@end