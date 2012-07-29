//
//  UIColor+HexColor.h
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//



@interface UIColor (HexColor)
+(UIColor*)colorWithHexString:(NSString*)hex;
+(NSArray*)getNoteColorSchemes;
+(NSArray*)getOptionsColorSchemes;
+(NSArray*)getHeaderColorSchemes;
+(BOOL)isWhiteColor:(UIColor*)color;
+(BOOL)isShadowColor:(UIColor*)color;
- (UIColor *)colorWithBrightness:(CGFloat)brightness;
- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset;

@end
