//
//  NoActivityView.m
//  MatchOff
//
//  Created by Benjamin Pilcher on 1/13/12.
//  Copyright (c) 2012 Gina + George. All rights reserved.
//

#import "EmptyDataView.h"
#import "UIColor+HexColor.h"
#import "NoteListViewController.h"

@interface EmptyDataView(PrivateMethods) 

- (void)show:(BOOL)val;

@end

@implementation EmptyDataView

@synthesize image,gg_keyPath,delegate,animatedHide;

- (id)initWithFrame:(CGRect)frame subscribedToKeyPath:(NSString *)keyPath{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.gg_keyPath = keyPath;
        
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 40.0)];
        [label setText:@"Pull to create a note"];
        [self addSubview:label];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setCenter:self.center];
        [label setTextColor:[UIColor colorWithHexString:@"333333"]];
        [self setClipsToBounds:YES];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame subscribedToKeyPath:nil];
    if (self) {
        
    }
    return self;
}

- (void)show:(BOOL)val
{
    if (val == YES) { // show it
        if ([self isHidden]==NO) {
            return;
        }
        [self setAlpha:0.0];
        [self setHidden:NO];
        [UIView animateWithDuration:0.25 
                         animations:^{
                             [self setAlpha:1.0];
                         }
                         completion:^(BOOL finished){
                            [self setUserInteractionEnabled:YES];
                             NSLog(@"showed empty data bg");
                         }];
    } else { // hide it
        [self setUserInteractionEnabled:NO];
        if (self.animatedHide == YES) {
            [UIView animateWithDuration:0.1 
                             animations:^{
                                 [self setAlpha:0.0];
                             }
                             completion:^(BOOL finished){
                                 [self setHidden:YES];
                                 [self setAlpha:1.0];
                                 
                                 if ([delegate respondsToSelector:@selector(didDisappear)]) {
                                     [delegate didDisappear];
                                 }
                                 
                             }];
        } else {
            [self setHidden:YES];
        }
        
        
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:self.gg_keyPath]) {
        NoteListViewController *parentVC = (NoteListViewController *)object;
        [self show:!parentVC.hasData];
    }
}

@end
