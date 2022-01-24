//
//  CSSettingsManager.h
//  SimpleStudio
//
//  Created by centurion on 12/3/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
enum recordModes
{
   rm_CAMERA = 1,
   rm_SCREEN = 2,
   rm_PIP = 3,
   rm_FULL_SCREEN = 4
};


@interface CSSettingsManager : NSObject
{
   NSUserDefaults *prefs;
}

//@property (retain) NSArray * videoDevices;
//@property (retain) NSArray * audioDevices;

@property (assign) NSPoint *controlViewPosition;
@property (assign) NSPoint *cameraViewOnScreenPosition;
@property (readwrite,strong) NSString *selectedVideoDeviceName;
@property (readwrite,strong) NSString *selectedAudioDeviceName;
@property (assign) NSString *selectedPreset;
@property (readwrite) BOOL cbSaveToFlash;
@property (readwrite) BOOL cbCopyToFTP;
@property (readwrite) BOOL cbLoadOnStart;
@property (readwrite) BOOL cbDisplayAlerts;
@property (readwrite) BOOL cbFullScreenRecord;
@property (readwrite) BOOL cbKeyHook;

@property (assign) NSString *ftpUname;
@property (assign) NSString *ftpPasswd;
@property (assign) NSString *ftpAddress;
@property (readwrite,assign) NSString *tmpFilePath;

-(void) saveDefaults;
- (void) loadDefaults;
-(NSString*)getValidPathOnStart : (NSString*) pathToValidate;


@end
