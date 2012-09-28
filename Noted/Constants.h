
static inline BOOL IsEmpty(id thing) {
    return thing == nil
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

// user defaults

#define USE_STANDARD_SYSTEM_KEYBOARD            @"useDefaultKeyboard"
#define HIDE_STATUS_BAR                         @"hideStatusBar"

// notifications
#define SHOULD_CREATE_NOTE                      @"shouldCreateNote"
