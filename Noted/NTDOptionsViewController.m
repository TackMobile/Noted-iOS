//
//  NTDOptionsViewController.m
//  Noted
//
//  Created by Nick Place on 7/10/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDOptionsViewController.h"
#import "NTDTheme.h"

// view tags
typedef NS_ENUM(NSInteger, NTDColorsSubviewTags) {
    NTDColorsSubviewWhiteTag = 0,
    NTDColorsSubviewSkyTag,
    NTDColorsSubviewLimeTag,
    NTDColorsSubviewKernalTag,
    NTDColorsSubviewShadowTag,
    NTDColorsSubviewTackTag
};

typedef NS_ENUM(NSInteger, NTDOptionsSubviewTags) {
    NTDOptionsSubviewShareTag = 0,
    NTDOptionsSubviewSettingsTag,
    NTDOptionsSubviewAboutTag
};

typedef NS_ENUM(NSInteger, NTDShareOptionsSubviewTags) {
    NTDShareOptionsSubviewEmailTag = 0,
    NTDShareOptionsSubviewMessageTag,
    NTDShareOptionsSubviewTweetTag,
    NTDShareOptionsSubviewFacebookTag
};

typedef NS_ENUM(NSInteger, NTDAboutOptionsSubviewTags) {
    NTDAboutOptionsSubviewVisitTag = 0,
    NTDAboutOptionsSubviewFollowTag
};

@interface NTDOptionsViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *shareTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *aboutTapGestureRecognizer;

@property (nonatomic) CGFloat compressedOptionSubviewHeight;
@property (nonatomic) CGFloat compressedOptionHeight;


@end

const CGFloat CompressedColorHeight = 12.0f;
const CGFloat OptionTopInsetWhenExpanded = 10.0f;

@implementation NTDOptionsViewController
@synthesize colorsSubview;
@synthesize optionsSubview, doneButton, toggleStatusBarButton;
@synthesize shareOptionsView, settingsOptionsView, aboutOptionsView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add subviews and make sure bounds are kept intact
    [self.view addSubview:self.optionsSubview];
    [self.view addSubview:self.colorsSubview];
    
    // set up tap recognizing
        
    self.shareTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(shareTapped:)];
    self.aboutTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(aboutTapped:)];
    
    [self.shareOptionsView addGestureRecognizer:self.shareTapGestureRecognizer];
    [self.aboutOptionsView addGestureRecognizer:self.aboutTapGestureRecognizer];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // layout colors and options
    // options stay a static height, colors are variable
    self.compressedOptionSubviewHeight = self.optionsSubview.frame.size.height;
    self.compressedOptionHeight = [(UIView *)[[self.optionsSubview subviews] objectAtIndex:0] frame].size.height;
    
    CGSize mySize = self.view.bounds.size;
    CGRect colorsFrame = {
        .origin = CGPointZero,
        .size.width = mySize.width,
        .size.height = mySize.height - self.compressedOptionSubviewHeight
    };
    CGRect optionsFrame = {
        .origin.x = 0,
        .origin.y = mySize.height - self.compressedOptionSubviewHeight,
        .size.width = mySize.width,
        .size.height = self.compressedOptionSubviewHeight
    };
    self.colorsSubview.frame = colorsFrame;
    self.optionsSubview.frame = optionsFrame;
    
    self.optionsSubview.clipsToBounds = YES;
    self.colorsSubview.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    // set up inner options
    [[self.optionsSubview subviews] enumerateObjectsUsingBlock:^(UIView *option, NSUInteger idx, BOOL *stop) {
        
        option.clipsToBounds = YES;
        
        UITapGestureRecognizer *optionTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(optionTapped:)];
        [option addGestureRecognizer:optionTapGestureRecognizer];
        
        switch (option.tag) {
            case NTDOptionsSubviewShareTag:
            {
                CGRect shareFrame = self.shareOptionsView.frame;
                shareFrame.origin.y = option.frame.size.height-1;
                
                [option addSubview:self.shareOptionsView];
                self.shareOptionsView.frame = shareFrame;
                
                break;
            }
                
            case NTDOptionsSubviewSettingsTag:
            {
                CGRect settingsFrame = self.settingsOptionsView.frame;
                settingsFrame.origin.y = option.frame.size.height-1;
                
                [option addSubview:self.settingsOptionsView];
                self.shareOptionsView.frame = settingsFrame;
                
                break;
            }
                
            case NTDOptionsSubviewAboutTag:
            {
                CGRect aboutFrame = self.aboutOptionsView.frame;
                aboutFrame.origin.y = option.frame.size.height-1;
                
                [option addSubview:self.aboutOptionsView];
                self.aboutOptionsView.frame = aboutFrame;
                
                break;
            }
                
            default:
                break;
        }
        
    }];
    
    // initialize correct colors
    [[self.colorsSubview subviews] enumerateObjectsUsingBlock:^(UIView *color, NSUInteger idx, BOOL *stop) {
        
       UITapGestureRecognizer *colorTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(colorTapped:)];

        [color addGestureRecognizer:colorTapGestureRecognizer];
        
        color.backgroundColor = [[NTDTheme themeForColorScheme:color.tag] backgroundColor];
        
        color.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
//        switch (color.tag) {
//            case NTDColorsSubviewWhiteTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeWhite] backgroundColor];
//                break;
//            case NTDColorsSubviewSkyTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeSky] backgroundColor];
//                break;
//            case NTDColorsSubviewLimeTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeLime] backgroundColor];
//                break;
//            case NTDColorsSubviewKernalTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeKernal] backgroundColor];
//                break;
//            case NTDColorsSubviewShadowTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeShadow] backgroundColor];
//                break;
//            case NTDColorsSubviewTackTag:
//                color.backgroundColor = [[NTDTheme themeForColorScheme:NTDColorSchemeTack] backgroundColor];
//                break;
//                
//            default:
//                break;
//        }
    }];
}

#pragma mark -  Gesture Recognition

- (void) colorTapped:(UITapGestureRecognizer *)sender
{
    UIColor *noteColor = [[NTDTheme themeForColorScheme:sender.view.tag] backgroundColor];
    [self.delegate setNoteColor:noteColor textColor:nil];
}

- (void) optionTapped:(UITapGestureRecognizer *)sender
{
    // epand the option
    [self expandOptionWithTag:sender.view.tag];
}

#pragma mark - Positioning
- (void) expandOptionWithTag:(NSInteger)tag
{
    // compress colors and expand options
    CGRect colorsFrame = self.colorsSubview.frame;
    colorsFrame.size.height = self.view.frame.size.height;
    
    CGRect optionsFrame = self.optionsSubview.frame;
    optionsFrame.origin.y = CompressedColorHeight - OptionTopInsetWhenExpanded;
    optionsFrame.size.height = self.view.frame.size.height - optionsFrame.origin.y;
    
    colorsSubview.frame = colorsFrame;
    //optionsSubview.frame = optionsFrame;
    
    [[optionsSubview subviews] enumerateObjectsUsingBlock:^(UIView *option, NSUInteger idx, BOOL *stop) {
        CGRect optionFrame = option.frame;
        
        if (option.tag < tag) {
            // shift the option up and out of view. accounting for 1px spacer
            optionFrame = CGRectOffset(optionFrame, 0, (option.tag - tag) * (self.compressedOptionHeight + 1));
        } else if (option.tag == tag) {
            optionFrame.origin.y = 0;
            optionFrame.size.height = optionsFrame.size.height;
        } else {
            optionFrame.origin.y = optionsFrame.size.height + (option.tag - tag - 1) * (self.compressedOptionHeight + 1);
        }
    }];
}

- (void) compressOptions {
    
}

@end
