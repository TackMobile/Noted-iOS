//
//  NotedModel.m
//  Noted
//
//  Created by Tony Hillerson on 7/18/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "NotedModel.h"
#import "Utilities.h"

@implementation NotedModel
@synthesize currentNotes;

SHARED_INSTANCE_ON_CLASS_WITH_INIT_BLOCK(NotedModel, ^{
    return [[self alloc] init];
});

@end
