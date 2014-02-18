//
//  NotedTests.m
//  NotedTests
//
//  Created by Vladimir Fleurima on 2/14/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <Kiwi/Kiwi.h>

SPEC_BEGIN(MathSpec)

describe(@"Math", ^{
    it(@"is pretty cool", ^{
        NSUInteger a = 16;
        NSUInteger b = 26;
        [[@(a+b) should] equal:@(42)];
//        [[theValue(a + b) should] equal:theValue(42)];
    });
});

SPEC_END
