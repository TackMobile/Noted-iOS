//
//  NewNoteCell.m
//  Noted
//
//  Created by Tony Hillerson on 7/24/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NewNoteCell.h"
#import "UIColor+HexColor.h"

@implementation NewNoteCell

@synthesize label;

+ (void)configure:(NewNoteCell *)cell {
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.label.textColor = [UIColor colorWithHexString:@"AAAAAA"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    cell.label.text = NSLocalizedString(@"New Note", @"New Note");
}

@end
