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
static NSString *const NTDDidPurchaseThemesKey = @"DidPurchaseThemes";

static NSArray *backgroundColors, *caretColors, *themes;

static BOOL TESTING_THEMES = YES;

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
    
    NSArray *aBackgroundColors = [[NSArray alloc] initWithObjects:
                                    [UIColor colorWithHexString:@"405C78"],
                                    [UIColor colorWithHexString:@"5C7C9A"],
                                    [UIColor colorWithHexString:@"F5D9A0"],
                                    [UIColor colorWithHexString:@"C7C8C8"],
                                    [UIColor colorWithHexString:@"807E7E"],
                                    [UIColor colorWithHexString:@"FF5F3F"],
                                    nil];
    
    NSArray *bBackgroundColors = [[NSArray alloc] initWithObjects:
                                        [UIColor colorWithHexString:@"EF4B4E"],
                                        [UIColor colorWithHexString:@"FFC926"],
                                        [UIColor colorWithHexString:@"F2E4BF"],
                                        [UIColor colorWithHexString:@"51BFB4"],
                                        [UIColor colorWithHexString:@"AAD9D4"],
                                        [UIColor colorWithHexString:@"AAD9D4"],
                                        nil];
    
    NSArray *cBackgroundColors = [[NSArray alloc] initWithObjects:
                                     [UIColor colorWithHexString:@"1A5D65"],
                                     [UIColor colorWithHexString:@"339966"],
                                     [UIColor colorWithHexString:@"86C486"],
                                     [UIColor colorWithHexString:@"D2DB9A"],
                                     [UIColor colorWithHexString:@"F9D980"],
                                     [UIColor colorWithHexString:@"F9D980"],
                                     nil];
    
    NSArray *dBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithHexString:@"EF6766"],
                                  [UIColor colorWithHexString:@"F28D70"],
                                  [UIColor colorWithHexString:@"F1DF81"],
                                  [UIColor colorWithHexString:@"8CBD9C"],
                                  [UIColor colorWithHexString:@"4B6D8A"],
                                  [UIColor colorWithHexString:@"4B6D8A"],
                                  nil];
    
    NSArray *eBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithHexString:@"F1511F"],
                                  [UIColor colorWithHexString:@"FFA52A"],
                                  [UIColor colorWithHexString:@"FFD92D"],
                                  [UIColor colorWithHexString:@"48B6FF"],
                                  [UIColor colorWithHexString:@"2D85D3"],
                                  [UIColor colorWithHexString:@"2D85D3"],
                                  nil];
    
    NSArray *fBackgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithHexString:@"220F37"],
                                  [UIColor colorWithHexString:@"39214E"],
                                  [UIColor colorWithHexString:@"583279"],
                                  [UIColor colorWithHexString:@"8E378F"],
                                  [UIColor colorWithHexString:@"CC3D81"],
                                  [UIColor colorWithHexString:@"CC3D81"],
                                  nil];

    
    NSArray *defaultCaretColors = [[NSArray alloc] initWithObjects:
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"0088CA"],
                                   [UIColor colorWithHexString:@"7DA700"],
                                   [UIColor colorWithHexString:@"C7AC00"],
                                   [UIColor colorWithHexString:@"999999"],
                                   [UIColor colorWithHexString:@"00639C"],
                                   nil];
    
    backgroundColors = [[NSArray alloc] initWithObjects:
                        defaultBackgroundColors, aBackgroundColors, bBackgroundColors, cBackgroundColors, dBackgroundColors, eBackgroundColors, fBackgroundColors, nil];
    caretColors = [[NSArray alloc] initWithObjects:
                   defaultCaretColors, defaultCaretColors, defaultCaretColors, defaultCaretColors, nil];

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
    return @[@"Noted", @"Turbo", @"Sun Glow", @"Field", @"Ice Cream", @"Candy Crush", @"Violets"];
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
    if (TESTING_THEMES) {
        float white = 0;
        if ([self isDarkColorScheme])
            white = 1;
        
        return [UIColor colorWithWhite:white alpha:.5];
    }
    return caretColors[self.activeThemeIndex][self.colorScheme];
}

- (UIColor *)textColor
{
    if ([self isDarkColorScheme])
        return [UIColor whiteColor];
    else
        return [UIColor colorWithWhite:0 alpha:.8];
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
    if (TESTING_THEMES) {
        CGFloat red, green, blue, alpha;
        [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
        return (red+green+blue)<(3/2);
    }
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

#pragma mark - Purchases

+ (BOOL)didPurchaseThemes {
    if ([[NSUserDefaults standardUserDefaults] valueForKey:NTDDidPurchaseThemesKey]) {
        return [[[NSUserDefaults standardUserDefaults] valueForKey:NTDDidPurchaseThemesKey] boolValue];
    }
    return NO;
}

+ (void)setPurchasedThemes:(BOOL)purchased {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:purchased] forKey:NTDDidPurchaseThemesKey];
}

+ (void)restorePurchases {
    // temporary reset of purchase
    [self setPurchasedThemes:NO];
}
@end
