//
//  NSIndexPath+NTDManipulation.h
//  Noted
//
//  Created by Vladimir Fleurima on 4/30/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath (NTDManipulation)

- (NSIndexPath *)ntd_indexPathForPreviousItem;
- (NSIndexPath *)ntd_indexPathForNextItem;

@end
