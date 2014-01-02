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
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE, dd MMM yy HH:mm:ss VVVV"];
    NSDate *todayDate = [NSDate date];
    double ti = [dateCreated timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
    	return @"a few seconds ago";
    } else 	if (ti < 60) {
    	return @"less than a minute ago";
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%d hours ago", diff];
    } else if (ti < 172800) {
        return @"yesterday";
    } else {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d days ago", diff];
    }
}


@end
