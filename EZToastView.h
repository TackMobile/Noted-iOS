//  EZToastView.h
//  © Lucid Vapor LLC 2012
//
//  control.support@lucidvapor.com
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


#import <UIKit/UIKit.h>




typedef enum EZToastViewAlignment
{
	EZToastViewAlignmentBottom = 0,
	EZToastViewAlignmentCenter = 1,
	EZToastViewAlignmentTop = 2
} EZToastViewAlignment;

/**
 Protocol used to set various appearance related properties
 for EZToastView
 */


@protocol EZToastViewAppearanceDefaults <NSObject>
@required
/**
 The toastAlignmentMargin appearance property
 */
-(void)setToastAlignmentMargin:(CGFloat)toastAlignmentMargin;
/**
 The borderWidth appearance property
 */
-(void)setBorderWidth:(CGFloat)borderWidth;
/**
 The borderColor appearance property
 */
-(void)setBorderColor:(UIColor *)borderColor;
/**
 The fadeDuration appearance property
 */
-(void)setFadeDuration:(NSTimeInterval)fadeDuration;
/**
 The maximumWidth appearance property
 */
-(void)setMaximumWidth:(CGFloat)maximumWidth;
/**
 The toastBackgroundColor appearance property
 */
-(void)setToastBackgroundColor:(UIColor *)toastBackgroundColor;
/**
 The messageColor appearance property
 */
-(void)setMessageColor:(UIColor *)messageColor;
/**
 The messageFont appearance property
 */
-(void)setMessageFont:(UIFont *)messageFont;
/**
 The messageAlignment appearance property
 */
-(void)setMessageAlignment:(UITextAlignment)messageAlignment;
/**
 The showDuration appearance property
 */
-(void)setShowDuration:(NSTimeInterval)showDuration;
/**
 The toastAlignment appearance property
 */
-(void)setToastAlignment:(EZToastViewAlignment)toastAlignment;
@end






/**
 EZToastView displays an unintrusive message to the user.  It is short lived,
 semi-transparent, and non-interactive so the user can be textually notified 
 without being forced to act. It is robustly customizable and allows you to
 get up and rolling with one line of code. No need to link or import 
 dependent libraries. No need to worry about frame and view dimensions.
 
 See [EZToastView How-To](http://www.lucidvapor.com/controls/documentation/EZToastView/howto/)
 for installation and use instructions.
 */


@interface EZToastView : UIView <EZToastViewAppearanceDefaults>


/** @name Configuring the toast's animation effects */

/**
 The amount of time, in seconds, that the toast takes to fade in and also fade out. 
 
 Default value is 0.5 seconds. 
 */
@property (nonatomic, assign) NSTimeInterval fadeDuration;


/**
 The amount of time, in seconds, that the toast displays on the screen before disappearing. 
 
 Default value is 2.0 seconds. 
 */
@property (nonatomic, assign) NSTimeInterval showDuration;



/** @name Configuring the toast's background appearance and frame */

/**
  The maximum width that the toast will expand to, if needed.
 
  If the width of the text is larger than this value, words will be
  wrapped and the height will be enlarged to fit the text. Default
  value is 290.0.
 */
@property (nonatomic, assign) CGFloat maximumWidth;


/**
 The width of the border surrounding the toast.
 
 Default is 2.0.
 */
@property (nonatomic, assign) CGFloat borderWidth;


/**
 The color of the border surrounding the toast.
 
 Default is 80% white. 
 */
@property (nonatomic, retain) UIColor *borderColor;


/**
 The vertical position of the toast within the window or view.
 
 If set to EZToastViewAlignmentBottom, the toast will be positioned
 at the bottom of the view/window but with a bottom margin specified
 by toastAlignmentMargin.  If EZToastViewAlignmentCenter, the toast
 will be dead center.  If EZToastViewAlignmentTop the toast will be
 positioned at the top of the view/window but with a top margin specified
 by toastAlignmentMargin.  Default is EZToastViewAlignmentBottom.
 */
@property (nonatomic, assign) EZToastViewAlignment toastAlignment;


/**
 The toast's margin from either the top or the bottom of the view/window.
 
 Used along with toastAlignment.  Default is 50.0.
 */
@property (nonatomic, assign) CGFloat toastAlignmentMargin;


/**
 The background color of the toast.
 
 Default is black with 70% transparency. 
 */
@property (nonatomic, retain) UIColor *toastBackgroundColor;



/** @name Configuring the toast's text effects */

/**
 The text message to be displayed in the toast.
 
 */
@property (nonatomic, retain) NSString *message;


/**
 The font with which to display the message.
 
 Default is [UIFont systemFontOfSize:15.0f].
 */
@property (nonatomic, retain) UIFont *messageFont;


/**
 The color of the text that is displayed in the message property.
 
 Default is white.
 */
@property (nonatomic, retain) UIColor *messageColor;



/**
 The alignment style of the text in the message property.
 
 Default is white.
 */
@property (nonatomic, assign) UITextAlignment messageAlignment;







/** @name Setting global default appearance */

/**
 The singleton instance object used to set global appearance
 properties to.
 
 @return An object that conforms to the *EZToastViewAppearanceDefaults* protocol.
 
 Use this returned object to make permanent appearance changes to
 all future toast objects.  For instance, setting this object's
 toastBackgroundColor to red in the application:didFinishLaunchingWithOptions:
 method, will ensure that all future toast objects have a background 
 color of red, without the need to explicitly do so.
 */
+(id<EZToastViewAppearanceDefaults>)appearanceDefaults;

/**
 Resets any global appearance properties changed using appearanceDefaults
 back to their original values.
 
 */
+(void)resetAppearanceDefaults;







/** @name Displaying the toast message on the screen */

/**
 Quick, convenient method to display a toast message using all the default
 appearance settings.
 
 @param message The text to be displayed and set for the message property.
 */
+(void)showToastMessage:(NSString *)message;

+(void)showToastMessage:(NSString *)message withDelay:(NSTimeInterval)delay andDuration:(NSTimeInterval)duration;


/** 
 Convenient method to display a toast message with a specified toastAlignment.
 
 @param message The text to be displayed and set for the message property.
 @param alignment The *EZToastViewAlignment* to be used for the toastAlignment property.
 */
+(void)showToastMessage:(NSString *)message withAlignment:(EZToastViewAlignment)alignment;


/** 
 Convenient method to display a toast message with a specified toastAlignment
 and toastAlignmentMargin.
 
 @param message The text to be displayed and set for the message property.
 @param alignment The *EZToastViewAlignment* to be used for the toastAlignment property.
 @param alignmentMargin The top or bottom margin to be used for the toastAlignmentMargin property.
 */
+(void)showToastMessage:(NSString *)message withAlignment:(EZToastViewAlignment)alignment alignmentMargin:(CGFloat)margin;


/** 
 Convenient method to display a toast message with any number of specified
 properties.
 
 @param message The text to be displayed and set for the message property.
 @param keysAndValues The dictionary with values and keys to be set.
 
 Each key must be a property name of the EZToastView.  The value for that
 key will be assigned to the property. Consider using the appearanceDefaults
 object to set these values globally.
 */
+(void)showToastMessage:(NSString *)message withPropertyValues:(NSDictionary *)keysAndValues;


/**
 Instance method to display an allocated toast.
 */
-(void)show;


/**
 Instance method to display an allocated toast within the bounds of a specified view.
 
 @param view The view in which to show the toast view.
 */
-(void)showInView:(UIView *)view;
@end
