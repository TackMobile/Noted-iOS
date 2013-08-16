//
//  UIViewController+NTDToast.m
//  Noted
//
//  Created by Nick Place on 8/6/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "UIViewController+NTDToast.h"

@implementation UIViewController (NTDToast)

- (void)showToastWithMessage:(NSString *)message {
    
    UIFont *toastFont = [UIFont fontWithName:@"Avenir-Light" size:20];
    CGSize messageSize = { .width = self.view.frame.size.width - 50, .height = 80};
    
    // calculate the toast size
    CGRect toastRect = {
        .origin.x = (self.view.frame.size.width - messageSize.width)/2,
        .origin.y = (self.view.frame.size.height - messageSize.height)/2,
        .size = messageSize };
    
    // style the toast
    UILabel *toast = [[UILabel alloc] initWithFrame:toastRect];
    toast.text = message;
    toast.font = toastFont;
    toast.backgroundColor = [UIColor colorWithWhite:.17 alpha:1];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    
    // animate the toast
    [self.view addSubview:toast];
    toast.alpha = 0;
    toast.transform = CGAffineTransformMakeScale(1.3, 1.3);
    
    [UIView animateWithDuration:.1 animations:^{
        toast.alpha = .7;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.3 delay:.5 options:0 animations:^{
            toast.alpha = 0;
            toast.transform = CGAffineTransformMakeScale(1.3, 1.3);
            
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
