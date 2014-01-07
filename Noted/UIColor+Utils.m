//
//  UIColor+HexColor.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "UIColor+Utils.h"

@implementation UIColor (Utils)

+(UIColor*) colorWithHexString:(NSString *) hex  
{  
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];  
    
    // String should be 6 or 8 characters  
    if ([cString length] < 6) return [UIColor grayColor];  
    
    // strip 0X if it appears  
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];  
    
    if ([cString length] != 6) return  [UIColor grayColor];  
    
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2;  
    NSString *rString = [cString substringWithRange:range];  
    
    range.location = 2;  
    NSString *gString = [cString substringWithRange:range];  
    
    range.location = 4;  
    NSString *bString = [cString substringWithRange:range];  
    
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  
    
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
} 

- (BOOL)isEqualToColor:(UIColor *)otherColor {
    if (self == otherColor)
        return YES;
    
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color)
    {
        if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome)
        {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            CGColorRef colorRef = CGColorCreate(colorSpaceRGB, components);
            UIColor *color = [UIColor colorWithCGColor:colorRef];
            CGColorRelease(colorRef);
            return color;
        }
        else
            return color;
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}

@end
