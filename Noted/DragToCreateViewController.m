//
//  DragToCreateViewController.m
//  Noted
//
//  Created by Nick Place on 11/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "DragToCreateViewController.h"

@interface DragToCreateViewController ()

@end

@implementation DragToCreateViewController
@synthesize scrollIndicatorImage, instructionLabel;

- (id)init
{
    self = [super initWithNibName:@"DragToCreateView" bundle:nil];
    if (self){
        scrollThreshold = self.view.frame.size.height; // the same height of this xib
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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - scrolling

- (void) scrollingWithYOffset:(float)yOffset {

    if (abs(yOffset) > CGRectGetHeight(self.view.frame)) {
        instructionLabel.text = NSLocalizedString(@"Release to Create a New Note",@"Release to create");
    } else {
        instructionLabel.text = NSLocalizedString(@"Pull Down to Create a New Note",@"Pull down to create");
    }
    //double rotation = (M_PI * (yOffset/scrollThreshold));
    //scrollIndicatorImage.transform = CGAffineTransformMakeRotation(rotation);
}

@end
