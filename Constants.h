typedef void(^NTDVoidBlock)();

static const CGFloat NTDPullToCreateShowCardOffset = 30.0;
static const CGFloat NTDPullToCreateScrollCardOffset = 50.0;

static NSString * const NTDStandardFontName = @"Avenir";
static NSString * const NTDLightFontName = @"Avenir-Light";

#pragma mark - Starter Quotes -

static NSString * const NTDJohnMaedaQuote = @"“The best art makes your head spin with questions. Perhaps this is the fundamental distinction between pure art and pure design. While great art makes you wonder, great design makes things clear.” ― John Maeda";
static NSString * const NTDAlbertEinsteinQuote = @"“I am not a genius, I am just curious. I ask many questions. And when the answer is simple, then God is answering.” ― Albert Einstein";
static NSString * const NTDBruceLeeQuote = @"“It is not a daily increase, but a daily decrease. Hack away at the inessentials.” ― Bruce Lee";
static NSString * const NTDSteveJobsQuote = @"“That’s been one of my mantras – focus and simplicity. Simple can be harder than complex. You have to work hard to get your thinking clean to make it simple. But it’s worth it in the end because once you get there, you can move mountains.” ― Steve Jobs";
static NSString * const NTDEdwardTufteQuote = @"“Good design is a lot like clear thinking made visual.” ― Edward Tufte";
static NSString * const NTDIsaacNewtonQuote = @"“Truth is ever to be found in the simplicity, and not in the multiplicity and confusion of things.” ― Isaac Newton";

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

#pragma mark - NSNotification Names -

static NSString *const NTDDidChangeThemeNotification = @"DidChangeThemeNotification";
static NSString *const NTDWillBeginWalkthroughNotification = @"NTDUserWillBeginWalkthroughNotification";
static NSString *const NTDDidEndWalkthroughNotification = @"NTDUserDidCompleteWalkthroughNotification";
static NSString *const NTDDidCompleteWalkthroughUserInfoKey = @"NTDDidCompleteWalkthroughKey";
static NSString *const NTDDidAdvanceWalkthroughToStepNotification = @"NTDDidAdvanceWalkthroughToStepNotification";
static NSString *const NTDWillEndWalkthroughStepNotification = @"NTDWillEndWalkthroughStepNotification";
