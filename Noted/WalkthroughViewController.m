//
//  TourViewController.m
//  Noted
//
//  Created by Ben Pilcher on 11/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "WalkThroughViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+position.h"
#import "UIColor+HexColor.h"

#define RIGHT_BTN_START     0
#define RIGHT_BTN_EXIT      1

NSString *const kStepDescription =          @"walkthroughStepDescription";
NSString *const kStepViewControllerClass =  @"viewControllerClass";
NSString *const kWalkthroughStepNumber =    @"walkthroughStepNum";
NSString *const kDidExitTour =              @"walkthroughExited";

NSString *const kWalkThroughStepBegun =     @"walkThroughStepBegunNotification";
NSString *const kWalkThroughExited =        @"didExitTourNotification";
NSString *const kWalkThroughStepComplete =  @"stepCompleteNotification";

@interface WalkThroughViewController ()
{
    NSArray *_steps;
}

@end

@implementation WalkThroughViewController

- (id)init
{
    self = [super initWithNibName:@"WalkThroughView" bundle:nil];
    if (self){
        // register defaults
        [self currentStep];
        
        self.rightButton.tag = RIGHT_BTN_START;
        [self.view setTag:900];
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
    
    [self.view setBackgroundColor:[UIColor colorWithHexString:@"1A9FEB"]];
    [self.rightButton setBackgroundColor:[UIColor colorWithHexString:@"A7D2EB"]];
    self.rightButton.layer.cornerRadius = 0;
    [self.leftButton setBackgroundColor:[UIColor colorWithHexString:@"A7D2EB"]];
    self.leftButton.layer.cornerRadius = 0;
    
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStepComplete:) name:kWalkThroughStepComplete object:nil];
    
    _steps = [NSArray arrayWithObjects:
              [NSDictionary dictionaryWithObjectsAndKeys:
               @"Use a two-finger swipe from the right of the note area to create a new note",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep1],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Awesome! You amaze me. Try creating another note.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep2],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"You can swipe left or right on a note to cycle through your notes.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep3],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"To delete a note, do a two-finger swipe from the left.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep4],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Pinch the note to bring all your notes into view.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep5],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Pulling down on the list is another way to create a note.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep6],@"index",@"NoteListViewController",kStepViewControllerClass,nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Tap on the menu icon in the upper-right to share your note, access settings and change the note color.",kStepDescription,
               [NSNumber numberWithInt:walkThroughStep7],@"index",@"NoteStackViewController",kStepViewControllerClass,nil],
    nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skip:(id)sender {
    [self exit];
}

- (IBAction)startTour:(id)sender {
    if (self.rightButton.tag == RIGHT_BTN_START) {
        [self goToStep:1];
        self.rightButton.tag = RIGHT_BTN_EXIT;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidExitTour];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didExitTourNotification" object:nil userInfo:nil];

        [self tourFinished];
    }
}

- (void)exit
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidExitTour];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didExitTourNotification" object:nil userInfo:nil];
    
    [self tourFinished];
}

- (void)resumeWithCompletionBlock:(void(^)())completionBlock
{
    if ([self currentStep]>0) {
        [self goToStep:[self currentStep]];
    }
}

- (void)goToStep:(NSUInteger)stepNum
{
    if (stepNum > _steps.count) {
        [self tourFinished];
        return;
    }
    if ([self currentStep] == 0) {
        [self.leftButton setHidden:YES];
        [self.rightButton setTitle:@"Exit Tour" forState:UIControlStateNormal];
    }
    
    NSDictionary *step = [_steps objectAtIndex:stepNum-1];
    [UIView animateWithDuration:0.25
                     animations:^{
                         _messageLabel.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [_messageLabel setText:[step objectForKey:kStepDescription]];
                         [UIView animateWithDuration:0.25
                                          animations:^{
                                              _messageLabel.alpha = 1.0;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                     }];
    
    
    if ([[step objectForKey:@"index"] intValue] == _steps.count-1) {
        [self.rightButton setTitle:NSLocalizedString(@"That's it!",@"That's it!") forState:UIControlStateNormal];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kWalkThroughStepBegun object:nil userInfo:step];
}

- (void)tourFinished
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.view setFrameY:CGRectGetMaxY(self.view.superview.frame)];
                         [self.view setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
                         
                     }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kWalkThroughStepComplete object:nil];
    
}

- (BOOL)shouldResume
{
    int stepsComplete = [self currentStep];
    BOOL incomplete = stepsComplete < _steps.count;
    BOOL exited = [[NSUserDefaults standardUserDefaults] boolForKey:kDidExitTour];
    return incomplete && !exited;
}

- (void)handleStepComplete:(NSNotification *)note
{
    [self advance];
    int nextStep = [self currentStep]+1;
    [self goToStep:nextStep];
    if (_stepCompleteBlock) {
        _stepCompleteBlock();
    }
}

- (int)nextStepNumber
{
    return [self currentStep] + 1;
}

- (NSUInteger)currentStep
{
    NSNumber *currentStepNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kWalkthroughStepNumber];
    if (!currentStepNumber) {
        currentStepNumber = [NSNumber numberWithInt:0];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDidExitTour];
    }
    
    return currentStepNumber.integerValue;
}

- (void)advance
{
    NSInteger currentStep = [self currentStep];
    //NSLog(@"step %i",currentStep+1);
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:currentStep+1] forKey:kWalkthroughStepNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
