//
//  UIDeviceHardware.h
//
//  Used to determine EXACT version of device software is running on.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NTDDevicePerformanceClass) {
    NTDHighPerformanceDevice = 0,
    NTDLowPerformanceDevice
};

@interface UIDeviceHardware : NSObject
+ (NTDDevicePerformanceClass) performanceClass;
@end