//
//  NotedModel.h
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utilities.h"

@interface NotedModel : NSObject

DEFINE_SHARED_INSTANCE_METHODS_ON_CLASS(NotedModel);

@property(nonatomic,strong) NSOrderedSet *currentNotes;

@end
