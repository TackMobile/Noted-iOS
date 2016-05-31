typedef void(^NTDVoidBlock)();

static const CGFloat NTDPullToCreateShowCardOffset = 30.0;
static const CGFloat NTDPullToCreateScrollCardOffset = 50.0;

static NSString * const NTDStandardFontName = @"Avenir";
static NSString * const NTDLightFontName = @"Avenir-Light";

UIColor *ModalBackgroundColor;

typedef NS_ENUM(NSInteger, NTDDeletionDirection) {
    NTDDeletionDirectionNoDirection = 0,
    NTDDeletionDirectionLeft,
    NTDDeletionDirectionRight
};

// user defaults
#define HIDE_STATUS_BAR                         @"hideStatusBar"

// helpers
#define CLAMP(x, a, b) MIN(b, MAX(a,x))
