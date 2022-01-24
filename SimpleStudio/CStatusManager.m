//
//  CalertManager.m
//  SimpleStudio
//
//  Created by centurion on 11/15/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "CStatusManager.h"

@implementation CStatusManager
@synthesize saveDestination;
@synthesize upperStatus;
@synthesize statuses;
@synthesize settings;

-(id)init
{
   if (![super init]) {
      NSLog(@"CStatusManager::init init failed");
      return nil;
   }
   statuses = [[NSDictionary alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Statuses" ofType:@"plist"]];
   saveDestination = @"";
   upperStatus = @"";
   return self;
   
}

-(NSString*)updateStatus :(int)status : (NSString*) msg
{
   NSString* tmp = @"";
   switch (status) {
      case sc_IDLE:
         if (settings.cbKeyHook) {
            tmp = [statuses objectForKey:@"cm_HOOK_REC_INACTIVE"];

         } else {
            tmp = [statuses objectForKey:@"cm_NOHOOK_REC_INACTIVE"];
         }
         break;
      case sc_RECORDING:
            tmp = [statuses objectForKey:@"cm_REC_ACTIVE"];
         break;
      case sc_SAVING:
            tmp = [statuses objectForKey:@"cm_REC_SAVE"];
         break;
      case sc_SAVED:
            tmp = [statuses objectForKey:@"im_REC_SAVE_SUCCESS"];
         break;
      case sc_DONT_CHANGE:
            tmp = currentStatus;
         break;
      default:
            tmp = [NSMutableString stringWithString: @""];
         break;
   }
   if ([msg  isEqual: @""]) {
      upperStatus = [NSString stringWithFormat:@"%@ %@",tmp,saveDestination];
   } else {
      upperStatus = [NSString stringWithFormat:@"%@ %@",tmp,msg];
   }
   return upperStatus;
}


-(bool) displayAlert : (int)alertType globalStatus: (BOOL) flagState alertText: (NSString *) alTxt
{
   NSLog(@"AlertManager::Triggering alert %d, flagstate %d",alertType,flagState);

   if (flagState ) {
      NSString * notificationText = [NSString stringWithString:alTxt] ;
      NSString * alertTitle;
      switch (alertType) {
         case al_SAVING_MOVIE:
            alertTitle = @"SimpleStudio: Saving movie";
            break;
         case al_STARTING_RECORDING:
            alertTitle = @"SimpleStudio: Starting recording to file";
            break;
         case al_UNABLE_TO_CREATE_MOVIE:
            alertTitle = @"SimpleStudio: Unable to create movie";
            break;
         case al_RECORDING_FINISHED:
            alertTitle =@"SimpleStudio: Recording finished.";
            break;
         case al_CONNECTING_TO_FTP:
            alertTitle = @"SimpleStudio: Connecting to ftp server";
            break;
         case al_NEW_RECORD:
            alertTitle = @"SimpleStudio: Waiting for new recording";
            break;
         default:
            //this is for the security issues. If you'll call the IBAction from button without or wrong tag f.e.

            NSLog(@"AlertManager::Failed to trigger alert, type is %d",alertType);
            return false;
            break;
      }
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = alertTitle;
      notification.informativeText = notificationText;
      notification.soundName = NSUserNotificationDefaultSoundName;
      
      dispatch_async(dispatch_get_main_queue(), ^{

         [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
      });
   }
   return true;
}


@end
