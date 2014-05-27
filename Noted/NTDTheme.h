//
//  NTDTheme.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const NTDDidChangeThemeNotification;
FOUNDATION_EXPORT NSString *const NTDNoteThemesProductID;

typedef NS_ENUM(int16_t, NTDColorScheme) {
    NTDColorSchemeWhite = 0,
    NTDColorSchemeSky,
    NTDColorSchemeLime,
    NTDColorSchemeKernal,
    NTDColorSchemeShadow,
    NTDColorSchemeTack,
    NTDNumberOfColorSchemes
};

typedef NS_ENUM(int16_t, NTDThemeName) {
    NTDThemeNoted = 0,
    NTDThemeTurbo,
    NTDThemeSunGlow,
    NTDThemeField,
    NTDThemeIceCream,
    NTDThemeCandyCrush,
    NTDThemeViolets,
    NTDNumberOfThemes
};

@interface NTDTheme : NSObject

@property (nonatomic, readonly) UIColor *backgroundColor, *subheaderColor, *textColor;
@property (nonatomic, readonly) UIColor *borderColor, *caretColor;
@property (nonatomic, readonly) UIImage *optionsButtonImage;
@property (nonatomic, assign) NTDColorScheme colorScheme;

+ (void)setThemeToActive:(NTDThemeName)theme;
+ (int) activeThemeIndex;

+ (UIColor *)backgroundColorForThemeName:(NTDThemeName)themeName colorScheme:(NTDColorScheme)colorScheme;

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme;
+ (NTDTheme *)randomTheme;
- (BOOL)isDarkColorScheme;

- (NSString *)themeName;
+ (NSArray *)themeNames;
+ (BOOL)didPurchaseThemes;
+ (void)setPurchasedThemes:(BOOL)purchased;
+ (void)restorePurchases;

@end
