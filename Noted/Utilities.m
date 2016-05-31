//
//  Utilities.m
//  Noted
//
//  Created by James Bartolotta on 5/31/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+(NSString*)formatRelativeDate:(NSDate*)dateCreated {
    
    NSDate *todayDate = [NSDate date];
    
    // include the year if it differs from this year
    NSUInteger unitFlags = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:todayDate];
    todayComponents.hour = 0;
    todayComponents.minute = 0;
    NSDateComponents *createdComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:dateCreated];
    createdComponents.hour = 0;
    createdComponents.minute = 0;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSLocale *locale = [NSLocale currentLocale];
    [cal setTimeZone:[NSTimeZone localTimeZone]];
    [cal setLocale:locale];
    
    todayDate = [cal dateFromComponents:todayComponents];
    dateCreated = [cal dateFromComponents:createdComponents];
    
    NSDateComponents *components = [cal components:NSDayCalendarUnit
                                          fromDate:dateCreated
                                            toDate:todayDate
                                           options:0];
        
    NSInteger days = [components day];
    
    if (days < 2) {
        static NSDateFormatter *localizedRelativeDateFormatter;
        if (!localizedRelativeDateFormatter) {
            localizedRelativeDateFormatter = [NSDateFormatter new];
            [localizedRelativeDateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [localizedRelativeDateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [localizedRelativeDateFormatter setLocale:locale];
            [localizedRelativeDateFormatter setDoesRelativeDateFormatting:YES];
        }
        return [localizedRelativeDateFormatter stringFromDate:dateCreated];
    } else if (days < 7 && [@"en" isEqualToString:[locale objectForKey:NSLocaleLanguageCode]]) {
        return [NSString stringWithFormat:@"%ld days ago", (long)days];
    } else {
        static NSDateFormatter *sameYearDateFormatter, *differentYearDateFormatter;
        if (!sameYearDateFormatter) {
            sameYearDateFormatter = [NSDateFormatter new];
            [sameYearDateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMMMd" options:0 locale:locale]];
        }
        if (!differentYearDateFormatter) {
            differentYearDateFormatter = [NSDateFormatter new];
            [differentYearDateFormatter setDateStyle:NSDateFormatterLongStyle];
        }

        NSDateFormatter *dateFormatter = ([todayComponents year] == [createdComponents year]) ? sameYearDateFormatter : differentYearDateFormatter;
        NSString *formattedDate = [dateFormatter stringFromDate:dateCreated];

        return formattedDate;
    }
    
    // today
    // yesterday
    // x days ago (up to 6)
    // date (January 2nd) (December 25th 2013)
}


@end
