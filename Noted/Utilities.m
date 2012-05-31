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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *now = [NSDate date];
    
    [dateFormatter setDateFormat:@"yyyy"];
    int year = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowYear = [[dateFormatter stringFromDate:now] intValue];
    [dateFormatter setDateFormat:@"MM"];
    int month = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowMonth = [[dateFormatter stringFromDate:now] intValue];
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:dateCreated] intValue];
    int nowDay = [[dateFormatter stringFromDate:now] intValue];
    
    
    if (month == 1 || month == 2) {
        month += 12;
        year -= 1;
    }
    if (nowMonth == 1 || nowMonth == 2) {
        month+=12;
        year -= 1;
    }
    
    int totalDays = floorf(365.0*year) + floorf(year/4.0) - floorf(year/100.0) + floorf(year/400.0) + day + floorf((153*month+8)/5);
    
    int totalNowDays = floorf(365.0*nowYear) + floorf(nowYear/4.0) - floorf(nowYear/100.0) + floorf(nowYear/400.0) + nowDay + floorf((153*nowMonth+8)/5);
    
    int daysAgo = totalNowDays - totalDays;
    NSString *dateString = [NSString alloc];
    
    if (daysAgo == 0) {
        dateString = [NSString stringWithFormat:@"Today"];
    }else if (daysAgo == 1) {
        dateString = [NSString stringWithFormat:@"Yesterday"];
    }else {
        dateString = [NSString stringWithFormat:@"%i days ago",daysAgo];
    }
    return dateString;
}


@end
