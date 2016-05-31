//
//  Utilities.h
//  Noted
//
//  Created by James Bartolotta on 5/31/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

/**
* Method to take a date object and return a string indicating the time difference between that date and now.
* @return A date string formatted based on how long ago the passed in date was.
* If it was less than 2 days difference returns either 'Today' or 'Yesterday'
* If less than 7 days but longer than 2, returns "X days ago"
* If longer than 7 days it returns date formatted like "May 31st" or "May 31st, 2013" if from a different year.
*/
+(NSString*)formatRelativeDate:(NSDate*)date;

@end
