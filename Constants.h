typedef void(^NTDVoidBlock)();

static const CGFloat NTDPullToCreateShowCardOffset = 30.0;
static const CGFloat NTDPullToCreateScrollCardOffset = 50.0;

UIColor *ModalBackgroundColor;

// user defaults
#define HIDE_STATUS_BAR                         @"hideStatusBar"
#define kFirstUse                               @"firstUse"

// System Versioning Preprocessor Macros
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// helpers
#define CLAMP(x, a, b) MIN(b, MAX(a,x))
