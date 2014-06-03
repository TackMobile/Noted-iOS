//
//  NTDTheme.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDTheme.h"
#import "UIColor+Utils.h"
#import <IAPHelper/IAPShare.h>

@interface NTDTheme ()
@property (nonatomic) NSInteger activeThemeIndex;
@end

@implementation NTDTheme
NSString *const NTDActiveThemeIndexKey = @"activeThemeIndex";
NSString *const NTDDidChangeThemeNotification = @"DidChangeThemeNotification";
NSString *const NTDNoteThemesProductID = @"com.tackmobile.noted.themes";

static NSArray *backgroundColors, *textColors, *caretColors, *themes;

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
    
    NSArray *defaultTextColors = [[NSArray alloc] initWithObjects:
                                  [UIColor blackColor],
                                  [UIColor blackColor],
                                  [UIColor blackColor],
                                  [UIColor blackColor],
                                  [UIColor whiteColor],
                                  [UIColor whiteColor], nil];
    
    NSArray *defaultCaretColors = [[NSArray alloc] initWithObjects:
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"0088CA"],
                                   [UIColor colorWithHexString:@"7DA700"],
                                   [UIColor colorWithHexString:@"C7AC00"],
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"00639C"],
                                   nil];
    // setting sun
    NSArray *aBackgroundColors = [[NSArray alloc] initWithObjects:
                                    [UIColor colorWithRed:0.96 green:0.85 blue:0.64 alpha:1],
                                    [UIColor colorWithRed:0.94 green:0.62 blue:0.55 alpha:1],
                                    [UIColor colorWithRed:0.85 green:0.28 blue:0.42 alpha:1],
                                    [UIColor colorWithRed:0.54 green:0.27 blue:0.49 alpha:1],
                                    [UIColor colorWithRed:0.36 green:0.18 blue:0.44 alpha:1],
                                    [UIColor colorWithRed:0.24 green:0.23 blue:0.56 alpha:1],
                                    nil];
    NSArray *aTextColors = [[NSArray alloc] initWithObjects:
                                [UIColor blackColor],
                                [UIColor blackColor],
                                [UIColor whiteColor],
                                [UIColor whiteColor],
                                [UIColor whiteColor],
                                [UIColor whiteColor],
                                nil];
    NSArray *aCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.91 green:0.59 blue:0 alpha:1],
                              [UIColor colorWithRed:0.89 green:0.34 blue:0.19 alpha:1],
                              [UIColor colorWithRed:0.64 green:0 blue:0.16 alpha:1],
                              [UIColor colorWithRed:0.36 green:0.11 blue:0.31 alpha:1],
                              [UIColor colorWithRed:0.55 green:0.31 blue:0.64 alpha:1],
                              [UIColor colorWithRed:0.44 green:0.4 blue:0.78 alpha:1], nil];
    
    // turbo charge
    NSArray *bBackgroundColors = [[NSArray alloc] initWithObjects:
                                        [UIColor colorWithRed:0.25 green:0.36 blue:0.47 alpha:1],
                                        [UIColor colorWithRed:0.36 green:0.49 blue:0.6 alpha:1],
                                        [UIColor colorWithRed:1 green:0.99 blue:1 alpha:1],
                                        [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1],
                                        [UIColor colorWithRed:0.5 green:0.49 blue:0.49 alpha:1],
                                        [UIColor colorWithRed:1 green:0.37 blue:0.25 alpha:1],
                                        nil];
    NSArray *bTextColors = [[NSArray alloc] initWithObjects:
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            nil];
    NSArray *bCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.39 green:0.56 blue:0.74 alpha:1],
                              [UIColor colorWithRed:0.45 green:0.62 blue:0.77 alpha:1],
                              [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1],
                              [UIColor colorWithRed:0.55 green:0.58 blue:0.58 alpha:1],
                             [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1],
                              [UIColor colorWithRed:0.76 green:0.16 blue:0.04 alpha:1],
                              nil];

    // candy coat
    NSArray *cBackgroundColors = [[NSArray alloc] initWithObjects:
                                     [UIColor colorWithRed:0.93 green:0.32 blue:0.17 alpha:1],
                                     [UIColor colorWithRed:0.99 green:0.64 blue:0.23 alpha:1],
                                     [UIColor colorWithRed:1 green:0.85 blue:0.26 alpha:1],
                                     [UIColor colorWithRed:0.18 green:0.7 blue:0 alpha:1],
                                     [UIColor colorWithRed:0.31 green:0.72 blue:0.99 alpha:1],
                                     [UIColor colorWithRed:0.2 green:0.53 blue:0.82 alpha:1],
                                     nil];
    NSArray *cTextColors = [[NSArray alloc] initWithObjects:
                            [UIColor whiteColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            nil];
    
    NSArray *cCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.76 green:0.16 blue:0.04 alpha:1],
                              [UIColor colorWithRed:0.82 green:0.44 blue:0 alpha:1],
                              [UIColor colorWithRed:0.82 green:0.65 blue:0 alpha:1],
                             [UIColor colorWithRed:0.11 green:0.45 blue:0 alpha:1],
                              [UIColor colorWithRed:0 green:0.51 blue:0.84 alpha:1],
                             [UIColor colorWithRed:0.04 green:0.31 blue:0.55 alpha:1],
                              nil];

    // open field
    NSArray *dBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithRed:0.13 green:0.36 blue:0.39 alpha:1],
                                  [UIColor colorWithRed:0.26 green:0.55 blue:0.47 alpha:1],
                                  [UIColor colorWithRed:0.54 green:0.76 blue:0.54 alpha:1],
                                  [UIColor colorWithRed:0.82 green:0.85 blue:0.63 alpha:1],
                                  [UIColor colorWithRed:0.97 green:0.84 blue:0.55 alpha:1],
                                  [UIColor colorWithRed:0.96 green:0.72 blue:0.43 alpha:1],
                                  nil];
    NSArray *dTextColors = [[NSArray alloc] initWithObjects:
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            nil];
    NSArray *dCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.16 green:0.54 blue:0.58 alpha:1],
                              [UIColor colorWithRed:0.31 green:0.71 blue:0.6 alpha:1],
                              [UIColor colorWithRed:0.26 green:0.58 blue:0.26 alpha:1],
                             [UIColor colorWithRed:0.57 green:0.62 blue:0.22 alpha:1],
                              [UIColor colorWithRed:0.79 green:0.58 blue:0.04 alpha:1],
                             [UIColor colorWithRed:0.84 green:0.5 blue:0.05 alpha:1],
                              nil];

    // coral punch
    NSArray *eBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithRed:0.93 green:0.3 blue:0.32 alpha:1],
                                  [UIColor colorWithRed:1 green:0.78 blue:0.24 alpha:1],
                                  [UIColor colorWithRed:0.95 green:0.89 blue:0.76 alpha:1],
                                  [UIColor colorWithRed:0.34 green:0.75 blue:0.71 alpha:1],
                                  [UIColor colorWithRed:0.67 green:0.85 blue:0.83 alpha:1],
                                  [UIColor colorWithRed:1 green:1 blue:1 alpha:1],
                                  nil];
    NSArray *eTextColors = [[NSArray alloc] initWithObjects:
                            [UIColor whiteColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            [UIColor whiteColor],
                            [UIColor blackColor],
                            [UIColor blackColor],
                            nil];
    
    NSArray *eCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.78 green:0.05 blue:0.07 alpha:1],
                              [UIColor colorWithRed:0.78 green:0.58 blue:0 alpha:1],
                              [UIColor colorWithRed:0.83 green:0.67 blue:0.27 alpha:1],
                              [UIColor colorWithRed:0.16 green:0.56 blue:0.52 alpha:1],
                             [UIColor colorWithRed:0.29 green:0.69 blue:0.65 alpha:1],
                             [UIColor colorWithRed:0.73 green:0.73 blue:0.73 alpha:1],
                              nil];

    // violet grove
    NSArray *fBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithRed:0.13 green:0.07 blue:0.21 alpha:1],
                                  [UIColor colorWithRed:0.22 green:0.13 blue:0.3 alpha:1],
                                  [UIColor colorWithRed:0.34 green:0.2 blue:0.47 alpha:1],
                                  [UIColor colorWithRed:0.55 green:0.23 blue:0.55 alpha:1],
                                  [UIColor colorWithRed:0.79 green:0.25 blue:0.51 alpha:1],
                                  [UIColor colorWithRed:0.54 green:0.09 blue:0.3 alpha:1],
                                  nil];
    NSArray *fTextColors = [[NSArray alloc] initWithObjects:
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            [UIColor whiteColor],
                            nil];
    NSArray *fCaretColors = [[NSArray alloc] initWithObjects:
                              [UIColor colorWithRed:0.45 green:0.17 blue:0.76 alpha:1],
                              [UIColor colorWithRed:0.44 green:0.22 blue:0.64 alpha:1],
                              [UIColor colorWithRed:0.54 green:0.29 blue:0.76 alpha:1],
                             [UIColor colorWithRed:0.79 green:0.33 blue:0.79 alpha:1],
                              [UIColor colorWithRed:0.62 green:0.13 blue:0.36 alpha:1],
                             [UIColor colorWithRed:0.79 green:0.09 blue:0.43 alpha:1],
                            nil];


    backgroundColors = [[NSArray alloc] initWithObjects:
                        defaultBackgroundColors, aBackgroundColors, bBackgroundColors, cBackgroundColors, dBackgroundColors, eBackgroundColors, fBackgroundColors, nil];
    caretColors = [[NSArray alloc] initWithObjects:
                    defaultCaretColors, aCaretColors, bCaretColors, cCaretColors, dCaretColors, eCaretColors, fCaretColors, nil];
    textColors = [[NSArray alloc] initWithObjects:defaultTextColors, aTextColors, bTextColors, cTextColors, dTextColors, eTextColors, fTextColors, nil];

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

+ (NSArray *)themeNames {
    return @[@"Noted", @"Setting Sun", @"Turbo Charge", @"Candy Coat", @"Open Field", @"Coral Punch", @"Violet Grove"];
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
    return textColors[self.activeThemeIndex][self.colorScheme];
}

- (UIColor *)subheaderColor
{
    if ([self isDarkColorScheme])
        return [UIColor colorWithWhite:1.0 alpha:0.6];
    else
        return [UIColor colorWithWhite:0 alpha:0.5];
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
    return textColors[self.activeThemeIndex][self.colorScheme] == [UIColor whiteColor];
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

#pragma mark - Purchases

+ (BOOL)didPurchaseThemes {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:NTDNoteThemesProductID] boolValue];
}

+ (void)setPurchasedThemes:(BOOL)purchased {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:purchased] forKey:NTDNoteThemesProductID];
}

+ (void)restorePurchases {
    // temporary reset of purchase
    [self setPurchasedThemes:NO];
    
}
@end
