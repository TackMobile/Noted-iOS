//
//  KeyboardScrollView.m
//  Noted
//
//  Created by James Bartolotta on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "KeyboardScrollView.h"

@implementation KeyboardScrollView

- (id)initWithFrame:(CGRect)frame 
{
return [super initWithFrame:frame];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches= [event allTouches];
    self.scrollEnabled = YES;
    if (allTouches.count == 2) {
        self.scrollEnabled = NO;
    }
    [self.nextResponder touchesBegan:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesMoved:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event 
{	
    // If not dragging, send event to next responder
    [self.nextResponder touchesEnded: touches withEvent:event];
    self.scrollEnabled = YES;
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesCancelled:touches withEvent:event];
    self.scrollEnabled = YES;
}

//-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    
//}

@end
