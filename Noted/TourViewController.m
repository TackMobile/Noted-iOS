//
//  TourViewController.m
//  Noted
//
//  Created by Ben Pilcher on 11/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "TourViewController.h"
#import "UIView+position.h"
#import "UIColor+HexColor.h"

#define RIGHT_BTN_START     0
#define RIGHT_BTN_EXIT      1

NSString *const kStepDescription = @"tourStepDescription";
NSString *const kTourStepNumber = @"tourStepNum";

@interface TourViewController ()
{
    NSArray *_steps;
}

@end

@implementation TourViewController

- (id)init
{
    self = [super initWithNibName:@"TourView" bundle:nil];
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
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStepComplete:) name:@"stepComplete" object:nil];
    
    _steps = [NSArray arrayWithObjects:
              [NSDictionary dictionaryWithObjectsAndKeys:
               @"Use a two-finger swipe from the right of the note area to create a new note",kStepDescription,
               [NSNumber numberWithInt:1],@"index",@"NoteStackViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Awesome! Try creating another note.",kStepDescription,
               [NSNumber numberWithInt:2],@"index",@"NoteStackViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"You can swipe left or right on a note to cycle through your notes.",kStepDescription,
               [NSNumber numberWithInt:3],@"index",@"NoteStackViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"To delete a note, do a two-finger swipe from the left.",kStepDescription,
               [NSNumber numberWithInt:4],@"index",@"NoteStackViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"To delete a note, do a two-finger swipe from the left.",kStepDescription,
               [NSNumber numberWithInt:5],@"index",@"NoteStackViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Pinch the note to bring all your notes into view.",kStepDescription,
               [NSNumber numberWithInt:6],@"index",@"NoteListViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Pulling down on the list is another way to create a note.",kStepDescription,
               [NSNumber numberWithInt:7],@"index",@"NoteListViewController",@"vcClass",nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"Tap on the menu icon in the upper-right to share your note, access settings and change the note color.",kStepDescription,
               [NSNumber numberWithInt:7],@"index",@"NoteStackViewController",@"vcClass",nil],
    nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skip:(id)sender {
    
}

- (IBAction)startTour:(id)sender {
    if (self.rightButton.tag == RIGHT_BTN_START) {
        [self goToStep:0];
        self.rightButton.tag = RIGHT_BTN_EXIT;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didExitTour"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didExitTourNotification" object:nil userInfo:nil];

        [self tourFinished];
    }
}

- (void)resumeWithView:(UIView *)view completionBlock:(void(^)())completionBlock
{
    
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
    NSDictionary *step = [_steps objectAtIndex:stepNum];
    [_messageLabel setText:[step objectForKey:kStepDescription]];
    NSLog(@"%@",[step objectForKey:kStepDescription]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tourStepBegun" object:nil userInfo:step];
}

- (void)tourFinished
{
    NSLog(@"Done!");
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.view setFrameY:CGRectGetMaxY(self.view.superview.frame)];
                     }
                     completion:^(BOOL finished){
                         
                     }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"stepComplete" object:nil];
    
}

- (BOOL)shouldResume
{
    int stepsComplete = [self currentStep];
    BOOL incomplete = stepsComplete < _steps.count;
    BOOL exited = [[NSUserDefaults standardUserDefaults] boolForKey:@"didExitTour"];
    return incomplete && !exited;
}

- (void)handleStepComplete:(NSNotification *)note
{
    [self advance];
    [self goToStep:[self currentStep]];
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
    NSNumber *currentStepNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kTourStepNumber];
    if (!currentStepNumber) {
        currentStepNumber = [NSNumber numberWithInt:0];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didExitTour"];
    }
    
    return currentStepNumber.integerValue;
}

- (void)advance
{
    NSInteger currentStep = [self currentStep];
    NSLog(@"step %i",currentStep+1);
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:currentStep+1] forKey:kTourStepNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
