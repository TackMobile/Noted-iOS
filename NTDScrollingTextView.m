//
//  NTDScrollingTextView.m
//  Noted
//
//  Created by Tack Workspace on 5/29/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDScrollingTextView.h"

@interface NTDScrollingTextView () <UITextViewDelegate>

    @property (nonatomic, weak) id<UITextViewDelegate> customDelegate;

@end

@implementation NTDScrollingTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [super setDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardIsUp:) name:UIKeyboardDidShowNotification object:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [super setDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardIsUp:) name:UIKeyboardDidShowNotification object:nil];
    }
    return self;
}

// intercept the delegate call
- (void)setDelegate:(id<UITextViewDelegate>)delegate
{
    self.customDelegate = delegate;
    [super setDelegate:self];
} 

static CGFloat heightDifference;
-(void)setContentOffset:(CGPoint)contentOffset
{
    //    NSLog(@"%p Existing Offset: %@ New Offset: %@ Height Difference: %.2f", self, NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(contentOffset), self.contentOffset.y - contentOffset.y);
    CGFloat offsetDifference = self.contentOffset.y - contentOffset.y;
    if (heightDifference != 0 &&
        offsetDifference != 0 && /* Don't bother if vertical offset hasn't changed. */
        SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && /* <3 iOS 7 */
        !self.dragging && /* Otherwise this triggers while the keyboard is scrolling. */
        ABS(offsetDifference - heightDifference) < 0.01) /* Ghetto tolerance check */
    {
        //        NSLog(@"[RESET] %p Existing Offset: %@ New Offset: %@ Height Difference: %.2f", self, NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(contentOffset), offsetDifference);
        contentOffset = CGPointZero;
    }
    [super setContentOffset:contentOffset];
}

-(void)setContentSize:(CGSize)contentSize
{
    heightDifference = self.contentSize.height - contentSize.height;
    //    NSLog(@"%p Existing Size: %@ New Size: %@ Height Difference: %.2f", self, NSStringFromCGSize(self.contentSize), NSStringFromCGSize(contentSize), self.contentSize.height - contentSize.height);
    [super setContentSize:contentSize];
}

#pragma mark - Helper Methods

- (void) scrollToCaretAnimated:(BOOL)animated {
    // automatic scrolling is default <7.0
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
        return;

    CGRect rect = [self caretRectForPosition:self.selectedTextRange.end];
    rect.size.height += self.textContainerInset.bottom;
    [self scrollRectToVisible:rect animated:animated];
}

- (void)keyboardIsUp:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.superview convertRect:keyboardRect fromView:nil];
    
    UIEdgeInsets inset = self.contentInset;
    inset.bottom = keyboardRect.size.height;
    self.contentInset = inset;
    self.scrollIndicatorInsets = inset;
    
    [self scrollToCaretAnimated:YES];
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if ([textView.text hasSuffix:@"\n"]) {
        [CATransaction setCompletionBlock:^{
            [self scrollToCaretAnimated:NO];
        }];
    } else {
        [self scrollToCaretAnimated:NO];
    }
    if ([self.customDelegate respondsToSelector:@selector(textViewDidChange:)])
        return [self.customDelegate textViewDidChange:textView];

}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([self.customDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)])
        return [self.customDelegate textViewShouldBeginEditing:textView];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.customDelegate respondsToSelector:@selector(textViewDidEndEditing:)])
        [self.customDelegate textViewDidEndEditing:textView];

}

@end
