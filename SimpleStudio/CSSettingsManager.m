//
//  CSSettingsManager.m
//  SimpleStudio
//
//  Created by centurion on 12/3/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "CSSettingsManager.h"


@implementation CSSettingsManager
@synthesize cbDisplayAlerts;
@synthesize cbFullScreenRecord;
@synthesize cbKeyHook;
@synthesize cbLoadOnStart;
@synthesize selectedPreset;
@synthesize cbSaveToFlash;
@synthesize controlViewPosition;
@synthesize cameraViewOnScreenPosition;
@synthesize selectedVideoDeviceName;
@synthesize selectedAudioDeviceName;
@synthesize ftpAddress;
@synthesize tmpFilePath;
@synthesize ftpUname;
@synthesize ftpPasswd;
@synthesize cbCopyToFTP;

- (void) loadDefaults
{
   prefs = [NSUserDefaults standardUserDefaults];
//   NSLog(@"%@",[prefs valueForKey:@"lastPath"]);
   if (nil == [prefs valueForKey:@"lastPath"]) {
      [prefs setObject:@"/" forKey:@"lastPath"];
      [prefs synchronize];
      
   }
   
   //Selected settings
   if (nil != [prefs valueForKey:@"lastBaseName"]) {
      ftpAddress = [prefs valueForKey:@"lastBaseName"];
   }
   if (nil != [prefs valueForKey:@"lastPath"]) {
      tmpFilePath =  [prefs valueForKey:@"lastPath"];
   }
   if (nil != [prefs valueForKey:@"lastFtpUname"]) {
      ftpUname =  [prefs valueForKey:@"lastFtpUname"];
   }
   if (nil != [prefs valueForKey:@"lastFtpPasswd"]) {
      ftpPasswd =  [prefs valueForKey:@"lastFtpPasswd"];
   }
   if (nil != [prefs valueForKey:@"lastSelectedPreset"]) {
      selectedPreset = [prefs valueForKey:@"lastSelectedPreset"];
   }
   if (nil != [prefs valueForKey:@"lastVideoDevice"]) {
      selectedVideoDeviceName = [prefs valueForKey:@"lastVideoDevice"];
      
   }
   if (nil != [prefs valueForKey:@"lastAudioDevice"]) {
      selectedAudioDeviceName = [prefs valueForKey:@"lastAudioDevice"];
   }
   
   //views in FullScreen
   if (nil != [prefs valueForKey:@"dCameraViewPosition"]) {
      NSPoint tmp = NSPointFromString([prefs stringForKey:@"dCameraViewPosition"]);
      cameraViewOnScreenPosition = &tmp;
   }
   
   if (nil != [prefs valueForKey:@"dControlViewPosition"]) {
      NSPoint tmp = NSPointFromString([prefs stringForKey:@"dControlViewPosition"]);
      controlViewPosition = &tmp;
   }
   
   //CheckBoxes
   if (nil != [prefs valueForKey:@"dSaveToFlash"]) {
      cbSaveToFlash = [prefs boolForKey:@"dSaveToFlash"];
   }
   if (nil != [prefs valueForKey:@"dDisplayAlerts"]) {
      cbDisplayAlerts = [prefs boolForKey:@"dDisplayAlerts"];
   }
   if (nil != [prefs valueForKey:@"dFullScreenRecord"]) {
      cbFullScreenRecord = [prefs boolForKey:@"dFullScreenRecord"];
   }
   if (nil != [prefs valueForKey:@"dLoadOnStart"]) {
      cbLoadOnStart = [prefs boolForKey:@"dLoadOnStart"];
   }
   if (nil != [prefs valueForKey:@"dKeyHook"]) {
      cbKeyHook = [prefs boolForKey:@"dKeyHook"];
   }
   if (nil != [prefs valueForKey:@"dCopyToFTP"]) {
      cbCopyToFTP = [prefs boolForKey:@"dCopyToFTP"];
   }

}

-(void)saveDefaults
{
 //  NSLog(@"CSSettingsMeneger::SaveDefaults");
   
   [prefs setObject:tmpFilePath forKey:@"lastPath"];
   [prefs setObject:ftpAddress forKey:@"lastBaseName"];
   [prefs setObject:ftpUname forKey:@"lastFtpUname"];
   [prefs setObject:ftpPasswd forKey:@"lastFtpPasswd"];

   [prefs setObject:self.selectedAudioDeviceName forKey:@"lastAudioDevice"];
   [prefs setObject:self.selectedVideoDeviceName forKey:@"lastVideoDevice"];
   [prefs setObject:selectedPreset forKey:@"lastSelectedPreset"];
   //[prefs setObject:NSStringFromPoint (*(cameraViewOnScreenPosition)) forKey:@"dCameraViewPosition"];
   //[prefs setObject:NSStringFromPoint (*(controlViewPosition)) forKey:@"dControlViewPosition"];

   [prefs setBool:cbSaveToFlash forKey:@"dSaveToFlash"];
   [prefs setBool:cbDisplayAlerts forKey:@"dDisplayAlerts"];
   [prefs setBool:cbFullScreenRecord forKey:@"dFullScreenRecord"];
   [prefs setBool:cbLoadOnStart forKey:@"dLoadOnStart"];
   [prefs setBool:cbKeyHook forKey:@"dKeyHook"];
   [prefs setBool:cbCopyToFTP forKey:@"dCopyToFTP"];

   
   [prefs synchronize];
   NSLog(@"Prefs:%@",[prefs valueForKey:@"lastPath"]);

   

}

-(NSString *)getValidPathOnStart : (NSString *) pathToValidate
{
   // BOOL isDir;
   NSFileManager *fm = [[NSFileManager alloc]init];
   bool exists = [fm fileExistsAtPath:pathToValidate];
   if (exists)
      {
      return pathToValidate;
      }
    
   NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
   NSString * desktopPath = [paths objectAtIndex:0];
   return desktopPath;
}

- (id) init
{
   NSLog(@"settingsManager:: init");
   if(![super init])
      {
      NSLog(@"settingsManager::  init failed");
      return nil;
      }
   
   return self;
}


@end
