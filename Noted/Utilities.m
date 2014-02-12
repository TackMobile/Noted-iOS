//
//  Utilities.m
//  Noted
//
//  Created by James Bartolotta on 5/31/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+(NSString*)getCurrentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *now = [NSDate date];
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate:now] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:now] intValue];
    
    NSString *am_pm = @"AM"; 
    
    if (hour > 12) {
        am_pm = @"PM";
        hour = hour - 12;
    }
    
    NSString *dateString;
    if (minute < 10) {
        dateString = [[NSString alloc] initWithFormat:@"%i:0%i %@",hour,minute,am_pm];
    }else {
        dateString = [[NSString alloc] initWithFormat:@"%i:%i %@",hour,minute,am_pm];
    }
    return dateString;
}

+(NSString*)formatDate:(NSDate*)dateCreated {
    NSArray *months = [[NSArray alloc] initWithObjects:@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August", @"September",@"October",@"November",@"December", nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
    [dateFormatter setDateFormat:@"yyyy"];
    
    [dateFormatter setDateFormat:@"MM"];
    int monthInt = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:dateCreated] intValue];
    
    NSString *am_pm = @"AM"; 
    
    if (hour > 12) {
        am_pm = @"PM";
        hour = hour - 12;
    }
    
    if (monthInt == 0) {
        monthInt++;
    }
    NSString *month = [months objectAtIndex:monthInt-1];
    NSString *dateString;
    if (minute < 10) {
        dateString = [[NSString alloc] initWithFormat:@"%@ %i  %i:0%i %@",month,day,hour,minute,am_pm];
    }else {
        dateString = [[NSString alloc] initWithFormat:@"%@ %i  %i:%i %@",month,day,hour,minute,am_pm];
    }
    
    return dateString;
}

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
        return [NSString stringWithFormat:@"%d days ago", days];
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
