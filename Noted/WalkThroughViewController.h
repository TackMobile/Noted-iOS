//
//  TourViewController.h
//  Noted
//
//  Created by Ben Pilcher on 11/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TourStepCompletedBlock)();

extern NSString *const kStepViewControllerClass;
extern NSString *const kWalkThroughStepBegun;
extern NSString *const kWalkThroughStepComplete;
extern NSString *const kWalkThroughExited;
extern NSString *const kShouldExitTour;
extern NSString *const kWalkthroughStepNumber;
extern NSString *const kShouldExitTour;

typedef enum {
    walkThroughStepCreate1,
    walkThroughStepCreate2,
    walkThroughStepCycle,
    walkThroughStepDelete,
    walkThroughStepGoToList,
    walkThroughStepPullToCreate,
    walkThroughStepOptions
    
} UserSteps;

extern NSString *const kStepDescription;

@interface WalkThroughViewController : UIViewController

@property (nonatomic, copy) TourStepCompletedBlock stepCompleteBlock;
@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

- (IBAction)skip:(id)sender;
- (IBAction)startTour:(id)sender;
- (void)resumeWithCompletionBlock:(void(^)())completionBlock;
- (BOOL)shouldResume;

@end
