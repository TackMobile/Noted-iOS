//
//  WalkthroughViewController.m
//  Noted
//
//  Created by Nick Place on 11/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "WalkthroughViewController.h"

@interface WalkthroughViewController ()

@end

typedef enum {
    walkThroughStep1,
    walkThroughStep2,
    walkThroughStep3,
    walkThroughStep4
} UserSteps;

@implementation WalkthroughViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _walkthroughProgress = [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"WalkthroughProgress"] intValue];
    }
    return self;
}

- (void) loadView {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
