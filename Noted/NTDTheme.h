//
//  NTDTheme.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/15/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NTDColorScheme) {
    NTDColorSchemeWhite = 0,
    NTDColorSchemeLime,
    NTDColorSchemeSky,
    NTDColorSchemeKernal,
    NTDColorSchemeShadow,
    NTDColorSchemeTack,
    NTDNumberOfColorSchemes
};

@interface NTDTheme : NSObject

@property (nonatomic, readonly) UIColor *backgroundColor, *headerColor, *subheaderColor, *textColor, *borderColor;
@property (nonatomic, readonly) UIImage *optionsButtonImage;

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme;
+ (NTDTheme *)themeForBackgroundColor:(UIColor *)backgroundColor; /* Backwards compatibility */
@end
