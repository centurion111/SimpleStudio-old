//
//  CalertManager.h
//  SimpleStudio
//
//  Created by centurion on 11/15/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSettingsManager.h"

//NSString* const cm_HOOK_REC_ACTIVE = @"Press record button or space key to start recording";
//NSString* const cm_NOHOOK_REC_INACTIVE = @"Press record button or space key to start recording";

//Statuses consts


@interface CStatusManager : NSObject
{
   NSString * currentStatus;
}

@property (readwrite) NSDictionary * statuses;

@property (readwrite) NSString * upperStatus;
@property (readwrite) NSString * saveDestination;

@property (readwrite) CSSettingsManager* settings;
enum alerts
{
   al_SAVING_MOVIE = 1,
   al_STARTING_RECORDING = 2,
   al_UNABLE_TO_CREATE_MOVIE = 3,
   al_RECORDING_FINISHED = 4,
   al_CONNECTING_TO_FTP = 5,
   al_SAVING_TO_FLASH =6,
   al_NEW_RECORD =7
   
};

enum statusCodes
{
   sc_DONT_CHANGE = 0,
   sc_IDLE = 1,
   sc_RECORDING =2,
   sc_SAVING = 3,
   sc_SAVED = 4
};

-(bool) displayAlert : (int)alertType globalStatus: (BOOL) flagState alertText: (NSString *) alTxt;
-(NSString*)updateStatus :(int)status : (NSString*) msg;
@end
