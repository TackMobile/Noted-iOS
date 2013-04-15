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
            [UIColor colorWithHexString:@"BCD66A"],
            [UIColor colorWithHexString:@"EFD977"],
            [UIColor colorWithHexString:@"333333"],
            [UIColor colorWithHexString:@"1A9FEB"],
            nil];
}

+ (NTDTheme *)themeForColorScheme:(NTDColorScheme)scheme
{
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

-(UIColor *)backgroundColor
{
    return backgroundColors[self.colorScheme];
}

- (UIColor *)textColor
{
    if (NTDColorSchemeTack == self.colorScheme)
        return [UIColor whiteColor];
    else
        return [UIColor colorWithHexString:@"#333333"];
}

- (UIColor *)headerColor
{
    return [self textColor];
}

- (UIColor *)subheaderColor
{
    if (NTDColorSchemeTack == self.colorScheme)
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
    if (NTDColorSchemeTack == self.colorScheme)
        return [UIImage imageNamed:@"menu-icon-white"];
    else
        return [UIImage imageNamed:@"menu-icon-grey"];
}

@end
