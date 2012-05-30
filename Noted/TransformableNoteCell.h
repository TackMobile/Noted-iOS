//
//  TransformableNoteCell.h
//  Noted
//
//  Created by James Bartolotta on 5/28/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    TransformableNoteCellStyleUnfolding,
    TransformableNoteCellStylePullDown,
} TransformableNoteCellStyle;


@protocol TransformableNoteCell <NSObject>
@property (nonatomic, assign) CGFloat  finishedHeight;
@property (nonatomic, retain) UIColor *tintColor;   // default is white color
@end


@interface TransformableNoteCell : UITableViewCell <TransformableNoteCell>

// Use this factory method instead of 
// - (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
+ (TransformableNoteCell *)transformableNoteCellWithStyle:(TransformableNoteCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@end
