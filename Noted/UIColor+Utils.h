//
//  UIColor+Utils.h
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//



@interface UIColor (Utils)

+(UIColor*)colorWithHexString:(NSString*)hex;
- (BOOL)isEqualToColor:(UIColor *)otherColor;

@end
