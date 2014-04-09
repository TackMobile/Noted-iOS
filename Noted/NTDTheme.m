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
@property (nonatomic) NSInteger activeThemeIndex;
@end

@implementation NTDTheme
NSString *const NTDActiveThemeIndexKey = @"activeThemeIndex";
NSString *const NTDDidChangeThemeNotification = @"didChangeTheme";

static NSArray *backgroundColors, *caretColors, *themes;

+ (void)initialize
{
    NSArray *defaultBackgroundColors = [[NSArray alloc] initWithObjects:
                                        [UIColor colorWithHexString:@"FFFFFF"],
                                        [UIColor colorWithHexString:@"B5D2E0"],
                                        [UIColor colorWithHexString:@"D1E88C"],
                                        [UIColor colorWithHexString:@"FFF090"],
                                        [UIColor colorWithHexString:@"333333"],
                                        [UIColor colorWithHexString:@"1A9FEB"],
                                        nil];
    
    NSArray *monoBackgroundColors = [[NSArray alloc] initWithObjects:
                                    [UIColor colorWithHexString:@"FFFFFF"],
                                    [UIColor colorWithHexString:@"DDDDDD"],
                                    [UIColor colorWithHexString:@"BBBBBB"],
                                    [UIColor colorWithHexString:@"999999"],
                                    [UIColor colorWithHexString:@"777777"],
                                    [UIColor colorWithHexString:@"666666"],
                                    nil];
    
    NSArray *primaryBackgroundColors = [[NSArray alloc] initWithObjects:
                                     [UIColor colorWithHexString:@"FF0000"],
                                     [UIColor colorWithHexString:@"00FF00"],
                                     [UIColor colorWithHexString:@"0000FF"],
                                     [UIColor colorWithHexString:@"FFFF00"],
                                     [UIColor colorWithHexString:@"00FFFF"],
                                     [UIColor colorWithHexString:@"FF00FF"],
                                     nil];
    
    NSArray *earthyBackgroundColors = [[NSArray alloc] initWithObjects:
                                     [UIColor colorWithHexString:@"800000"],
                                     [UIColor colorWithHexString:@"CC6600"],
                                     [UIColor colorWithHexString:@"663300"],
                                     [UIColor colorWithHexString:@"A38566"],
                                     [UIColor colorWithHexString:@"669900"],
                                     [UIColor colorWithHexString:@"333300"],
                                     nil];

    
    NSArray *defaultCaretColors = [[NSArray alloc] initWithObjects:
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"0088CA"],
                                   [UIColor colorWithHexString:@"7DA700"],
                                   [UIColor colorWithHexString:@"C7AC00"],
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"00639C"],
                                   nil];
    
    NSArray *monoCaretColors = [[NSArray alloc] initWithObjects:
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                nil];
    NSArray *primaryCaretColors = [[NSArray alloc] initWithObjects:
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                nil];
    
    NSArray *earthyCaretColors = [[NSArray alloc] initWithObjects:
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"999999"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                [UIColor colorWithHexString:@"FFFFFF"],
                                nil];
    
    backgroundColors = [[NSArray alloc] initWithObjects:
                        defaultBackgroundColors, monoBackgroundColors, primaryBackgroundColors, earthyBackgroundColors, nil];
    caretColors = [[NSArray alloc] initWithObjects:
                   defaultCaretColors, monoCaretColors, primaryCaretColors, earthyCaretColors, nil];

}

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme
{
    NSParameterAssert(scheme >= 0 && scheme < NTDNumberOfColorSchemes);
    if (!themes) {
        NSMutableArray *tempThemes = [NSMutableArray arrayWithCapacity:NTDNumberOfColorSchemes];
        for (NSInteger i = 0; i < NTDNumberOfColorSchemes; i++) {
            tempThemes[i] = [[NTDTheme alloc] init];
            [tempThemes[i] setColorScheme:i];
        }
        themes = [tempThemes copy];
    }
    return themes[scheme];
}

+ (NTDTheme *)randomTheme
{
    return [self themeForColorScheme:arc4random_uniform(NTDNumberOfColorSchemes)];
}

- (id) init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id) initWithTheme:(NTDThemeName)theme {
    NSParameterAssert(theme >= 0 && theme < NTDNumberOfThemes);
    self = [super init];
    if (self) {
        self.activeThemeIndex = theme;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ThemeChanged" object:nil];
    }
    return self;
}

- (UIColor *)backgroundColor
{
    return backgroundColors[self.activeThemeIndex][self.colorScheme];
}

+ (UIColor *)backgroundColorForThemeName:(NTDThemeName)themeName colorScheme:(NTDColorScheme)colorScheme {
    NSParameterAssert(colorScheme >= 0 && colorScheme < NTDNumberOfColorSchemes);
    NSParameterAssert(themeName >= 0 && themeName < NTDNumberOfThemes);

    return backgroundColors[themeName][colorScheme];
}


- (UIColor *)caretColor
{
    return caretColors[self.activeThemeIndex][self.colorScheme];
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

- (NSString *)themeName
{
    switch (self.colorScheme) {
        case NTDColorSchemeKernal:
            return @"Kernal";
        case NTDColorSchemeLime:
            return @"Lime";
        case NTDColorSchemeShadow:
            return @"Shadow";
        case NTDColorSchemeSky:
            return @"Sky";
        case NTDColorSchemeTack:
            return @"Tack";
        case NTDColorSchemeWhite:
            return @"White";
        default:
            return @"Unknown";
    }
}

+ (int) activeThemeIndex {
    if (![[NSUserDefaults standardUserDefaults] valueForKey:NTDActiveThemeIndexKey]) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:0] forKey:NTDActiveThemeIndexKey];
    }
    int savedThemeIndex = [[[NSUserDefaults standardUserDefaults] valueForKey:NTDActiveThemeIndexKey] intValue];

    return savedThemeIndex;
}

- (int) activeThemeIndex {
    return [NTDTheme activeThemeIndex];
}

+ (void)setThemeToActive:(NTDThemeName)theme {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:theme] forKey:NTDActiveThemeIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:NTDDidChangeThemeNotification object:nil];
}
@end
