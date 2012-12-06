//
//  DragToCreateViewController.m
//  Noted
//
//  Created by Nick Place on 11/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "DragToCreateViewController.h"
#import "NoteEntryCell.h"
#import "UIColor+HexColor.h"
#import "UIView+position.h"

#define SHADOW_TAG           56
#define SHADOW_TAG2          57
#define THRESHOLD CGRectGetHeight(self.view.frame)

@interface DragToCreateViewController ()
{
    NoteEntryCell *_newNote;
    CALayer *_newNoteContentLayer;
    UIView *_newNoteContainer;
}

@end

@implementation DragToCreateViewController
@synthesize scrollIndicatorImage, instructionLabel;

- (id)init
{
    self = [super initWithNibName:@"DragToCreateView" bundle:nil];
    if (self){
        scrollThreshold = self.view.frame.size.height; // the same height of this xib
        _dragging = YES;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)n bundle:(NSBundle *)b
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self scrollingWithYOffset:0.0];
    [self.view setClipsToBounds:YES];

    [self.view setBackgroundColor:[UIColor colorWithHexString:@"808080"]];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - scrolling

- (void) scrollingWithYOffset:(float)yOffset {
    
    if (!_dragging) {
        return;
    }
    
    [self updateViewsWithOffset:yOffset];
    
    if (abs(yOffset) > THRESHOLD) {
        instructionLabel.text = NSLocalizedString(@"Release to Create a New Note",@"Release to create");
        
        [self.view setFrameY:yOffset];
        
                       
    } else {
        
        [_newNoteContainer removeFromSuperview];

        instructionLabel.text = NSLocalizedString(@"Pull Down to Create a New Note",@"Pull down to create");
    }
}

- (void)updateViewsWithOffset:(float)yOffset
{
    if (!_newNote) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteEntryCell" owner:nil options:nil];
        _newNote = (NoteEntryCell *)[topLevelObjects lastObject];
        UIColor *tempColor = [UIColor colorWithHexString:@"AAAAAA"];
        _newNote.relativeTimeText.textColor = tempColor;
        _newNote.subtitleLabel.numberOfLines = 0;
        [_newNote.subtitleLabel setText:@""];
        [_newNote.subtitleLabel sizeToFit];
        
        UIView *shadow = [_newNote viewWithTag:SHADOW_TAG];
        UIView *shadow2 = [_newNote viewWithTag:SHADOW_TAG2];
        UIView *corners = [_newNote viewWithTag:91];
        [corners setHidden:YES];
        [shadow setHidden:YES];
        [shadow2 setHidden:YES];
        
        UIView *theView = [[UIView alloc] initWithFrame:_newNote.frame];
        [theView setBackgroundColor:[UIColor clearColor]];
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_newNote.bounds
                                                       byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                             cornerRadii:CGSizeMake(6.0, 6.0)];
        
        // Create the shadow layer
        CAShapeLayer *shadowLayer = [CAShapeLayer layer];
        [shadowLayer setFrame:theView.bounds];
        [shadowLayer setMasksToBounds:NO];
        [shadowLayer setShadowPath:maskPath.CGPath];
        shadowLayer.shadowColor = [UIColor blackColor].CGColor;
        shadowLayer.shadowOpacity = 0.3;
        shadowLayer.shadowOffset = CGSizeMake(0.0, -2.0);
        
        [_newNote setBackgroundColor:[UIColor clearColor]];
        [_newNote.contentView setBackgroundColor:[UIColor whiteColor]];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        [maskLayer setFrame:theView.bounds];
        [maskLayer setPath:maskPath.CGPath];
        
        // Create the rounded layer, and mask it using the rounded mask layer
        _newNoteContentLayer = [CALayer layer];
        [_newNoteContentLayer setFrame:theView.bounds];
        
        _newNote.layer.mask = maskLayer;
        [_newNoteContentLayer setContents:(id)[self imageForView:_newNote].CGImage];
        
        _newNoteContentLayer.mask = maskLayer;
        
        [theView.layer addSublayer:shadowLayer];
        [theView.layer addSublayer:_newNoteContentLayer];
        
        _newNoteContainer = theView;
        [_newNoteContainer setBackgroundColor:[UIColor clearColor]];
        
        UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(_newNote.subtitleLabel.frame), 320.0, 40.0)];
        [bottom setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight];
        [bottom setBackgroundColor:[UIColor whiteColor]];
        [_newNoteContainer addSubview:bottom];
    }
    
    UIView *superview = self.view.superview;
    [superview insertSubview:self.view atIndex:0];
    [superview insertSubview:_newNoteContainer aboveSubview:self.view];
    
    float distanceToTravel = -44.0;
    float g = yOffset/distanceToTravel;
    
    float absOffset = -(yOffset);
    float diff = absOffset-scrollThreshold;
    float yLoc = -(diff*g);
    
    yLoc = yLoc < yOffset ? yOffset : yLoc;
    
    [_newNoteContainer setFrameY:yLoc];
    [_newNoteContainer setFrameHeight:-(yLoc)];

}

- (UIImage *)imageForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,0.0f); //screenshot
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  
    return viewImage;
}

- (void)commitNewNoteCreation:(void(^)())completion
{
    UIView *superview = [_newNoteContainer superview];
    [superview.superview addSubview:_newNoteContainer];
    
    CGRect frame = _newNoteContainer.frame;
    frame = [superview convertRect:frame toView:superview.superview];
    [_newNoteContainer setFrame:frame];
    
    [UIView animateWithDuration:0.7
                     animations:^{
                         CGRect frame = CGRectMake(0, 0, [[UIScreen mainScreen]bounds].size.width, [[UIScreen mainScreen]bounds].size.height);
                         [_newNoteContainer setFrame:frame];
                     }
                     completion:^(BOOL finished){
                         completion();
                         [_newNoteContainer removeFromSuperview];
                         _dragging = YES;
                     }];
}

@end
