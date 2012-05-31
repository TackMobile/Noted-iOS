//
//  Utilities.h
//  Noted
//
//  Created by James Bartolotta on 5/31/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject
+(NSString*)formatRelativeDate:(NSDate*)date;
+(NSString *)formatDate:(NSDate*)date;
+(NSString*)getCurrentTime;
@end
