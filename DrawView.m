//
//  DrawView.m
//  GermanVerbs
//
//  Created by Ben Pilcher on 7/13/12.
//  Copyright (c) 2012 Neptune Native. All rights reserved.
//

#import "DrawView.h"
#import <QuartzCore/QuartzCore.h>


@implementation DrawView

@synthesize drawBlock;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        
        if (NO) {
            self.layer.borderColor = [UIColor blueColor].CGColor;
            self.layer.borderWidth = 0.5;
        }
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if(self.drawBlock)
        self.drawBlock(self,context);
}

@end