//
//  DragToCreateViewController.h
//  Noted
//
//  Created by Nick Place on 11/20/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DragToCreateViewController : UIViewController {
    float scrollThreshold;
}

@property (strong, nonatomic) IBOutlet UIImageView *scrollIndicatorImage;
@property (strong, nonatomic) IBOutlet UILabel *instructionLabel;
@property (nonatomic, assign) BOOL dragging;

- (void) scrollingWithYOffset:(float)yOffset;
- (void)commitNewNoteCreation:(void(^)())completion;

@end
