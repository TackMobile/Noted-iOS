//
//  NTDTheme.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int16_t, NTDColorScheme) {
    NTDColorSchemeWhite = 0,
    NTDColorSchemeSky,
    NTDColorSchemeLime,
    NTDColorSchemeKernal,
    NTDColorSchemeShadow,
    NTDColorSchemeTack,
    NTDNumberOfColorSchemes
};

@interface NTDTheme : NSObject

@property (nonatomic, readonly) UIColor *backgroundColor, *subheaderColor, *textColor;
@property (nonatomic, readonly) UIColor *borderColor, *caretColor;
@property (nonatomic, readonly) UIImage *optionsButtonImage;
@property (nonatomic, assign) NTDColorScheme colorScheme;

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme;
+ (NTDTheme *)randomTheme;
- (BOOL)isDarkColorScheme;
- (NSString *)themeName;
@end
