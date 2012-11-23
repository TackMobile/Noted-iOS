//
//  StackViewItem.h
//  Noted
//
//  Created by Ben Pilcher on 11/23/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoteEntry.h"

@interface StackViewItem : NSObject

@property (nonatomic, assign) BOOL isLast;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL isNoteEntry;
@property (nonatomic, assign) BOOL isSectionZeroRowOne;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NoteEntry *noteEntry;
@property (nonatomic, assign) NSInteger offsetFromActive;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) UITableViewCell *cell;
@property (nonatomic, assign) CGRect destinationFrame;
@property (nonatomic, assign) CGRect startingFrame;

- (id)initWithIndexPath:(NSIndexPath *)anIndexPath;

@end
