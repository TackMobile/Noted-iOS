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
[[NSNotificationCenter defaultCenter] addObserver:self \
selector:@selector(resetSharedInstance) \
name:kLogout \
object:nil]; \
} \
return _sharedInstance; \
} \
+ (void) resetSharedInstance { \
_sharedInstance = nil; \
[[NSNotificationCenter defaultCenter] removeObserver:self]; \
}


@interface Utilities : NSObject
+(NSString*)formatRelativeDate:(NSDate*)date;
+(NSString *)formatDate:(NSDate*)date;
+(NSString*)getCurrentTime;
@end
