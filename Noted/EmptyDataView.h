//
//  NoActivityView.h
//  MatchOff
//
//  Created by Benjamin Pilcher on 1/13/12.
//  Copyright (c) 2012 Gina + George. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmptyDataViewDelegate <NSObject>

- (void)didDisappear;

@end

@interface EmptyDataView : UIView

@property (nonatomic, assign) BOOL animatedHide;
@property (retain, nonatomic) UIImageView *image;
@property (strong, nonatomic) NSString *gg_keyPath;
@property (nonatomic, weak) id <EmptyDataViewDelegate> delegate;

- (void)show:(BOOL)val;
- (id)initWithFrame:(CGRect)frame subscribedToKeyPath:(NSString *)keyPath;

@end
