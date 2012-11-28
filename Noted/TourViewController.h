//
//  TourViewController.h
//  Noted
//
//  Created by Ben Pilcher on 11/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TourStepCompletedBlock)();

extern NSString *const kStepDescription;

@interface TourViewController : UIViewController

@property (nonatomic, copy) TourStepCompletedBlock stepCompleteBlock;
@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

- (IBAction)skip:(id)sender;
- (IBAction)startTour:(id)sender;
- (void)resumeWithView:(UIView *)view completionBlock:(void(^)())completionBlock;
- (BOOL)shouldResume;

@end
