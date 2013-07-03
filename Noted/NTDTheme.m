//
//  NTDTheme.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDTheme.h"
#import "UIColor+Utils.h"

@interface NTDTheme ()
@property (nonatomic, assign) NTDColorScheme colorScheme;
@end

@implementation NTDTheme

static NSArray *backgroundColors;

+(void)initialize
{
    backgroundColors = [[NSArray alloc] initWithObjects:
            [UIColor colorWithHexString:@"FFFFFF"],
            [UIColor colorWithHexString:@"B5D2E0"],
            [UIColor colorWithHexString:@"D1E88C"],
            [UIColor colorWithHexString:@"FFF090"],
            [UIColor colorWithHexString:@"333333"],
            [UIColor colorWithHexString:@"1A9FEB"],
            nil];
}

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme
{
    NSParameterAssert(scheme >= 0 && scheme < NTDNumberOfColorSchemes);
    NTDTheme *theme = [[NTDTheme alloc] init];
    theme.colorScheme = scheme;
    return theme;
}

+ (NTDTheme *)themeForBackgroundColor:(UIColor *)backgroundColor
{
    for (NSInteger i = 0; i < [backgroundColors count]; i++) {
        if ([backgroundColor isEqualToColor:backgroundColors[i]]) {
            return [NTDTheme themeForColorScheme:i];
        }
    }
    return nil;
}

+ (NTDTheme *)randomTheme
{
    return [self themeForColorScheme:arc4random_uniform(NTDNumberOfColorSchemes)];
}

-(UIColor *)backgroundColor
{
    return backgroundColors[self.colorScheme];
}

- (UIColor *)textColor
{
    if ([self isDarkColorScheme])
        return [UIColor whiteColor];
    else
        return [UIColor colorWithHexString:@"333333"];
}

- (UIColor *)subheaderColor
{
    if ([self isDarkColorScheme])
        return [UIColor colorWithWhite:1.0 alpha:0.5];
    else
        return [UIColor colorWithWhite:0.2 alpha:0.5];
}

- (UIColor *)borderColor
{
    return [self textColor];
}

- (UIImage *)optionsButtonImage
{
    if ([self isDarkColorScheme])
        return [UIImage imageNamed:@"menu-icon-white"];
    else
        return [UIImage imageNamed:@"menu-icon-grey"];
}

- (BOOL)isDarkColorScheme
{
    return (NTDColorSchemeTack == self.colorScheme || NTDColorSchemeShadow == self.colorScheme);
}
@end
