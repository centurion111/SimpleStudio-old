//
//  CSUsbController.m
//  SimpleStudio
//
//  Created by centurion on 2/24/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CDeviceManager.h"
#import "CSSettingsManager.h"
#import <DiskArbitration/DiskArbitration.h>

@implementation CDeviceManager
{
   CSSettingsManager * settingsMgr;
}


static CDeviceManager * sharedDeviceManager = nil;

+ (id) allocWithZone:(NSZone *)zone
{
//   NSLog(@"DeviceManager::allocWithZone");

   return [self sharedInstance];
}

- (id) copyWithZone:(NSZone*)zone
{
   return self;
}

+ (CDeviceManager*) sharedInstance
{
 //  NSLog(@"DeviceManager::sharedInstance");

   if (sharedDeviceManager == nil)
      {
      sharedDeviceManager = [[super allocWithZone:NULL] init];
      }
   return sharedDeviceManager;
}

+ (CDeviceManager *)getInstance
{
//   NSLog(@"DeviceManager::getInstance");

   @synchronized(self)
   {
   if (sharedDeviceManager == nil)
      {
      sharedDeviceManager = [[super allocWithZone:NULL] init];
      }
   }
   
   return sharedDeviceManager;
}


- (instancetype) singleInit
{
   if(![super init])
      {
         NSLog(@"DeviceManager:: init init failed");
         return nil;
      }
   DASessionRef devSession;
   usbDevices = [[NSMutableArray alloc]init];
   devSession = DASessionCreate(kCFAllocatorDefault);
   
   DARegisterDiskAppearedCallback(devSession,
                                  kDADiskDescriptionMatchVolumeMountable,
                                  diskAppearedCallback, NULL);
   DARegisterDiskDisappearedCallback(devSession,kDADiskDescriptionMatchVolumeMountable, diskDisappearedCallback, NULL);
   DASessionScheduleWithRunLoop(devSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
   NSLog(@"DeviceManager::init object%@",self);

   
   return [CDeviceManager getInstance];
}

/*=====================================================================
 //------------ USB devices section ------------
 =====================================================================*/


void diskAppearedCallback(DADiskRef disk, void* context)
{
 //  NSLog(@"Disk appeared");
   [[CDeviceManager getInstance] addDisk:disk];
}

void diskDisappearedCallback(DADiskRef disk, void* context)
{
  // NSLog(@"%@ was ejected", DADiskCopyDescription(disk));
   [[CDeviceManager getInstance] removeDisk:disk];

}

-(void) addDisk:(DADiskRef)disk
{
   id wdiskDescr = CFRetain(DADiskCopyDescription(disk));
   NSMutableDictionary * tmpDescr = wdiskDescr;
   if ([@"USB" isEqual:[tmpDescr objectForKey:@"DADeviceProtocol"]]) {
      NSLog(@"DeviceManager::addDisk adding usb device");
      id tmpDisk = CFRetain(disk);
      [usbDevices addObject:tmpDisk];
   }

}

-(void) removeDisk:(DADiskRef)disk
{
   NSLog(@"DeviceManager::removeDisk");
   id tmpDsk = CFRetain(disk);
   [usbDevices removeObject:tmpDsk];

   //[self->usbDevices removeObject:(__bridge id)(disk)];
}

-(NSInteger)getCounOfUsbDevices
{
   return [usbDevices count];
}

-(long long)getActiveDiskSize
{
   id wdiskDescr = CFRetain(DADiskCopyDescription((__bridge DADiskRef)([usbDevices objectAtIndex:0])));
   NSDictionary * tmpDescr = wdiskDescr;
   id diskSize = [tmpDescr objectForKey:@"DAMediaSize"];
   NSString* rs = [diskSize absoluteString];
   NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
   long long number = [[numberFormatter numberFromString:rs] longValue];
   return number;
}

-(NSString *)generateSaveToFlashPath
{
   if (0==[usbDevices count]) {
      return @"";
   }
   id wdiskDescr = CFRetain(DADiskCopyDescription((__bridge DADiskRef)([usbDevices objectAtIndex:0])));
   NSDictionary * tmpDescr = wdiskDescr;
   id tmpMediaPath = [tmpDescr objectForKey:@"DAVolumePath"];
   NSString * aPath = [tmpMediaPath absoluteString];
   NSLog(@"DeviceManager::generateSaveToFlashPath, generated path %@",aPath);

   return aPath;
}

@end
