//
//  NTDCrossDetectorView.m
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import "NTDCrossDetectorView.h"

typedef NS_ENUM(NSInteger, NTDCrossDetectorState) {
    NTDCrossDetectorStatePossible = 0,
    NTDCrossDetectorStateBegan,
    NTDCrossDetectorStateFirstHalfRecognized,
    NTDCrossDetectorStateSecondHalfRecognized,
    NTDCrossDetectorStateFailed,
};

@interface NTDCrossDetectorView ()
@property (nonatomic, assign) CGPoint ltrInitialPoint, ltrFinalPoint, rtlInitialPoint, rtlFinalPoint;
@property (nonatomic, assign) NTDCrossDetectorState state;
@end

@implementation NTDCrossDetectorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.fillColor = [UIColor redColor];
        self.state = NTDCrossDetectorStatePossible;
        self.opaque = NO;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

/* can only enter from Possible or FirstHalfRecognizerd states */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] != 1) {
        self.state = NTDCrossDetectorStateFailed;
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    switch (self.state) {
        case NTDCrossDetectorStatePossible:
        {
            self.ltrInitialPoint = touchPoint;
            self.state = NTDCrossDetectorStateBegan;
            break;
        }

        case NTDCrossDetectorStateFirstHalfRecognized:
        {
            self.rtlInitialPoint = touchPoint;
            break;
        }
        default:
            [self handleIllegalEntryState];
    }

    [super touchesBegan:touches withEvent:event];
}

/* can only enter from Failed, Began, or FirstHalfRecognized states */
/* must transition to Failed state or do no transition */
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint nowPoint = [[touches anyObject] locationInView:self];
    CGPoint prevPoint = [[touches anyObject] previousLocationInView:self];
    switch (self.state) {
        case NTDCrossDetectorStateFailed:
            break;
        case NTDCrossDetectorStateBegan:
            if (nowPoint.x >= prevPoint.x && nowPoint.y >= prevPoint.y) {
                self.ltrFinalPoint = nowPoint;
                [self setNeedsDisplay];
            } else {
                self.state = NTDCrossDetectorStateFailed;
            }
            break;
        case NTDCrossDetectorStateFirstHalfRecognized:
            if (nowPoint.x <= prevPoint.x && nowPoint.y >= prevPoint.y) {
                self.rtlFinalPoint = nowPoint;
                [self setNeedsDisplay];
            } else {
                self.state = NTDCrossDetectorStateFailed;
            }
            break;
        default:
            [self handleIllegalEntryState];
    }
    
    [super touchesMoved:touches withEvent:event];
}

/* can only enter from Failed, Began, or FirstHalfRecognized states */
/* must transition to either FirstHalfRecognized or Possible state */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
    switch (self.state) {
        case NTDCrossDetectorStateFailed:
            self.state = NTDCrossDetectorStatePossible;
            break;
        case NTDCrossDetectorStateBegan:
            self.state = NTDCrossDetectorStateFirstHalfRecognized;
            break;
        case NTDCrossDetectorStateFirstHalfRecognized:
            self.state = NTDCrossDetectorStateSecondHalfRecognized;
            if (self.delegate) {
                [self.delegate crossDetectorViewDidDetectCross:self];
            }
            self.state = NTDCrossDetectorStatePossible;
            break;
        default:
            [self handleIllegalEntryState];
    }

    [super touchesEnded:touches withEvent:event];
}

/* must transition to initial state (Possible) */
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = NTDCrossDetectorStatePossible;
    [super touchesCancelled:touches withEvent:event];
}

- (void)handleIllegalEntryState
{
    NSLog(@"Illegal entry state!");
    abort();
}

@end
