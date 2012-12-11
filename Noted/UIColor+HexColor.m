//
//  UIColor+HexColor.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "UIColor+HexColor.h"

@implementation UIColor (HexColor)

+(NSArray*)getNoteColorSchemes {
    //colorSchemes: white,lime,sky,kernal,shadow,tack
   return [[NSArray alloc] initWithObjects:
           [UIColor colorWithHexString:@"FFFFFF"],
           [UIColor colorWithHexString:@"B5D2E0"],
           [UIColor colorWithHexString:@"BCD66A"],
           [UIColor colorWithHexString:@"EFD977"],
           [UIColor colorWithHexString:@"333333"],
           [UIColor colorWithHexString:@"1A9FEB"],
           nil];
}

+(NSArray*)getOptionsColorSchemes {
    return [[NSArray alloc] initWithObjects:
            [UIColor colorWithHexString:@"FFFFFF"],
            [UIColor colorWithHexString:@"B5D2E0"],
            [UIColor colorWithHexString:@"BCD66A"],
            [UIColor colorWithHexString:@"EFD977"],
            [UIColor colorWithHexString:@"333333"],
            [UIColor colorWithHexString:@"1A9FEB"],
            nil];
}

+(NSArray*)getHeaderColorSchemes {
    return [[NSArray alloc] initWithObjects:
            [UIColor colorWithHexString:@"AAAAAA"],
            [UIColor colorWithHexString:@"88ACBB"],
            [UIColor colorWithHexString:@"C1D184"],
            [UIColor colorWithHexString:@"DAC361"],
            [UIColor colorWithHexString:@"CCCCCC"],
            [UIColor colorWithHexString:@"FFFFFF"],
            nil];
}

+(BOOL)isWhiteColor:(UIColor *)color {
    UIColor* white = [[self getNoteColorSchemes] objectAtIndex:0];
    if (CGColorEqualToColor(white.CGColor, color.CGColor)) {
        return YES;
    }
    return NO;
}

+(BOOL)isShadowColor:(UIColor *)color {
    UIColor* shadow = [[self getNoteColorSchemes] objectAtIndex:4];
    if (CGColorEqualToColor(shadow.CGColor, color.CGColor)) {
        return YES;
    }
    return NO;
}

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

- (UIColor *)colorWithBrightness:(CGFloat)brightnessComponent {
    
    UIColor *newColor = nil;
    if ( ! newColor) {
        CGFloat hue, saturation, brightness, alpha;
        if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            newColor = [UIColor colorWithHue:hue
                                  saturation:saturation
                                  brightness:brightness * brightnessComponent
                                       alpha:alpha];
        }
    }
    
    if ( ! newColor) {
        CGFloat red, green, blue, alpha;
        if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
            newColor = [UIColor colorWithRed:red*brightnessComponent
                                       green:green*brightnessComponent
                                        blue:blue*brightnessComponent
                                       alpha:alpha];
        }
    }
    
    if ( ! newColor) {
        CGFloat white, alpha;
        if ([self getWhite:&white alpha:&alpha]) {
            newColor = [UIColor colorWithWhite:white * brightnessComponent alpha:alpha];
        }
    }
    
    return newColor;
}

- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset {
    UIColor *newColor = nil;
    if ( ! newColor) {
        CGFloat hue, saturation, brightness, alpha;
        if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            // We wants the hue value to be between 0 - 1 after appending the offset
            CGFloat newHue = fmodf((hue + hueOffset), 1);
            newColor = [UIColor colorWithHue:newHue
                                  saturation:saturation
                                  brightness:brightness
                                       alpha:alpha];
        }
    }
    return newColor;
}

+ (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

@end
