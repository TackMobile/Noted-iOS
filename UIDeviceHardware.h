//
//  UIDeviceHardware.h
//
//  Used to determine EXACT version of device software is running on.

typedef NS_ENUM(NSInteger, NTDDevicePerformanceClass) {
    NTDHighPerformanceDevice = 0,
    NTDLowPerformanceDevice
};

@interface UIDeviceHardware : NSObject
+ (NTDDevicePerformanceClass) performanceClass;
+ (BOOL)isHighPerformanceDevice;
+ (NSString *)deviceType;
@end