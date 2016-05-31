//
//  Utilities.h
//  Noted
//
//  Created by James Bartolotta on 5/31/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFINE_SHARED_INSTANCE_METHODS_ON_CLASS(klass) \
+ (klass *) sharedInstance; \
+ (void) resetSharedInstance; \


#define SHARED_INSTANCE_ON_CLASS_WITH_INIT_BLOCK(klass, block) \
__strong static klass *_sharedInstance; \
+ (klass *) sharedInstance { \
if (_sharedInstance == nil) { \
_sharedInstance = block(); \
} \
return _sharedInstance; \
} \
+ (void) resetSharedInstance { \
_sharedInstance = nil; \
}


@interface Utilities : NSObject

/**
* Method to take a date object and return a string indicating the time difference between that date and now.
* @return A date string formatted based on how long ago the passed in date was.
* If it was less than 2 days difference returns either 'Today' or 'Yesterday'
* If less than 7 days but longer than 2, returns "X days ago"
* If longer than 7 days it returns date formatted like "May 31st"
*/
+(NSString*)formatRelativeDate:(NSDate*)date;

@end
