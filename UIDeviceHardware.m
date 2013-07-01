//
//  UIDeviceHardware.m
//
//  Used to determine EXACT version of device software is running on.

#import "UIDeviceHardware.h"
#include <sys/types.h>
#include <sys/sysctl.h>

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

+ (NTDDevicePerformanceClass) performanceClass {
    // reference: http://ios.e-lite.org/

    NSString *platformString = [UIDeviceHardware platform];
    
    // NSSets are faster for finding objects
    NSSet *lowPerformanceDeviceStrings = [NSSet setWithObjects:@"iPhone1,1",
                                          @"iPhone1,2",
                                          @"iPhone2,1",
                                          @"iPhone3,1",
                                          @"iPhone3,2",
                                          @"iPhone3,3",
                                          @"iPod1,1",
                                          @"iPod2,1",
                                          @"iPod3,1",
                                          @"iPod4,1",
                                          @"iPad1,1",
                                          @"iPad2,1",
                                          @"iPad2,2",
                                          @"iPad2,3", nil];
    
    if ([lowPerformanceDeviceStrings containsObject:platformString])
        return NTDLowPerformanceDevice;
    
    return NTDHighPerformanceDevice;
}

@end