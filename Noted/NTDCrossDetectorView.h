//
//  NTDCrossDetectorView.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/16/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTDCrossDetectorView;

@protocol NTDCrossDetectorViewDelegate <NSObject>
-(void)crossDetectorViewDidDetectCross:(NTDCrossDetectorView *)view;
@end

@interface NTDCrossDetectorView : UIView

@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, weak) id<NTDCrossDetectorViewDelegate> delegate;
@end
