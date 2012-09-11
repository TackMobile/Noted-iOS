//  EZToastView.m
//  © Lucid Vapor LLC 2012
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
//  PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL 
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  This source code is not to be distributed to any parties other than the purchasing
//  license holder(s).  Contact control.support@lucidvapor.com for any support 

#import "EZToastView.h"

#define DEFAULT_SHOW_DURATION 0.4f
#define DEFAULT_ALPHA_ANIMATION_DURATION 0.5f
#define DEFAULT_TOAST_VERITCAL_PADDING 5.0f
#define DEFAULT_TOAST_HORIZONTAL_PADDING 5.0f
#define DEFAULT_ALIGNMENT_MARGIN 50.0f
#define DEFAULT_MAXIMUM_WIDTH 290.0f
#define DEFAULT_TOAST_ALIGNMENT EZToastViewAlignmentBottom


/***************** Appearance Proxy Object *******************/


@interface AppearanceProxyObject : NSObject <EZToastViewAppearanceDefaults>
@property (nonatomic, assign) NSTimeInterval fadeDuration;
@property (nonatomic, assign) NSTimeInterval showDuration;
@property (nonatomic, assign) CGFloat maximumWidth;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic, assign) EZToastViewAlignment toastAlignment;
@property (nonatomic, assign) CGFloat toastAlignmentMargin;
@property (nonatomic, retain) UIFont *messageFont;
@property (nonatomic, retain) UIColor *messageColor;
@property (nonatomic, retain) UIColor *toastBackgroundColor;
@property (nonatomic, assign) UITextAlignment messageAlignment;
-(id)initWithDefaults;
-(void)setDefaults;
@end

@implementation AppearanceProxyObject
@synthesize toastAlignmentMargin,borderWidth,borderColor,
fadeDuration,maximumWidth,toastBackgroundColor,messageColor,
messageFont,showDuration,toastAlignment,messageAlignment;

-(id)initWithDefaults
{
	self = [super init];
    [self setDefaults];
	return self;
}


-(void)setDefaults
{
	self.fadeDuration = DEFAULT_ALPHA_ANIMATION_DURATION;
	self.showDuration = DEFAULT_SHOW_DURATION;
	self.toastAlignment = DEFAULT_TOAST_ALIGNMENT;
	self.toastAlignmentMargin = DEFAULT_ALIGNMENT_MARGIN;
	self.maximumWidth = DEFAULT_MAXIMUM_WIDTH;
	self.borderWidth = 2.0f;
	self.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
	self.toastBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
	self.messageColor = [UIColor whiteColor];
	self.messageFont = [UIFont systemFontOfSize:15.0f];
	self.messageAlignment = UITextAlignmentCenter;
}

-(void)dealloc
{
	[borderColor release];
	[toastBackgroundColor release];
	[messageColor release];
	[messageFont release];
	[super dealloc];
}

@end



/***************** EZToastView *******************/


@interface EZToastView ()

@property (nonatomic, retain) UIView *parentView;

+(NSMutableArray *)toastViews;

-(void)setupProperties;
-(void)fadeToastOut:(EZToastView *)toastView;
-(void)fadeToastIn:(EZToastView *)toastView;
+(void)addToastView:(EZToastView *)toastView;
+(void)removeToastView;
+(void)showNextToastIfAvailable;
-(void)readjustSize;
-(void)transformToastInWindow;
-(void)adjustToastFrame:(CGSize)containerSize;
@end

@implementation EZToastView

@synthesize toastAlignmentMargin = _toastAlignmentMargin;
@synthesize borderWidth = _borderWidth;
@synthesize borderColor = _borderColor;
@synthesize fadeDuration = _fadeDuration;
@synthesize maximumWidth = _maximumWidth;
@synthesize message = _message;
@synthesize toastBackgroundColor = _toastBackgroundColor;
@synthesize messageColor = _messageColor;
@synthesize messageFont = _messageFont;
@synthesize parentView = _parentView;
@synthesize showDuration = _showDuration;
@synthesize toastAlignment = _toastAlignment;
@synthesize messageAlignment = _messageAlignment;


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupProperties];
    }
    return self;
}

-(id)init
{
	return [self initWithFrame:CGRectZero];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	return [self initWithFrame:CGRectZero];
}


-(void)setupProperties
{
	id<EZToastViewAppearanceDefaults>defaults = [EZToastView appearanceDefaults];
	AppearanceProxyObject *defaultToastView = (AppearanceProxyObject *)defaults;
	
	self.backgroundColor = [UIColor clearColor];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	
	self.fadeDuration = defaultToastView.fadeDuration;
	self.showDuration = defaultToastView.showDuration;
	self.toastAlignment = defaultToastView.toastAlignment;
	self.toastAlignmentMargin = defaultToastView.toastAlignmentMargin;
	self.maximumWidth = defaultToastView.maximumWidth;
	self.borderWidth = defaultToastView.borderWidth;
	self.borderColor = defaultToastView.borderColor;
	self.toastBackgroundColor = defaultToastView.toastBackgroundColor;
	self.messageColor = defaultToastView.messageColor;
	self.messageFont = defaultToastView.messageFont;
	self.messageAlignment = defaultToastView.messageAlignment;
	
	self.parentView = nil;
	self.message = @"";
}



#pragma mark - Frame appearance

-(void)setMessage:(NSString *)message
{
	if (message != _message) 
	{
		[_message release];
		[self willChangeValueForKey:@"message"];
		_message = [message retain];
		[self didChangeValueForKey:@"message"];
	}
	[self readjustSize];
}

-(void)setBorderWidth:(CGFloat)borderWidth
{
	if (borderWidth != _borderWidth) 
	{
		[self willChangeValueForKey:@"borderWidth"];
		_borderWidth = borderWidth;
		[self didChangeValueForKey:@"borderWidth"];
	}
	[self readjustSize];
}

-(void)setMessageFont:(UIFont *)messageFont
{
	if (messageFont != _messageFont) 
	{
		[_messageFont release];
		[self willChangeValueForKey:@"messageFont"];
		_messageFont = [messageFont retain];
		[self didChangeValueForKey:@"messageFont"];
	}
	[self readjustSize];
}

-(void)setMaximumWidth:(CGFloat)maximumWidth
{
	if (maximumWidth != _maximumWidth) 
	{
		[self willChangeValueForKey:@"maximumWidth"];
		_maximumWidth = maximumWidth;
		[self didChangeValueForKey:@"maximumWidth"];
	}
	[self readjustSize];
}

-(void)readjustSize
{
	CGFloat lineWidth = self.borderWidth;
	CGFloat totalSidePadding = DEFAULT_TOAST_HORIZONTAL_PADDING * 2  + lineWidth * 2;
	CGSize maxTextSize = CGSizeMake(self.maximumWidth - totalSidePadding, MAXFLOAT);
	CGSize textSize = [self.message sizeWithFont:self.messageFont constrainedToSize:maxTextSize lineBreakMode:UILineBreakModeWordWrap];
	
	CGRect frame = self.frame;
	frame.size.width = textSize.width + totalSidePadding;
	frame.size.height = textSize.height + DEFAULT_TOAST_VERITCAL_PADDING * 2  + lineWidth * 2;
	self.frame = frame;
}

-(void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGFloat lineWidth = self.borderWidth;
	
	CGRect backgroundFrame = self.bounds;
	CGRect insetBackgroundRect = CGRectInset(backgroundFrame, lineWidth/2.0, lineWidth/2.0);
	UIBezierPath *roundedBackgroundPath = [UIBezierPath bezierPathWithRoundedRect:insetBackgroundRect cornerRadius:5.0];
	CGContextSaveGState(ctx);
	
	[self.toastBackgroundColor setFill];
	[roundedBackgroundPath fill];
	
	
	
	CGRect insetBorderRect = CGRectInset(backgroundFrame, lineWidth/2.0, lineWidth/2.0);
	UIBezierPath *roundedBorderPath = [UIBezierPath bezierPathWithRoundedRect:insetBorderRect cornerRadius:5.0];
	[self.borderColor setStroke];
	roundedBorderPath.lineWidth = lineWidth;
	[roundedBorderPath stroke];
	
	[self.messageColor set];
	CGRect messageInsectRect = CGRectInset(backgroundFrame, DEFAULT_TOAST_HORIZONTAL_PADDING + lineWidth, DEFAULT_TOAST_VERITCAL_PADDING + lineWidth);
	[self.message drawInRect:messageInsectRect withFont:self.messageFont lineBreakMode:UILineBreakModeWordWrap alignment:self.messageAlignment];
	
	CGContextRestoreGState(ctx);
}



#pragma mark - Showing

+(void)showToastMessage:(NSString *)message
{
	AppearanceProxyObject *defaults = (AppearanceProxyObject *)[EZToastView appearanceDefaults];
    
	[EZToastView showToastMessage:message withAlignment:defaults.toastAlignment];
}

+(void)showToastMessage:(NSString *)message withDelay:(NSTimeInterval)delay andDuration:(NSTimeInterval)duration
{
    AppearanceProxyObject *defaults = (AppearanceProxyObject *)[EZToastView appearanceDefaults];
    [defaults setShowDuration:duration];
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [EZToastView showToastMessage:message withAlignment:defaults.toastAlignment];
    });
}

+(void)showToastMessage:(NSString *)message withAlignment:(EZToastViewAlignment)alignment
{
	AppearanceProxyObject *defaults = (AppearanceProxyObject *)[EZToastView appearanceDefaults];
	[EZToastView showToastMessage:message withAlignment:alignment alignmentMargin:defaults.toastAlignmentMargin];
}

+(void)showToastMessage:(NSString *)message withAlignment:(EZToastViewAlignment)alignment alignmentMargin:(CGFloat)margin
{
	EZToastView *toastView = [[EZToastView alloc] init];
	toastView.toastAlignment = alignment;
	toastView.toastAlignmentMargin = margin;
	toastView.message = message;
	[toastView show];
	[toastView release];
}

+(void)showToastMessage:(NSString *)message withPropertyValues:(NSDictionary *)keysAndValues
{
	EZToastView *toastView = [[EZToastView alloc] init];
	toastView.message = message;
	NSArray *keys = keysAndValues.allKeys;
	for (int i = 0; i < [keysAndValues count]; i++) 
	{
		id key = [keys objectAtIndex:i];
		[toastView setValue:[keysAndValues valueForKey:key] forKey:key];
	}
	[toastView show];
	[toastView release];
}

-(void)show
{
	[EZToastView addToastView:self];
}


-(void)showInView:(UIView *)view
{
	self.parentView = view;
	[self show];
}


+(NSMutableArray *)toastViews
{
	static NSMutableArray *_toastViews = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _toastViews = [[NSMutableArray alloc] init];
    });
    
    return _toastViews;
}



+(void)resetAppearanceDefaults
{
	AppearanceProxyObject *appearanceProxy = (AppearanceProxyObject *)[EZToastView appearanceDefaults];
	[appearanceProxy setDefaults];
}




+(id<EZToastViewAppearanceDefaults>)appearanceDefaults
{
	static AppearanceProxyObject *_appearanceDefaults = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _appearanceDefaults = [[AppearanceProxyObject alloc] initWithDefaults];
    });
    
    return _appearanceDefaults;
}


#pragma mark - Sequencing the showing and animating effects

+(void)addToastView:(EZToastView *)toastView
{
	NSMutableArray *toastViews = [EZToastView toastViews];
	[toastViews addObject:toastView];
	if ([toastViews count] == 1) 
	{
		[EZToastView showNextToastIfAvailable];
	}
}


+(void)showNextToastIfAvailable
{
	NSMutableArray *toastViews = [EZToastView toastViews];
	if ([toastViews count] > 0) 
	{
		EZToastView *toastView = [toastViews objectAtIndex:0];
		[toastView fadeToastIn:toastView];
		
		[NSTimer scheduledTimerWithTimeInterval:toastView.showDuration + toastView.fadeDuration
										 target:toastView 
									   selector:@selector(showToastTimeExpired:) 
									   userInfo:nil
										repeats:NO];
	}
}

-(void)fadeToastIn:(EZToastView *)toastView
{
	if (toastView.superview) 
	{
		[toastView removeFromSuperview];
	}
	
	if (self.parentView) 
	{
		[self.parentView addSubview:toastView];
		[self adjustToastFrame:self.parentView.bounds.size];
	}
	else
	{
		UIWindow *window = [UIApplication sharedApplication].keyWindow;
		[window addSubview:toastView];
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver:toastView selector:@selector(windowOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[toastView transformToastInWindow];
	}
	
	
	toastView.alpha = 0.0;
	[UIView animateWithDuration:toastView.fadeDuration 
					 animations:^{
						 self.alpha = 1.0;
					 }
	 ];
}



-(void)showToastTimeExpired:(NSTimer *)timer
{
	[self fadeToastOut:self];
}

-(void)fadeToastOut:(EZToastView *)toastView
{
	if (toastView.superview) 
	{
		[UIView animateWithDuration:toastView.fadeDuration 
						 animations:^{
							 self.alpha = 0.0;
						 }
						 completion:^(BOOL finished) {
							 [EZToastView removeToastView];
						 }
		 ];
	}
}


+(void)removeToastView
{
	NSMutableArray *toastViews = [EZToastView toastViews];
	if ([toastViews count] > 0) 
	{
		EZToastView *toastView = [toastViews objectAtIndex:0];
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter removeObserver:toastView];
		if (toastView.superview) 
		{
			[toastView removeFromSuperview];
		}
		[toastViews removeObjectAtIndex:0];
		[EZToastView showNextToastIfAvailable];
	}
}



#pragma mark - Orientation changes

- (void)windowOrientationChanged:(NSNotification *)notification
{
	[self transformToastInWindow];
}

-(void)transformToastInWindow
{
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	CGSize windowSize = window.bounds.size;
	
	UIApplication *application = [UIApplication sharedApplication];
	UIInterfaceOrientation orientation = application.statusBarOrientation;
	CGSize statusBarSize;
	if (application.statusBarHidden) 
	{
		statusBarSize = CGSizeMake(0.0, 0.0);
	}
	else
	{
		statusBarSize = application.statusBarFrame.size;
	}
	
	CGFloat rotation = 0.0;
	
	switch (orientation) 
	{ 
		case UIInterfaceOrientationPortrait:
		{
			rotation = 0.0;
			break;
		}
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			rotation = M_PI;
			break;
		}
		case UIInterfaceOrientationLandscapeLeft:
		{
			rotation = - M_PI / 2.0f;
			break;
		}
		case UIInterfaceOrientationLandscapeRight:
		{
			rotation = M_PI / 2.0f;
			break;
		}
	} 
	
	self.transform = CGAffineTransformMakeRotation(rotation);
	
	
	CGRect toastFrame = self.frame;
	
	switch (orientation) 
	{ 
		case UIInterfaceOrientationPortrait:
		{
			switch (self.toastAlignment) 
			{
				case EZToastViewAlignmentTop:
					toastFrame.origin.y = (int)(statusBarSize.height + self.toastAlignmentMargin);
					break;
				case EZToastViewAlignmentBottom:
					toastFrame.origin.y = (int)(windowSize.height - self.toastAlignmentMargin - toastFrame.size.height);
					break;
				case EZToastViewAlignmentCenter:
					toastFrame.origin.y = (int)(windowSize.height / 2.0 - toastFrame.size.height / 2.0);
					break;
				default:
					break;
			}
			toastFrame.origin.x = (int)(windowSize.width / 2 - toastFrame.size.width / 2);
			break;
		}
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			switch (self.toastAlignment) 
			{
				case EZToastViewAlignmentTop:
					toastFrame.origin.y = (int)(windowSize.height - self.toastAlignmentMargin - toastFrame.size.height - statusBarSize.height);
					break;
				case EZToastViewAlignmentBottom:
					toastFrame.origin.y = (int)(self.toastAlignmentMargin);
					break;
				case EZToastViewAlignmentCenter:
					toastFrame.origin.y = (int)(windowSize.height / 2.0 - toastFrame.size.height / 2.0);
					break;
				default:
					break;
			}
			toastFrame.origin.x = (int)(windowSize.width / 2 - toastFrame.size.width / 2);
			break;
		}
		case UIInterfaceOrientationLandscapeLeft:
		{
			switch (self.toastAlignment) 
			{
				case EZToastViewAlignmentTop:
					toastFrame.origin.x = (int)(statusBarSize.width + self.toastAlignmentMargin);
					break;
				case EZToastViewAlignmentBottom:
					toastFrame.origin.x = (int)(windowSize.width - self.toastAlignmentMargin - toastFrame.size.width);
					break;
				case EZToastViewAlignmentCenter:
					toastFrame.origin.x = (int)(windowSize.width / 2.0 - toastFrame.size.width / 2.0);
					break;
				default:
					break;
			}
			toastFrame.origin.y = (int)(windowSize.height / 2 - toastFrame.size.height / 2);
			break;
		}
		case UIInterfaceOrientationLandscapeRight:
		{
			switch (self.toastAlignment) 
			{
				case EZToastViewAlignmentTop:
					toastFrame.origin.x = (int)(windowSize.width - self.toastAlignmentMargin - toastFrame.size.width - statusBarSize.width);
					break;
				case EZToastViewAlignmentBottom:
					toastFrame.origin.x = (int)(self.toastAlignmentMargin);
					break;
				case EZToastViewAlignmentCenter:
					toastFrame.origin.x = (int)(windowSize.width / 2.0 - toastFrame.size.width / 2.0);
					break;
				default:
					break;
			}
			toastFrame.origin.y = (int)(windowSize.height / 2 - toastFrame.size.height / 2);
			break;
		}
	}
	self.frame = toastFrame;
}


-(void)adjustToastFrame:(CGSize)containerSize
{
	CGRect toastFrame = self.frame;
	
	switch (self.toastAlignment) 
	{
		case EZToastViewAlignmentTop:
			toastFrame.origin.y = (int)(self.toastAlignmentMargin);
			self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			break;
		case EZToastViewAlignmentBottom:
			toastFrame.origin.y = (int)(containerSize.height - self.toastAlignmentMargin - toastFrame.size.height);
			self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			break;
		case EZToastViewAlignmentCenter:
			toastFrame.origin.y = (int)(containerSize.height / 2.0 - toastFrame.size.height / 2.0);
			self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			break;
		default:
			break;
	}
	toastFrame.origin.x = (int)(containerSize.width / 2 - toastFrame.size.width / 2);
	self.frame = toastFrame;
}


#pragma mark - Memory


-(void)dealloc
{
	[_borderColor release];
	[_message release];
	[_messageFont release];
	[_messageColor release];
	[_toastBackgroundColor release];
	[_parentView release];
	[super dealloc];
}


#pragma mark - Other
-(void)setValue:(id)value forUndefinedKey:(NSString *)key{}

@end

