//
//  DrawView.h
//  GermanVerbs
//
//  Created by Ben Pilcher on 7/13/12.
//  Copyright (c) 2012 Neptune Native. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^DrawView_DrawBlock)(UIView* v,CGContextRef context);

@interface DrawView : UIView

@property (nonatomic,copy) DrawView_DrawBlock drawBlock;

@end
