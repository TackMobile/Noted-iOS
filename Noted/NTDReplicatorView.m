//
//  NTDReplicatorView.m
//  Noted
//
//  Created by Vladimir Fleurima on 8/6/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NTDReplicatorView.h"

@implementation NTDReplicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (Class)layerClass
{
    return [CAReplicatorLayer class];
}

- (CAReplicatorLayer *)replicatorLayer
{
    return (CAReplicatorLayer *)self.layer;
}

@end
