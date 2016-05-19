typedef void(^NTDVoidBlock)();

static const CGFloat NTDPullToCreateShowCardOffset = 30.0;
static const CGFloat NTDPullToCreateScrollCardOffset = 50.0;

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

// idioms
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_TALL_IPHONE (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height > 567.0f)
