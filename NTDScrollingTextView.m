//
//  NTDScrollingTextView.m
//  Noted
//
//  Created by Tack Workspace on 5/29/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDScrollingTextView.h"

@implementation NTDScrollingTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardIsUp:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardIsUp:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Helper Methods

- (void)keyboardIsUp:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.superview convertRect:keyboardRect fromView:nil];
    
    UIEdgeInsets inset = self.contentInset;
    inset.bottom = keyboardRect.size.height;

    [UIView animateWithDuration:0.4 animations:^{
        self.contentInset = inset;
        self.scrollIndicatorInsets = inset;
    }];
}

@end
