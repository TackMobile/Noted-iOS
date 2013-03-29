//
//  TransformableNoteCell.m
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "TransformableNoteCell.h"
#import "UIColor+Utils.h"
#import <QuartzCore/QuartzCore.h>

@interface UnfoldingNoteCell : TransformableNoteCell
@end

@interface PullDownNoteCell : TransformableNoteCell
@end

@implementation UnfoldingNoteCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1/500.f;
        [self.contentView.layer setSublayerTransform:transform];
        
        self.textLabel.layer.anchorPoint = CGPointMake(0.5, 0.0);
        
        self.detailTextLabel.layer.anchorPoint = CGPointMake(0.5, 1.0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        self.tintColor = [UIColor whiteColor];
    }
    return self;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat fraction = (self.frame.size.height / self.finishedHeight);
    fraction = MAX(MIN(1, fraction), 0);
    
    CGFloat angle = (M_PI / 2) - asinf(fraction);
    CATransform3D transform = CATransform3DMakeRotation(angle, -1, 0, 0);
    [self.textLabel.layer setTransform:transform];
    [self.detailTextLabel.layer setTransform:CATransform3DMakeRotation(angle, 1, 0, 0)];
    
    self.textLabel.backgroundColor       = [self.tintColor colorWithBrightness:0.3 + 0.7*fraction];
    self.detailTextLabel.backgroundColor = [self.tintColor colorWithBrightness:0.5 + 0.5*fraction];
    
    CGSize contentViewSize = self.contentView.frame.size;
    CGFloat contentViewMidY = contentViewSize.height / 2;
    CGFloat labelHeight = self.finishedHeight / 2;
    
    // OPTI: Always accomodate 1 px to the top label to ensure two labels 
    // won't display one px gap in between sometimes for certain angles 
    self.textLabel.frame = CGRectMake(0, contentViewMidY - (labelHeight * fraction),
                                      contentViewSize.width, labelHeight + 1);
    self.detailTextLabel.frame = CGRectMake(0, contentViewMidY - (labelHeight * (1 - fraction)),
                                            contentViewSize.width, labelHeight);
}

@end

@implementation PullDownNoteCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1/500.f;
        [self.contentView.layer setSublayerTransform:transform];
        
        self.textLabel.layer.anchorPoint = CGPointMake(0.5, 1.0);
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        self.tintColor = [UIColor whiteColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat fraction = (self.frame.size.height / self.finishedHeight);
    fraction = MAX(MIN(1, fraction), 0);
    
    CGFloat angle = (M_PI / 2) - asinf(fraction);
    CATransform3D transform = CATransform3DMakeRotation(angle, 1, 0, 0);
    [self.textLabel.layer setTransform:transform];
    
    self.textLabel.backgroundColor       = [self.tintColor colorWithBrightness:0.3 + 0.7*fraction];
    
    CGSize contentViewSize = self.contentView.frame.size;
    CGFloat labelHeight = self.finishedHeight;
    
    // OPTI: Always accomodate 1 px to the top label to ensure two labels 
    // won't display one px gap in between sometimes for certain angles 
    self.textLabel.frame = CGRectMake(0, contentViewSize.height - labelHeight,
                                      contentViewSize.width, labelHeight);
}

@end

#pragma mark -

@implementation TransformableNoteCell
@synthesize finishedHeight, tintColor;

+ (TransformableNoteCell *)unfoldingTableViewCellWithReuseIdentifier:(NSString *)reuseIdentifier {
    UnfoldingNoteCell *cell = (id)[[UnfoldingNoteCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                                         reuseIdentifier:reuseIdentifier];
    return cell;
}

+ (TransformableNoteCell *)pullDownTableViewCellWithReuseIdentifier:(NSString *)reuseIdentifier {
    PullDownNoteCell *cell = (id)[[PullDownNoteCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                       reuseIdentifier:reuseIdentifier];
    return cell;
}

+ (TransformableNoteCell *)transformableNoteCellWithStyle:(TransformableNoteCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    switch (style) {
        case TransformableNoteCellStylePullDown:
            return [TransformableNoteCell pullDownTableViewCellWithReuseIdentifier:reuseIdentifier];
            break;
        case TransformableNoteCellStyleUnfolding:
        default:
            return [TransformableNoteCell unfoldingTableViewCellWithReuseIdentifier:reuseIdentifier];
            break;
    }
}

@end
