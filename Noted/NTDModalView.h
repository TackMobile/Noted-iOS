//
//  NTDModalView.h
//  
//
//  Created by Vladimir Fleurima on 12/18/13.
//
//
typedef NS_ENUM(NSInteger, NTDWalkthroughModalPosition)
{
    NTDWalkthroughModalPositionTop = 0,
    NTDWalkthroughModalPositionCenter,
    NTDWalkthroughModalPositionBottom
};

typedef NS_ENUM(NSInteger, NTDWalkthroughModalType)
{
    NTDWalkthroughModalTypeMessage = 0,
    NTDWalkthroughModalTypeBoolean,
    NTDWalkthroughModalTypeDismiss,
    NTDWalkthroughModalTypeMultipleButtons
};

typedef NS_ENUM(NSInteger, NTDModalBackgroundType)
{
    NTDModalBackgroundTypeNone = 0,
    NTDModalBackgroundTypeClear,
};

typedef void(^NTDWalkthroughPromptHandler)(BOOL userClickedYes);
typedef void(^NTDModalDismissalHandler)(NSUInteger index);

static const NSTimeInterval NTDDefaultInitialModalDelay = 0.75;

@interface NTDModalView : UIView

@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NTDWalkthroughModalPosition position;
@property (nonatomic, assign) NTDWalkthroughModalType type;
@property (nonatomic, copy) NTDWalkthroughPromptHandler promptHandler;

@property (nonatomic, strong) UIView *modalBackground;
@property (nonatomic, readonly) UIFont *modalFont;
@property CGRect superviewFrame;

-(instancetype)initwithMessage:(NSString *)message handler:(NTDWalkthroughPromptHandler)handler;
-(instancetype)initwithMessage:(NSString *)message buttons:(NSArray *)buttonTitles dismissalHandler:(NTDModalDismissalHandler)handler;

-(void)show;
-(void)dismiss;
+ (BOOL)isShowing;
@end
