//
//  CSUsbController.h
//  SimpleStudio
//
//  Created by centurion on 2/24/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <AVFoundation/AVFoundation.h>

@interface CDeviceManager : NSObject
{
   //Store media type and file path
   NSMutableArray * usbDevices;
}

- (id) copyWithZone:(NSZone*)zone;
+ (id) allocWithZone:(NSZone *)zone;
+ (CDeviceManager *)getInstance;
+ (CDeviceManager *) sharedInstance;

-(void) addDisk:(DADiskRef)disk;
-(void) removeDisk:(DADiskRef)disk;
- (instancetype) singleInit;
-(long long)getActiveDiskSize;

-(NSString *)generateSaveToFlashPath;
-(NSInteger)getCounOfUsbDevices;
@end
