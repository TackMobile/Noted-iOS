//
//  UIDeviceHardware.m
//
//  Used to determine EXACT version of device software is running on.

#import "UIDeviceHardware.h"
#include <sys/types.h>
#include <sys/sysctl.h>

NSString * const HighPerformanceDevice = @"HighPerformanceDevice";
NSString * const LowPerformanceDevice = @"LowPerformanceDevice";

@implementation UIDeviceHardware

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString *) platformString{
    NSString *platform = [UIDeviceHardware platform];
    // reference: http://ios.e-lite.org/
    
    if ([platform isEqualToString:@"iPhone1,1"] ||
        [platform isEqualToString:@"iPhone1,2"] ||
        [platform isEqualToString:@"iPhone2,1"] ||
        [platform isEqualToString:@"iPhone3,1"] ||
        [platform isEqualToString:@"iPhone3,3"] ||
        [platform isEqualToString:@"iPod1,1"] ||
        [platform isEqualToString:@"iPod2,1"] ||
        [platform isEqualToString:@"iPod3,1"] ||
        [platform isEqualToString:@"iPod4,1"] ||
        [platform isEqualToString:@"iPad1,1"] ||
        [platform isEqualToString:@"iPad2,1"] ||
        [platform isEqualToString:@"iPad2,2"] ||
        [platform isEqualToString:@"iPad2,3"])
    {
        return LowPerformanceDevice;
    }
    
    return HighPerformanceDevice;
}

@end