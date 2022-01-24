//
//  AppController.m
//  SimpleStudio
//
//  Created by centurion on 11/10/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "AppController.h"
#import <CoreLocation/CoreLocation.h>


@implementation AppController{

   NSSize camera_prvSZ;
   NSSize ctrlSZ;
   NSSize camera_winSZ;
   EventHotKeyRef spaceHotKeyRef;
   EventHotKeyRef escHotKeyRef;

   int cGuiMode;
   bool videoDeviceReady;
   NSFileManager *fileManager;
   FMServer* server;
   FTPManager* man;
   BOOL succeeded;
   CSCopyPath *activeTask;
   NSTimer * copyTimer;
   dispatch_queue_t serialQueue;
   dispatch_queue_t cpUiQueue;

   BOOL fsBtnTrigger;
}

// Properties that don't need to be seen by the outside world.

@synthesize previewView;
@synthesize session;
@synthesize screenCaptureSession;
@synthesize videoDeviceFormat;
@synthesize audioDeviceFormat;
@synthesize captureScreenInput;
@synthesize devCtrl;
//@synthesize ftpCtrl;
@synthesize availableSessionPresets;
@synthesize ckBSaveToFlash;
@synthesize ckBDisplayAlerts;
@synthesize ckBFullScreenDuringRecord;
@synthesize ckBLoadOnStart;
@synthesize ckBCopyToFtp;
@synthesize modeSelector;
@synthesize ckbKeyHook;
@synthesize aControlView;
@synthesize FSControlView;
@synthesize audioDeviceInput;
@synthesize videoDeviceInput;
@synthesize selectedAudioDevice;
@synthesize selectedVideoDevice;
@synthesize videoDevices;
@synthesize audioDevices;
@synthesize hasRecordingDevice;
@synthesize selectedVideoDeviceProvidesAudio;
@synthesize recording;
@synthesize RecordMenuItem;

bool isRecording = false;

static AppController * sharedAppController = nil;

+ (id) allocWithZone:(NSZone *)zone
{
   return [self sharedInstance];
}

- (id) copyWithZone:(NSZone*)zone
{
   return self;
}

+ (AppController*) sharedInstance
{
   if (sharedAppController == nil)
      {
         sharedAppController = [[super allocWithZone:NULL] init];
      }
   return sharedAppController;
}

+ (AppController *)getInstance
{
   
   @synchronized(self)
   {
   if (sharedAppController == nil)
      {
         sharedAppController = [[super allocWithZone:NULL] init];
      }
   }
   
   return sharedAppController;
}

+ (NSSet *)keyPathsForValuesAffectingAvailableSessionPresets
{
   return [NSSet setWithObjects:@"selectedVideoDevice", @"selectedAudioDevice", nil];
}


- (instancetype)initOnStart
{
   [FSControlView setHidden:YES];

   camera_prvSZ = NSMakeSize(550, 431);
   ctrlSZ = NSMakeSize(550, 168);
   camera_winSZ = NSMakeSize(550,599);
   //cpView = [[CSCopyView alloc]init];
   self = [super init];
   if (! self) return nil;
   devCtrl = [[CDeviceManager alloc]singleInit];
   licCtrl = [[LicensingController alloc] initWithWindowNibName:@"LicensingController"];
   alertMgr = [[CStatusManager alloc]init];
   settingsMgr = [[CSSettingsManager alloc]init];
   fileManager = [NSFileManager defaultManager];
   [alertMgr setSettings:settingsMgr];
   storedMainViewRect = [mainView frame];
   self.session = [[AVCaptureSession alloc] init];
   self.screenCaptureSession = [[AVCaptureSession alloc] init];
   serialQueue = dispatch_queue_create("com.simplerecstudio.queue", DISPATCH_QUEUE_SERIAL);
   cpUiQueue = dispatch_queue_create("com.simplerecstudioUI.queue", DISPATCH_QUEUE_CONCURRENT);
   [self loadDefaults];
   [self toggleCopyToFtp:nil];
   // Capture Notification Observers
   NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
   id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                             object:session
                                                              queue:[NSOperationQueue mainQueue]
                                                         usingBlock:^(NSNotification *note) {
                                                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                               [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
                                                            });
                                                         }];
   id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                object:session
                                                                 queue:[NSOperationQueue mainQueue]
                                                            usingBlock:^(NSNotification *note) {
                                                               [self updatePreset];
                                                               NSLog(@"did start running");
                                                            }];
   id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                               object:session
                                                                queue:[NSOperationQueue mainQueue]
                                                           usingBlock:^(NSNotification *note) {
                                                              NSLog(@"did stop running");
                                                           }];
   id deviceWasConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                                                   object:nil
                                                                    queue:[NSOperationQueue mainQueue]
                                                               usingBlock:^(NSNotification *note) {
                                                                  [self devicesDidChange:note];
                                                               }];
   id deviceWasDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
                                                                      object:nil
                                                                       queue:[NSOperationQueue mainQueue]
                                                                  usingBlock:^(NSNotification *note) {
                                                                     [self devicesDidChange:note];
                                                                  }];
   
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeErrorDidOccur:) name:AVCaptureSessionRuntimeErrorNotification object:self.screenCaptureSession];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ftpUploadDidFinish:) name:@"ftpUploadFinished" object:self.ftpCtrl];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copyProcessDidStart:) name:@"cpProcessStarted" object:self.ftpCtrl];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copyProcessDidEnd:) name:@"cpProcessFinished" object:self.ftpCtrl];
   

   observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, didStartRunningObserver, didStopRunningObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver, nil];
   [self refreshDevices];

   // Attach preview to session
   NSLog(@"%@",[DateFormatter stringFromDate:[NSDate date]]);
   immgRecInactive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"status_rec_inactive" ofType:@"png"]];
   immgRecActive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"status_rec_active" ofType:@"png"]];
   immgBtnActive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"activeBtnBg" ofType:@"png"]];
   if ([settingsMgr cbKeyHook]) {
      [self registerSpaceHook];
   }
   ftpctrl = [[CSFtpController alloc]init];
   isRecording = false;
   pathsForCPF = [[NSMutableArray alloc]init];
   //Program should allways start in camera mode
   [self switchGuiModeTo:rm_CAMERA];
   [alertMgr updateStatus:sc_IDLE:@""];
   [aControlView updateValueTo:[alertMgr upperStatus] withColor:[aControlView txtColor] toTextField:[aControlView statusLabel]];
   [FSControlView updateValueTo:[alertMgr upperStatus] withColor:[FSControlView txtColor] toTextField:[FSControlView statusLabel]];
   [FSControlView updateValueTo:@"Press Esc to exit FullScreen" withColor:[FSControlView txtColor] toTextField:[FSControlView bottomStatusLabel]];

   [aControlView updateValueTo:@"00:00:00" withColor:[aControlView txtColor] toTextField:[aControlView timerLabel]];
   [FSControlView updateValueTo:@"00:00:00" withColor:[FSControlView txtColor] toTextField:[FSControlView timerLabel]];
   DateFormatter = [[NSDateFormatter alloc] init];
   [DateFormatter setDateFormat:@"hh:mm:ss"];
   fsBtnTrigger = YES;
   [aControlView hideCopyUI];
   audioLevelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateAudioLevels:) userInfo:nil repeats:YES];
   storedPreviewViewRect = [previewView frame];
   currentDisplay = CGMainDisplayID();
   return [AppController getInstance];
}


//make sure that refresh devices stands before
-(void) loadDefaults
{
   @try {
      [settingsMgr loadDefaults];

       NSFileManager *fileManager = [[NSFileManager alloc] init];
       NSString * tmpFilePath = [settingsMgr tmpFilePath];
       BOOL exists = [fileManager fileExistsAtPath:tmpFilePath];
       if (!exists) {
           tmpFilePath = [fileManager URLsForDirectory:NSDownloadsDirectory inDomains: NSUserDomainMask][0].path;
       }
       [tmpPathField setStringValue:tmpFilePath];
      [ckBSaveToFlash setState:[settingsMgr cbSaveToFlash]];
      [ckBDisplayAlerts setState:[settingsMgr cbDisplayAlerts]];
      [ckBFullScreenDuringRecord setState:[settingsMgr cbFullScreenRecord]];
      [ckBLoadOnStart setState:[settingsMgr cbLoadOnStart]];
      [ckbKeyHook setState:[settingsMgr cbKeyHook]];
      [ckBCopyToFtp setState:[settingsMgr cbCopyToFTP]];
      [ftpAddressField setStringValue:[settingsMgr ftpAddress]];
      [ftpUnameField setStringValue:[settingsMgr ftpUname]];
      [ftpPasswdField setStringValue:[settingsMgr ftpPasswd]];

      for (int i=0;i<[audioDevices count];++i)
         {
            selectedAudioDevice = [audioDevices objectAtIndex:i];
            [audioDevSelector selectItemAtIndex:i];
            if ([[selectedAudioDevice localizedName] isEqualToString:[settingsMgr selectedAudioDeviceName]]) {
            return;
            }
         }
      for (int i=0;i<[videoDevices count];++i)
         {
            selectedVideoDevice = [videoDevices objectAtIndex:i];
            [videoDevSelector selectItemAtIndex:i];
            if ([[selectedVideoDevice localizedName] isEqualToString:[settingsMgr selectedVideoDeviceName]]) {
               return;
            }
         }
   }
   @catch (NSException * e) {
      NSLog(@"LoadDefaults::Exception: %@", e);
      
   }
}


-(void) saveDefaults
{
   [settingsMgr setSelectedVideoDeviceName:[[self selectedVideoDevice]localizedName]];
   [settingsMgr setSelectedAudioDeviceName:[[self selectedAudioDevice]localizedName]];
   [settingsMgr setSelectedPreset:[session sessionPreset]];
   [settingsMgr setFtpAddress:[NSString stringWithString:ftpAddressField.stringValue]];
   [settingsMgr setFtpUname:[NSString stringWithString:ftpUnameField.stringValue]];
   [settingsMgr setFtpPasswd:[NSString stringWithString:ftpPasswdField.stringValue]];

   [settingsMgr setTmpFilePath:[NSString stringWithString:tmpPathField.stringValue]];
   [settingsMgr saveDefaults];
}

//------------------------------------------
-(void) disableFtpUI
//------------------------------------------
{
   [ftpAddressField setEnabled:NO];
   [ftpPasswdField setEnabled:NO];
   [ftpUnameField setEnabled:NO];
   
}

//------------------------------------------
-(void) enableFtpUI
//------------------------------------------
{
   [ftpAddressField setEnabled:YES];
   [ftpPasswdField setEnabled:YES];
   [ftpUnameField setEnabled:YES];
}



OSStatus spaceHookHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData) {
   NSLog(@"The space key was pressed.");
   if (isRecording) {
      [[AppController getInstance] stopRecord];
      isRecording = false;
   }
   else
      {
         [[AppController getInstance] runRecord];
      }
   return noErr;
}

-(void) registerSpaceHook
{
   NSLog(@"AppController::RegisterSpaceHook");
   EventHotKeyID gMyHotKeyID;
   EventTypeSpec eventType;
   eventType.eventClass=kEventClassKeyboard;
   eventType.eventKind=kEventHotKeyPressed;
   InstallApplicationEventHandler(&spaceHookHandler, 1, &eventType, NULL, NULL);
   gMyHotKeyID.signature='rml1';
   gMyHotKeyID.id=1;
   RegisterEventHotKey(kVK_Space, 0, gMyHotKeyID,GetApplicationEventTarget(), 0, &spaceHotKeyRef);
}

-(void) unRegisterSpaceHook
{
   NSLog(@"AppController::unRegisterSpaceHook");
   UnregisterEventHotKey(spaceHotKeyRef);
}

OSStatus escHookHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData) {
   NSLog(@"The esc key was pressed.");
   [[AppController getInstance]enterFullScreen];
   [[AppController getInstance]unRegisterEscHook];
   return noErr;
}

-(void) registerEscHook
{
   NSLog(@"AppController::registerEscHook");
   EventHotKeyID gMyHotKeyID;
   EventTypeSpec eventType;
   eventType.eventClass=kEventClassKeyboard;
   eventType.eventKind=kEventHotKeyPressed;
   InstallApplicationEventHandler(&escHookHandler, 1, &eventType, NULL, NULL);
   gMyHotKeyID.signature='rml1';
   gMyHotKeyID.id=1;
   RegisterEventHotKey(kVK_Escape, 0, gMyHotKeyID,GetApplicationEventTarget(), 0, &escHotKeyRef);
}

-(void) unRegisterEscHook
{
   NSLog(@"AppController::unRegisterEscHook");
   UnregisterEventHotKey(escHotKeyRef);
}



- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
   // Do nothing
}

-(void) stopRecord
{
   NSLog(@"AppController::StopRecord to file %@",movieFileOutput);
   @try{
   if ([settingsMgr cbKeyHook])
      {
      [self unRegisterSpaceHook];
      }
   isRecording = false;
   [movieFileOutput stopRecording];
   }
   @catch (NSException * e) {
      NSLog(@"AppController::StopRecord::Exception: %@", e);
   }
   
   [alertMgr displayAlert:al_RECORDING_FINISHED globalStatus:[settingsMgr cbDisplayAlerts] alertText: settingsMgr.tmpFilePath];
   if (cGuiMode == rm_PIP) {
     // [exitPipWindow orderOut:self];
      [self switchGuiModeTo:rm_CAMERA];
   }

   [aControlView updateValueTo:[alertMgr updateStatus:sc_SAVED:@""] withColor:[aControlView txtColor] toTextField:[aControlView statusLabel]];
   [recordingTimer invalidate];
   [recordingButton setImage:immgRecInactive];
   [fsRecBtn setImage:immgRecInactive];
   
   [aControlView updateValueTo:@"00:00:00" withColor:[aControlView txtColor] toTextField:[aControlView timerLabel]];
   [audioLevelMeter setFloatValue:0];
   NSString* theFileName = [crFileName lastPathComponent];
   NSString *dstPath;
   CSCopyPath* cPath;
   int jobType=0;
   
   if ([settingsMgr cbCopyToFTP]) {
      dstPath = [self makeFtpPath:theFileName];
      jobType = cp_FTP;
      cPath = [[CSCopyPath alloc]initWithParams:crFileName :dstPath :jobType];
      //    CSCopyPath* cPath = [[CSCopyPath alloc]initWithParams:@"/Users/centurion/Desktop/File-06-04-2015-23-57-59.mov" :@"file:///Volumes/UNTITLED/File-06-04-2015-23-57-59.mov" :0];
      [pathsForCPF addObject:cPath];
   }
   if ([settingsMgr cbSaveToFlash]&& [devCtrl getCounOfUsbDevices]>0)
      {
         dstPath = [NSString stringWithFormat:@"%@%@",[devCtrl generateSaveToFlashPath],theFileName];
         jobType = cp_USB;
         cPath = [[CSCopyPath alloc]initWithParams:crFileName :dstPath :jobType];
         [pathsForCPF addObject:cPath];
      }
      void (^cpBlock)(void);

      fTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateCpStatus:) userInfo:nil repeats:YES];
   
      cpBlock = ^{
         [[NSNotificationCenter defaultCenter] postNotificationName:@"cpProcessStarted" object:self];
         NSLog(@"Copy loop iteration");
         while ([pathsForCPF count]>0)
            {
            NSLog(@"Copy loop iteration");
            @try{
               CSCopyPath* tmp= [pathsForCPF objectAtIndex:0];
               if ( tmp.type == cp_FTP )
                  {
                     [self copyToFtp];
                  } else
                     [self copyToUsbDrive];
               }
            @catch (NSException * e) {
                  NSLog(@"CopyProcess Exception: %@", e);
               }
            }
         [[NSNotificationCenter defaultCenter] postNotificationName:@"cpProcessFinished" object:self];


      };
      
      if ([settingsMgr cbSaveToFlash]||[settingsMgr cbCopyToFTP]) {
         NSLog(@"Dispatching copy to ftp action");
         dispatch_async(serialQueue,cpBlock);

         }
   
   [modeSelector setEnabled:YES];
   if ([settingsMgr cbKeyHook])
   {
      [self registerSpaceHook];
   }


}



-(void) runRecord
{
   [self saveDefaults];
   if ([settingsMgr cbFullScreenRecord])
      {
         if (rm_CAMERA == cGuiMode )
         [self enterFullScreen];
      }
   NSLog(@"AppController::RunRecord");
   NSLog(@"RunRecord selected devices: \n audio: %@ \n video: %@",[self selectedAudioDevice],[self  selectedVideoDevice]);
   NSLog(@"RunRecord selected devices: \n audio: %@ \n video: %@",[self selectedAudioDevice],[self  selectedVideoDevice]);

   isRecording = true;
   [aControlView updateValueTo:[alertMgr updateStatus:sc_RECORDING:@""] withColor:[aControlView txtColor] toTextField:[aControlView statusLabel]];
   
   [recordingButton setImage:immgRecActive];
   [fsRecBtn setImage:immgRecActive];
   recordingStartTime = [NSDate date];
   if ((rm_PIP == cGuiMode) || (rm_CAMERA == cGuiMode)|| (rm_FULL_SCREEN == cGuiMode))
      [self.session startRunning];
   if ((rm_PIP == cGuiMode) || (rm_SCREEN == cGuiMode))
      [self.screenCaptureSession startRunning];
   NSString * tmpName = [AppController generateFileNameWithExtension:@".mov"];
   NSString * fullName;
   fullName =  [NSString stringWithFormat:@"%@/%@", [settingsMgr tmpFilePath],tmpName];
   [alertMgr setSaveDestination:fullName];
    
   [movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:fullName] recordingDelegate:self];
   crFileName = fullName;

   NSLog(@"AppController::RunRecord Recording the file to %@", fullName);

   recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateRecordingTime:) userInfo:nil repeats:YES];

   [alertMgr displayAlert:al_STARTING_RECORDING globalStatus:[settingsMgr cbDisplayAlerts] alertText: tmpName];
  // [mCaptureMovieFileOutput recordToOutputFileURL:[NSURL fileURLWithPath:@"/Users/Shared/My Recorded Movie.mov"]];
   [modeSelector setEnabled:NO];//screen

}

-(IBAction) setSavePath :(NSButton *)sender
{
   
   // Create the File Open Dialog class.
   NSOpenPanel* openDlg = [NSOpenPanel openPanel];
   
   // Enable the selection of files in the dialog.
   [openDlg setCanChooseFiles:NO];
   
   // Multiple files not allowed
   [openDlg setAllowsMultipleSelection:NO];
   
   // Can't select a directory
   [openDlg setCanChooseDirectories:YES];
   
   // Display the dialog. If the OK button was pressed,
   // process the files.
   if ( [openDlg runModal] == NSOKButton )  // See #1
      {
      for( NSURL* URL in [openDlg URLs] )  // See #2, #4
         {
         
         NSLog( @"AppController::SetSavePath selecting %@", [URL path] );      // See #3
         [settingsMgr setTmpFilePath:[NSString stringWithString:[URL path]]];
         
         [tmpPathField setStringValue:[NSString stringWithString:[URL path]]];

         }
      }
   [self saveDefaults];
   [tmpPathField setStringValue:[settingsMgr tmpFilePath]];
   NSLog(@"AppController::setSavePath newPath = %@",[settingsMgr tmpFilePath]);
   
   
}


- (void)awakeFromNib
{
   [previewView.window setMovableByWindowBackground:YES];
   
}

// Handle window closing notifications for your device input

- (void)windowWillClose:(NSNotification *)notification
{
   @try {
      [session stopRunning];
   }
   @catch (NSException * e) {
      NSLog(@"Exception: %@", e);
      [session commitConfiguration];
   }

   [self saveDefaults];
   [NSApp terminate:self];

}

    
    
//--------------------------------------------------------------------------
//Generate the name from current date and time
+ (NSString*)generateFileNameWithExtension:(NSString *)extensionString
//--------------------------------------------------------------------------
{
   NSDate *time = [NSDate date];
   NSDateFormatter* df = [NSDateFormatter new];
   [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
   NSString *timeString = [df stringFromDate:time];
   NSString * tmpTimeStr = [timeString stringByReplacingOccurrencesOfString:@":" withString:@"-"];
   NSString *fileName = [NSString stringWithFormat:@"File-%@%@", tmpTimeStr, extensionString];
   
   return fileName;

}

-(void)updateRecordingTime:(NSTimer * ) timer
{
   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
   [dateFormatter setDateFormat:@"HHmmss"];
   
   NSDate *ct = [NSDate date];
   
   NSTimeInterval diff = [ct timeIntervalSinceDate:recordingStartTime]; // diff = 3600.0
   [aControlView updateValueTo:[self stringFromTimeInterval:diff] withColor:[aControlView txtColor] toTextField:[aControlView timerLabel]];
   [FSControlView updateValueTo:[self stringFromTimeInterval:diff] withColor:[aControlView txtColor] toTextField:[FSControlView timerLabel]];

}

- (void)updateAudioLevels:(NSTimer *)timer
{
   NSInteger channelCount = 0;
   float decibels = 0.f;
   // Sum all of the average power levels and divide by the number of channels
   for (AVCaptureConnection *connection in [ movieFileOutput connections]) {
      for (AVCaptureAudioChannel *audioChannel in [connection audioChannels]) {
         decibels += [audioChannel averagePowerLevel];
         channelCount += 1;
      }
   }
   
   decibels /= channelCount;
   float val = (pow(10.f, 0.05f * decibels) * 20.0f);
   [[aControlView indicator]setFloatValue:val];
   [[FSControlView indicator]setFloatValue:val];
}


- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
   NSInteger ti = (NSInteger)interval;
   NSInteger seconds = ti % 60;
   NSInteger minutes = (ti / 60) % 60;
   NSInteger hours = (ti / 3600);
   return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}




-(IBAction) recordButtonPress :(id)sender
{
   if (isRecording) {
      [self.RecordMenuItem setTitle:@"Start Recording"];
      [self stopRecord];
   }
   else
      {
         [self.RecordMenuItem setTitle:@"Stop Recording"];
         [self runRecord];
      }
}

- (void)devicesDidChange:(NSNotification *)notification
{
   NSLog(@"AppController::devicesDidChange");
   NSLog(@"video: %@, \nAudio: %@",selectedVideoDevice,selectedAudioDevice);
   [self refreshDevices];
   [self reconfigureSessions];
}

+ (NSSet *)keyPathsForValuesAffectingVideoDeviceFormat
{
   return [NSSet setWithObjects:@"selectedVideoDevice.activeFormat", nil];
}

- (AVCaptureDeviceFormat *)videoDeviceFormat
{
   return [[self selectedVideoDevice] activeFormat];
}

/* Add a display as an input to the capture session. */
-(AVCaptureScreenInput *)addDisplayInputToCaptureSession //cropRect:(CGRect)cropRect
{
   /* Indicates the start of a set of configuration changes to be made atomically. */
   [self.screenCaptureSession beginConfiguration];
   AVCaptureScreenInput *newScreenInput;
   /* Is this display the current capture input? */
   #define MAX_DISPLAYS (3) /* or whatever you want */
   
   NSRect winRect = [[self window] frame];
   CGRect cgWinRect = (CGRect){NSMinX(winRect), NSMinY(winRect), NSWidth(winRect), NSHeight(winRect)};
   CGDirectDisplayID displays=0;
   CGDisplayCount displayCount;
   
   
   CGGetDisplaysWithRect( cgWinRect,MAX_DISPLAYS, &displays, &displayCount);

   /* Display is not the current input, so remove it. */
   [self.screenCaptureSession removeInput:self.captureScreenInput];
   newScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:displays];
   
   self.captureScreenInput = newScreenInput;
   NSLog(@"AppCOntroller::addDisplayInputToCaptureSession Current display is: %u",displays);
   if ( [self.screenCaptureSession canAddInput:self.captureScreenInput] )
   {
      /* Add the new display capture input. */
      [self.screenCaptureSession addInput:self.captureScreenInput];
  }
 //  [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];

   /* Set the bounding rectangle of the screen area to be captured, in pixels. */
 //  [self.captureScreenInput setCropRect:cropRect];
   
   /* Commits the configuration changes. */
   [self.screenCaptureSession commitConfiguration];
   return newScreenInput;
}



- (NSArray *)availableSessionPresets
{
   NSArray *allSessionPresets = [NSArray arrayWithObjects:
                                 AVCaptureSessionPresetLow,
                                 AVCaptureSessionPresetMedium,
                                 AVCaptureSessionPresetHigh,
                                 AVCaptureSessionPreset320x240,
                                 AVCaptureSessionPreset352x288,
                                 AVCaptureSessionPreset640x480,
                                 AVCaptureSessionPreset960x540,
                                 AVCaptureSessionPreset1280x720,
                                 AVCaptureSessionPresetPhoto,
                                 nil];
   
   NSMutableArray *mAvailableSessionPresets = [NSMutableArray arrayWithCapacity:9];
   for (NSString *sessionPreset in allSessionPresets) {
      if ([[self session] canSetSessionPreset:sessionPreset])
         [mAvailableSessionPresets addObject:sessionPreset];
   }
   
   return mAvailableSessionPresets;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
   NSLog(@"Did start recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
   NSLog(@"Did pause recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
   NSLog(@"Did resume recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections dueToError:(NSError *)error
{
   dispatch_async(dispatch_get_main_queue(), ^(void) {
      [self presentError:error];
   });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)recordError
{
   NSLog(@"Did finish recording to %@", outputFileURL);

   if (recordError != nil && [[[recordError userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue] == NO) {
      [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
      dispatch_async(dispatch_get_main_queue(), ^(void) {
         [self presentError:recordError];
      });
   } else {
     // Move the recorded temporary file to a user-specified location
      NSURL * savePathUrl = [NSURL URLWithString:[settingsMgr tmpFilePath]];
      NSError * error = nil;
     // [[NSFileManager defaultManager] removeItemAtURL:savePathUrl error:nil]; // attempt to remove file at the desired save location before moving the recorded file to that location
      if ([[NSFileManager defaultManager] moveItemAtURL:outputFileURL toURL:savePathUrl error:&error]) {
            [[NSWorkspace sharedWorkspace] openURL:savePathUrl];
            }
          else {
            // remove the temporary recording file if it's not being saved
            //[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
         }
      
   }
}

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput
{
   // We don't require frame accurate start when we start a recording. If we answer YES, the capture output
   // applies outputSettings immediately when the session starts previewing, resulting in higher CPU usage
   // and shorter battery life.
   return NO;
}

- (IBAction)enterFullScreen:(id)sender
{
   [self enterFullScreen];
}

- (void)enterFullScreen
{
   fsBtnTrigger = NO;
   NSDictionary *fullScreenOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:NSFullScreenModeAllScreens   ];
   
   if (rm_FULL_SCREEN != cGuiMode) {
      [toggleSettingsButton setEnabled:NO];
      [modeSelector setEnabled:NO];
      storedPreviewViewRect = [previewView frame];

      [self setGuiModeTo:rm_FULL_SCREEN];
      NSRect screenRect = [[NSScreen mainScreen] frame];
      storedMainViewRect = mainView.frame;
      NSLog (@"AppController::enterFullScreen, gui mode set to %d",cGuiMode);
      //NSLog(@"screen x = %f", screenRect.size.width );
      //NSLog(@"screen y = %f", screenRect.size.height );
      //NSLog(@"origin x = %f", screenRect.origin.x );
      //NSLog(@"origin y = %f", screenRect.origin.y );
      [self.window setFrame:screenRect display:YES animate:YES];

      [mainView enterFullScreenMode:[NSScreen mainScreen] withOptions:fullScreenOptions];
      [previewView setFrame:self.window.contentView.frame];
      [previewView addSubview:FSControlView positioned:NSWindowAbove relativeTo:nil];
      [previewView setNeedsDisplay:YES];
      [previewView display];
      [aControlView setHidden:YES];
      [FSControlView setHidden:NO];
      [FSControlView setNeedsDisplay:YES];
      [FSControlView display];
      [mainView setNeedsDisplay:YES];
      [mainView display];
      NSLog(@"Entering FullScreen");
      NSLog(@"MainWindow screen x = %f", self.window.frame.size.width );
      NSLog(@"MainWindow screen y = %f", self.window.frame.size.height );
      NSLog(@"MainWindow origin x = %f", self.window.frame.origin.x );
      NSLog(@"MainWindow origin y = %f", self.window.frame.origin.y );
      NSLog(@"MainView  x = %f", self.window.contentView.frame.size.width );
      NSLog(@"MainView  y = %f", self.window.contentView.frame.size.height );
      NSLog(@"MainView origin x = %f", self.window.contentView.frame.origin.x );
      NSLog(@"MainView origin y = %f", self.window.contentView.frame.origin.y );
      NSLog(@"PreviewView screen x = %f", previewView.frame.size.width );
      NSLog(@"PreviewView screen y = %f", previewView.frame.size.height );
      NSLog(@"PreviewView origin x = %f", previewView.frame.origin.x );
      NSLog(@"PreviewView origin y = %f", previewView.frame.origin.y );
      [self registerEscHook];
   } else {
      NSLog(@"AppController::EnterFullScreen: exiting fullScreen");
      if(self.isFullScreen) {
         [self.window toggleFullScreen:nil];
      }

      [toggleSettingsButton setEnabled:YES];
      [modeSelector setEnabled:YES];
     // [controlView removeFromSuperview];
      [mainView exitFullScreenModeWithOptions:fullScreenOptions];
      [mainView setFrame:storedMainViewRect];
      [previewView setFrame:storedPreviewViewRect];
      [self setGuiModeTo:rm_CAMERA];
      [self guiModeToCamera];
      [aControlView setHidden:NO];
      [FSControlView setHidden:YES];
      [aControlView display];
      fsBtnTrigger = YES;
      NSLog(@"Exiting FullScreen");
      NSLog(@"MainWindow screen x = %f", self.window.frame.size.width );
      NSLog(@"MainWindow screen y = %f", self.window.frame.size.height );
      NSLog(@"MainWindow origin x = %f", self.window.frame.origin.x );
      NSLog(@"MainWindow origin y = %f", self.window.frame.origin.y );
      NSLog(@"MainView  x = %f", self.window.contentView.frame.size.width );
      NSLog(@"MainView  y = %f", self.window.contentView.frame.size.height );
      NSLog(@"MainView origin x = %f", self.window.contentView.frame.origin.x );
      NSLog(@"MainView origin y = %f", self.window.contentView.frame.origin.y );
      NSLog(@"PreviewView screen x = %f", previewView.frame.size.width );
      NSLog(@"PreviewView screen y = %f", previewView.frame.size.height );
      NSLog(@"PreviewView origin x = %f", previewView.frame.origin.x );
      NSLog(@"PreviewView origin y = %f", previewView.frame.origin.y );
      [self unRegisterEscHook];


   }
  

}

+ (NSSet *)keyPathsForValuesAffectingPlaying
{
   return [NSSet setWithObjects:@"selectedVideoDevice.transportControlsPlaybackMode", @"selectedVideoDevice.transportControlsSpeed",nil];
}

- (IBAction)lockVideoDeviceForConfiguration:(id)sender
{
   if ([(NSButton *)sender state] == NSOnState)
      {
      [[self selectedVideoDevice] lockForConfiguration:nil];
      }
   else
      {
      [[self selectedVideoDevice] unlockForConfiguration];
      }
}


-(IBAction)toggleDisplayAlerts:(id)sender
{
   [settingsMgr setCbDisplayAlerts:[ckBDisplayAlerts state]];
}

-(IBAction)toggleLoadOnStart:(id)sender
{
   [settingsMgr setCbLoadOnStart:[ckBLoadOnStart state]];
   [self setLaunchOnLogin:[settingsMgr cbLoadOnStart]];
   //[settingsMgr saveDefaults];

}
-(IBAction)toggleSaveToFlash:(id)sender
{
   [settingsMgr setCbSaveToFlash:[ckBSaveToFlash state]];
  // [settingsMgr saveDefaults];
}
-(IBAction)toggleFullScreenRecord:(id)sender
{
   [settingsMgr setCbFullScreenRecord:[ckBFullScreenDuringRecord state]];
   //[settingsMgr saveDefaults];

}

-(IBAction)toggleKeyboardHook:(id)sender
{
   [settingsMgr setCbKeyHook:[ckbKeyHook state]];
   if ([settingsMgr cbKeyHook])
      {
         [self registerSpaceHook];
      }else
         {
            [self unRegisterSpaceHook];
         }
   [aControlView updateValueTo:[alertMgr updateStatus:sc_IDLE:@""] withColor:[aControlView txtColor] toTextField:[aControlView statusLabel]];
}

-(IBAction)toggleCopyToFtp:(id)sender
{
   [settingsMgr setCbCopyToFTP:[ckBCopyToFtp state]];
   if ([settingsMgr cbCopyToFTP])
      {
         [self enableFtpUI];
      }else
         {
            [self disableFtpUI];
         }
}

- (BOOL)launchOnLogin
{
   LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
   CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
   NSArray* loginItems = (__bridge NSArray *)(snapshotRef) ;
   NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
   for (id item in loginItems) {
      LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
      CFURLRef itemURLRef;
      if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
         NSURL *itemURL = (__bridge NSURL *)itemURLRef;
         if ([itemURL isEqual:bundleURL]) {
            return YES;
         }
      }
   }
   return NO;
}

- (void)setLaunchOnLogin:(BOOL)launchOnLogin
{
   NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
   LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
   
   if (launchOnLogin) {
      NSDictionary *properties;
      properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"MegaToolMaster.SimpleStudio"];
      LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsListRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)bundleURL, (__bridge CFDictionaryRef)properties,NULL);
      if (itemRef) {
         CFRelease(itemRef);
      }
   } else {
      LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
      CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
      NSArray* loginItems = (__bridge NSArray *)(snapshotRef) ;
      
      for (id item in loginItems) {
         LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
         CFURLRef itemURLRef;
         if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            if ([itemURL isEqual:bundleURL]) {
               LSSharedFileListItemRemove(loginItemsListRef, itemRef);
            }
         }
      }
   }
}

-(IBAction)changeGUIMode_m:(NSMenuItem*)sender
{
   [self switchGuiModeTo:roundl(sender.tag)];
}

-(IBAction)changeGUIMode:(NSSegmentedControl*)sender
{
   [self switchGuiModeTo:roundl([[sender cell] tagForSegment:[sender selectedSegment]])];
}

-(IBAction)exitPip:(NSButton*)sender
{
   [self switchGuiModeTo:roundl(sender.tag)];
}

-(void)switchGuiModeTo:(int)mode
{
   [self setGuiModeTo:mode];
   NSLog(@"AppController::toggleRecordScreen with  tag %ld",(long)mode);
   //[ckBMCamera setIsOn:NO];
   //[ckBMPIP setIsOn:NO];
   //[ckBMScreen setIsOn:NO];

   [m_cameraItem setEnabled:NO];
   [m_screenItem setEnabled:NO];
   [m_pipItem setEnabled:NO];
   if ([drawer state]== NSDrawerOpenState)
   [drawer toggle:toggleSettingsButton];
   switch (mode) {
      case rm_CAMERA:
         [modeSelector selectSegmentWithTag:rm_CAMERA];
         [m_screenItem setEnabled:YES];
         [m_pipItem setEnabled:YES];
         [self guiModeToCamera];
         break;
      case rm_PIP:
         [modeSelector selectSegmentWithTag:rm_PIP];
         [self guiModeToPIP];
         [m_cameraItem setEnabled:YES];
         break;
      case rm_SCREEN:
         [modeSelector selectSegmentWithTag:rm_SCREEN];
         [m_cameraItem setEnabled:YES];
         [self guiModeToScreen];

         break;
      case rm_FULL_SCREEN:
         break;
         
      default:
         [settingsMgr saveDefaults];
         
         NSLog(@"AppController::switchToGuiMode noSender called with wrong tag %d",cGuiMode);
         return;
         break;
   }
   //[[sender cell]setBackgroundColor:[self NSColorToCGColor:[NSColor greenColor]]];
   [self.window.contentView setWantsLayer:YES];
   
}

- (CGColorRef)NSColorToCGColor:(NSColor *)color
{
   NSInteger numberOfComponents = [color numberOfComponents];
   CGFloat components[numberOfComponents];
   CGColorSpaceRef colorSpace = [[color colorSpace] CGColorSpace];
   [color getComponents:(CGFloat *)&components];
   CGColorRef cgColor = CGColorCreate(colorSpace, components);
   
   return cgColor;
}


+ (NSSet *)keyPathsForValuesAffectingHasRecordingDevice
{
   return [NSSet setWithObjects:@"selectedVideoDevice", @"selectedAudioDevice", nil];
}


+ (NSSet *)keyPathsForValuesAffectingRecording
{
   return [NSSet setWithObject:@"movieFileOutput.recording"];
}


-(void)addMetaData
{
   NSArray *existingMetadataArray = movieFileOutput.metadata;
   NSMutableArray *newMetadataArray = nil;
   if (existingMetadataArray) {
      newMetadataArray = [existingMetadataArray mutableCopy];
   }
   else {
      newMetadataArray = [[NSMutableArray alloc] init];
   }
   
   AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
   item.keySpace = AVMetadataKeySpaceCommon;
   item.key = AVMetadataCommonKeyLocation;
   CLLocationManager *locationManager;

   CLLocation *location = [locationManager location];
   item.value = [NSString stringWithFormat:@"%+08.4lf%+09.4lf/",
                 location.coordinate.latitude, location.coordinate.longitude];
   
   [newMetadataArray addObject:item];
   
   movieFileOutput.metadata = newMetadataArray;

}

- (void)setButtonTitleFor:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color {
   NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
   [style setAlignment:NSCenterTextAlignment];
   NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    color, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
   NSAttributedString *attrString = [[NSAttributedString alloc]
                                     initWithString:title attributes:attrsDictionary];
   [button setAttributedTitle:attrString];
}

-(int)reconfigureSessions
{
   [settingsMgr setSelectedPreset:session.sessionPreset];
   [self endSession:screenCaptureSession];
   [self endSession:session];
   //main session config
   if((rm_CAMERA == cGuiMode) || (rm_PIP == cGuiMode) || (rm_FULL_SCREEN == cGuiMode))
      {
         [[self session] stopRunning];
         self.session = [[AVCaptureSession alloc] init];
         if((rm_CAMERA == cGuiMode) || (rm_FULL_SCREEN == cGuiMode))
            {
            audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
               [audioPreviewOutput setVolume:0.f];
               [session addOutput:audioPreviewOutput];
               // Attach outputs to session
               movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
               [movieFileOutput setDelegate:self];
               [session addOutput:movieFileOutput];
            }

         // Start the session
         [[self session] startRunning];
         [[self session]beginConfiguration];
         // Initial refresh of device list
         //[self refreshDevices];
         if (0 != [[settingsMgr selectedPreset] length])
            {
               [session setSessionPreset:[settingsMgr selectedPreset]];
            }
      
         // Select devices if any exist
         if (!selectedVideoDevice)
         {
            AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if (videoDevice) {
               NSLog(@"ReconfigureSessions:: will set video device to %@",videoDevice);
               [self setSelectedVideoDevice:videoDevice];
            } else {
               [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
            }
         } else
         {
            [self setSelectedVideoDevice:[videoDevices objectAtIndex:[videoDevSelector indexOfSelectedItem]]];
         }
            
         if (rm_SCREEN != cGuiMode)
         {
         if ([self selectedVideoDevice]) {
            NSError *error = nil;
            
            // Create a device input for the device and add it to the session
            AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
            if (newVideoDeviceInput == nil) {
               dispatch_async(dispatch_get_main_queue(), ^(void) {
                  [self presentError:error];
               });
            } else {
              // NSLog(@"AppController::ReconfigureSessions attaching videoinput %@ ",newVideoDeviceInput);
               if (![selectedVideoDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
                  [[self session] setSessionPreset:AVCaptureSessionPresetHigh];
            }
            [self setSelectedAudioDevice:[audioDevices objectAtIndex:[audioDevSelector indexOfSelectedItem]]];
         }
         }
         NSLog(@"Session inputs %@",session.inputs);
         [[self session]commitConfiguration];

      } // end main session config
   //screenCaptureSession config
   if((rm_SCREEN == cGuiMode) || (rm_PIP == cGuiMode))
      {
         [self.screenCaptureSession stopRunning];
         self.screenCaptureSession = [[AVCaptureSession alloc] init];
         [[self screenCaptureSession] startRunning];
         [[self screenCaptureSession]beginConfiguration];
         // Initial refresh of device list
         //[self refreshDevices];
         audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
         [audioPreviewOutput setVolume:0.f];
         // Attach outputs to session
         movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
         [movieFileOutput setDelegate:self];
      
         [screenCaptureSession addOutput:movieFileOutput];
         [screenCaptureSession addOutput:audioPreviewOutput];
         if (0 != [[settingsMgr selectedPreset] length])
            {
               [screenCaptureSession setSessionPreset:[settingsMgr selectedPreset]];
            }
      
         // Select devices if any exist
      
         [self addDisplayInputToCaptureSession];
         /* Add a movie file output + delegate. */
         movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
         [movieFileOutput setDelegate:self];
         if ([self.screenCaptureSession canAddOutput:movieFileOutput])
            {
            [self.screenCaptureSession addOutput:movieFileOutput];
            }
         else
            {
            NSLog(@"AppController::guiModeToScreen: screenCaptureSession error addig output");
            return -1;
            }
      
      
         [self setSelectedAudioDevice:[audioDevices objectAtIndex:[audioDevSelector indexOfSelectedItem]]];
         [[self screenCaptureSession]commitConfiguration];

      }
   NSLog(@"AppController::ReconfigureSessions");
   NSLog(@"Main session will start with devices: \n audio: %@ \n video: %@",[self selectedAudioDevice],[self  selectedVideoDevice]);

   return 0;
}

-(int)guiModeToCamera
{
   [self setGuiModeTo: rm_CAMERA];
   [toggleSettingsButton setEnabled:YES];
   [modeSelector setEnabled:YES forSegment:0];//screen
   [modeSelector setEnabled:YES forSegment:1];//camera
   [modeSelector setEnabled:YES forSegment:2];//pip
   [[previewView window] setStyleMask:NSTitledWindowMask|NSClosableWindowMask];
   NSPoint previewViewOrigin = mainView.frame.origin;
   previewViewOrigin.y +=  ctrlSZ.height;

   [self reconfigureSessions];
   [[previewView window] setLevel: NSNormalWindowLevel];
   NSLog(@"AppController::guiModeToCamera: initPreview %d",cGuiMode);
   NSRect wRect= [[mainView window] frame];
   wRect.size = camera_winSZ;
   [[mainView window] setFrame:wRect display:YES animate:YES];
   [previewView setHidden:NO];
   [previewView setFrameOrigin:previewViewOrigin];
   [previewView setFrameSize:camera_prvSZ];
   [aControlView setFrameOrigin:mainView.frame.origin];
   [aControlView setHidden:NO];
   CALayer *previewViewLayer;
   previewViewLayer = [[self previewView] layer];
   [[self previewView]display];
   [previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
   AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
   [newPreviewLayer setFrame:[previewViewLayer bounds]];
   [newPreviewLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
   [newPreviewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];

   [previewViewLayer addSublayer:newPreviewLayer];
   [toggleSettingsButton setEnabled:YES];
   [self.window display];
   [mainView needsDisplay];
   [aControlView display];
   [aControlView needsDisplay];
   /*

   NSLog(@"---------AppController::guiModeToCamera: afterTransform---------");
   NSLog(@"AppController::guiModeToCamera: controlViewSize %f",aControlView.frame.size.width);
   NSLog(@"MainWindow screen x = %f", self.window.frame.size.width );
   NSLog(@"MainWindow screen y = %f", self.window.frame.size.height );
   NSLog(@"MainWindow origin x = %f", self.window.frame.origin.x );
   NSLog(@"MainWindow origin y = %f", self.window.frame.origin.y );
   NSLog(@"MainView  x = %f", self.window.contentView.frame.size.width );
   NSLog(@"MainView  y = %f", self.window.contentView.frame.size.height );
   NSLog(@"MainView origin x = %f", self.window.contentView.frame.origin.x );
   NSLog(@"MainView origin y = %f", self.window.contentView.frame.origin.y );
   NSLog(@"PreviewView screen x = %f", previewView.frame.size.width );
   NSLog(@"PreviewView screen y = %f", previewView.frame.size.height );
   NSLog(@"PreviewView origin x = %f", previewView.frame.origin.x );
   NSLog(@"PreviewView origin y = %f", previewView.frame.origin.y );
   NSLog(@"AppController::guiModeToCamera: window size %f, %f",self.window.frame.size.height,self.window.frame.size.width);
 //  NSLog(@"AppController::guiModeToCamera: window size %f, %f",mainWindow.frame.size.height,mainWindow.frame.size.width);

   NSLog(@"AppController::guiModeToCamera: window from preview size %f, %f",previewView.window.frame.size.height,previewView.window.frame.size.width);
   NSLog(@"AppController::guiModeToCamera: previewView size %f, %f",previewView.frame.size.height,previewView.frame.size.width);
   NSLog(@"AppController::guiModeToCamera: content view size %f, %f",mainView.frame.size.height,mainView.frame.size.width);
*/
   return rm_CAMERA;
}

-(int)guiModeToScreen
{
   [self setGuiModeTo: rm_SCREEN];
   [modeSelector setEnabled:YES forSegment:0];//screen
   [modeSelector setEnabled:YES forSegment:1];//camera
   [modeSelector setEnabled:NO forSegment:2];//pip

   [[previewView window] setLevel: NSNormalWindowLevel];
   [toggleSettingsButton setEnabled:NO];
   [previewView setHidden:YES];
   [aControlView setHidden:NO];
   [self reconfigureSessions];
   
   NSRect wRect = [[mainView window] frame];
   wRect.size = ctrlSZ;
   [[mainView window] setStyleMask:NSBorderlessWindowMask];

   [[mainView window] setFrame:wRect display:YES animate:YES];
   [self.window display];
   [mainView needsDisplay];
   [aControlView display];

   ctrlViewInitPoint = aControlView.frame.origin;
   [aControlView setFrameOrigin:NSMakePoint(
                                       (NSWidth([mainView frame]) - NSWidth([aControlView frame])) / 2,
                                       (NSHeight([mainView frame]) - NSHeight([aControlView frame])) / 2
                                       )];
   [aControlView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];

   NSLog(@"AppController::guiModeToScreen: resized to %f",self.window.frame.size.height);
   //session config
   return rm_SCREEN;
}


-(int)guiModeToPIP
{
   NSLog(@"AppController::guiModeToPIP");
   [self setGuiModeTo: rm_PIP];

   [toggleSettingsButton setEnabled:NO];
   [modeSelector setEnabled:NO forSegment:0];//screen
   [modeSelector setEnabled:YES forSegment:1];//camera
   [modeSelector setEnabled:YES forSegment:2];//pip
   [previewView.window setStyleMask:NSBorderlessWindowMask|NSClosableWindowMask];
   [previewView setHidden:NO];
   [aControlView setHidden:YES];
   [self reconfigureSessions];

   NSRect wRect = [[mainView window] frame];
   //CGFloat n = previewView.frame.origin.y + previewView.frame.size.height - aControlView.frame.size.height ;
//   wRect.origin.y = wRect.origin.y + (wRect.size.height - n);
   wRect.size.height = camera_prvSZ.height/1.5;
   wRect.size.width = camera_prvSZ.height/1.6;
   
   [[mainView window] setFrame:wRect display:YES animate:YES];
   [[mainView window]setFrame:[mainView frame] display:YES animate:YES];

   [previewView setFrameSize:wRect.size];
   [previewView setBounds:wRect];
   [previewView needsDisplay];
   [previewView setFrameOrigin:NSMakePoint(
                                           (NSWidth([mainView frame]) - NSWidth([previewView frame])) / 2,
                                           (NSHeight([mainView frame]) - NSHeight([previewView frame])) / 2
                                           )];
   [previewView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
   [[previewView window] makeKeyAndOrderFront:nil];
   
   [[previewView window] setLevel: CGShieldingWindowLevel()];


   [self.window display];
   [mainView needsDisplay];
   [previewView display];
   
   CALayer *previewViewLayer;
   previewViewLayer = [[self previewView] layer];
   [[self previewView]setHidden:NO];

   [[self previewView]display];
   
   [previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
   AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
   [newPreviewLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
   [newPreviewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
   [newPreviewLayer setFrame:[previewView bounds]];
   [previewViewLayer addSublayer:newPreviewLayer];
   
   
   [self.window display];
   [mainView needsDisplay];
   [aControlView display];
   [aControlView needsDisplay];
   
   return rm_PIP;
}

-(void)endSession:(AVCaptureSession*)aSession
{
   @try {
      [aSession stopRunning];
      
   }
   @catch (NSException * e) {
      NSLog(@"AppController::EndSession Exception: %@", e);
      [aSession commitConfiguration];
   }
   
}

- (void)captureSessionRuntimeErrorDidOccur:(NSNotification *)notification
{
   NSLog(@"AppController::captureSessionRuntimeErrorDidOccur");
   NSError *error = [notification userInfo][AVCaptureSessionErrorKey];
   NSAlert *alert = [[NSAlert alloc] init];
   [alert setAlertStyle:NSCriticalAlertStyle];
   [alert setMessageText:[error localizedDescription]];
   NSString *informativeText = [error localizedRecoverySuggestion];
   informativeText = informativeText ? informativeText : [error localizedFailureReason]; // No recovery suggestion, then at least tell the user why it failed.
   [alert setInformativeText:informativeText];
   [alert beginSheetModalForWindow:self.window
                     modalDelegate:self
                    didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];
}

-(void) setGuiModeTo : (int)guiMode
{
   cGuiMode = guiMode;
   NSLog(@"%ld",(long)guiMode);
   [aControlView setGuiMode:guiMode];
   [FSControlView setGuiMode:guiMode];
}

-(void) updatePreset
{
   NSLog(@"AppController::updatePreset setting to %@",[session sessionPreset]);
   [settingsMgr setSelectedPreset:[session sessionPreset]];
}


/*=====================================================================
 //------------ IO devices section ------------
 =====================================================================*/


- (void)setSelectedVideoDevice:(AVCaptureDevice *)aSelectedVideoDevice
{
   
   NSLog(@"AppController::setSelectedVideoDevice = %@",aSelectedVideoDevice);
   if ([self videoDeviceInput]) {
      // Remove the old device input from the session
      [session removeInput:[self videoDeviceInput]];
      [self setVideoDeviceInput:nil];
   }
   
   if (aSelectedVideoDevice) {
      NSError *error = nil;
      // Create a device input for the device and add it to the session
      AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:aSelectedVideoDevice error:&error];
      if (newVideoDeviceInput == nil) {
         dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error];
         });
      } else {
         if (![aSelectedVideoDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
            [session setSessionPreset:[settingsMgr selectedPreset]];
         
         [session addInput:newVideoDeviceInput];
         [self setVideoDeviceInput:newVideoDeviceInput];
      }
   }
   selectedVideoDevice=aSelectedVideoDevice;
   // If this video device also provides audio, don't use another audio device
   if ([self selectedVideoDeviceProvidesAudio])
      setSelectedAudioDevice:nil;
   NSLog(@"DeviceManager::setSelectedVideoDevice = %@",aSelectedVideoDevice);
   
}


- (AVCaptureDevice *)selectedAudioDevice
{
   return [audioDeviceInput device];
}

-(BOOL)isValidVideoDevice : (NSString*) selectedDevice
{
   
   for (int i = 0 ; i < [videoDevices count ] ; i++) {
      if([[videoDevices objectAtIndex:i] name] == selectedDevice)
         return TRUE;
   }
   return FALSE;
}

-(BOOL)isValidAudioDevice : (NSString*) selectedDevice
{
   for (int i = 0 ; i < [audioDevices count ] ; i++) {
      if([[ audioDevices objectAtIndex:i] name] == selectedDevice)
         return TRUE;
      
   }
   return TRUE;
}

// should be called only within the session configuration process
- (void)setSelectedAudioDevice:(AVCaptureDevice *)aSelectedAudioDevice
{
   NSLog(@"DeviceManager::setSelectedAudioDevice trying to set audiodevice = %@",aSelectedAudioDevice);
   AVCaptureSession * aSession = session;
   if ((cGuiMode == rm_SCREEN)||(cGuiMode == rm_PIP))
      aSession = screenCaptureSession;

   if ([self audioDeviceInput]) {
      // Remove the old device input from the session
      [aSession removeInput:[self audioDeviceInput]];
      [self setAudioDeviceInput:nil];
   }
   selectedAudioDevice = aSelectedAudioDevice;
   if (selectedAudioDevice && ![self selectedVideoDeviceProvidesAudio]) {
      NSError *error = nil;
      
      // Create a device input for the device and add it to the session
      AVCaptureDeviceInput *newAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedAudioDevice error:&error];
      if (newAudioDeviceInput == nil) {
         dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error];
         });
      } else {
         if (![aSelectedAudioDevice supportsAVCaptureSessionPreset:[settingsMgr selectedPreset]])
            [ aSession setSessionPreset:[settingsMgr selectedPreset]];
         [aSession addInput:newAudioDeviceInput];
         [self setAudioDeviceInput:newAudioDeviceInput];
      }
   }
   NSLog(@"DeviceManager::setSelectedAudioDevice Session inputs = %@",aSession.inputs);
}

-(IBAction)actionChangeSelectedAudioDevice:(id)sender
{
   if (0!=[audioDevices count])
   [self setSelectedAudioDevice:[audioDevices objectAtIndex:[audioDevSelector indexOfSelectedItem]]];
   NSLog(@"actionChangeSelectedAudioDevice of selected audiodevice: %@,index: %ld",selectedAudioDevice,[audioDevSelector indexOfSelectedItem]);

}

-(IBAction)actionChangeSelectedVideoDevice:(id)sender
{
   if (0!=[videoDevices count])
   [self setSelectedVideoDevice:[videoDevices objectAtIndex:[videoDevSelector indexOfSelectedItem]]];
   NSLog(@"actionChangeSelectedVideoDevice selected videodevice: %@,index: %ld",selectedVideoDevice,[videoDevSelector indexOfSelectedItem]);

}

- (void)refreshDevices
{
   NSLog(@"AppController::refreshDevices video: %@\n, audio: %@",selectedVideoDevice,selectedAudioDevice);

   [self setVideoDevices:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]]];
   
   [self setAudioDevices:[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]];
   
   if (![videoDevices containsObject: selectedVideoDevice])
      {
      if ((0!=[videoDevices count]))
         [self setSelectedVideoDevice:videoDevices[0]];
      else
         [self setSelectedVideoDevice:nil];
      }
   if (![audioDevices containsObject: selectedAudioDevice])
      {
      if ((0!=[audioDevices count]))
         [self setSelectedAudioDevice:audioDevices[0]];
      else
         [self setSelectedAudioDevice:nil];
      }
   
   NSLog(@"AppController::refreshDevices after refresh video: %@\n, audio: %@",selectedVideoDevice,selectedAudioDevice);

   NSLog(@"AppController%@::refreshDevices",self);
   NSLog(@"videoDevices %@",[self videoDevices]);
   NSLog(@"audioDevices %@",[self audioDevices]);
}

- (BOOL)hasRecordingDevice
{
   return ((videoDeviceInput != nil) || (audioDeviceInput != nil));
}


- (AVCaptureDevice *)selectedVideoDevice
{
   return [videoDeviceInput device];
}

+ (NSSet *)keyPathsForValuesAffectingSelectedVideoDeviceProvidesAudio
{
   return [NSSet setWithObjects:@"selectedVideoDevice", nil];
}

- (BOOL)selectedVideoDeviceProvidesAudio
{
   // return ([[self selectedVideoDevice] hasMediaType:AVMediaTypeMuxed] || [[self selectedVideoDevice] hasMediaType:AVMediaTypeAudio]);
   return NO;
}

-(unsigned long long) getFileSize:(NSString*)filePath
{
   NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
   unsigned long long fileSize = [attributes fileSize]; // in bytes
   return fileSize;
}



// call this method from outside for ftp upload
-(NSString*)makeFtpPath:(NSString*)FileName
{
   NSString* res = [NSString stringWithFormat:@"%@/%@",[settingsMgr ftpAddress],FileName];
   return res;
}

-(int)copyToFtp
{
   NSLog(@"AppController::copyToFtp");
   CSCopyPath *tp = [pathsForCPF objectAtIndex:0];
   activeTask = tp;

   [pathsForCPF removeObjectAtIndex:0];
   [ftpctrl upload:tp.srcPath ftpUrl:tp.dstPath ftpUsr:[settingsMgr ftpUname] ftpPass:[settingsMgr ftpPasswd]] ;
   NSLog(@"AppController::copyToFtp. Exiting with flag ");
   return 0;
}

// call this method from outside for usb copy
-(int)copyToUsbDrive
{
   CSCopyPath *tp = [pathsForCPF objectAtIndex:0];
   activeTask = tp;
   [pathsForCPF removeObjectAtIndex:0];
   if ([devCtrl getCounOfUsbDevices]==0)
      {
         [fTimer invalidate];
      
         return 1;
      }
   NSLog(@"AppController::copyToUsbDrive: from %@ to %@", tp.srcPath, tp.dstPath);
   
   NSError *error;
   NSURL * tmpUrl = [NSURL URLWithString:tp.srcPath];
   NSURL * tmpUrlDst = [NSURL URLWithString:tp.dstPath];
   tp.srcPath = tmpUrl.path;
   tp.dstPath = tmpUrlDst.path;
   tp.srcSize = [self getFileSize:tp.srcPath];
   NSURL * tvolUrl = [NSURL URLWithString:[devCtrl generateSaveToFlashPath]];
   NSString* volumePath = tvolUrl.path;
   
   NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:volumePath
                                                                                             error:&error];
   unsigned long long freeSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
   if (tp.srcSize>freeSpace) {
      NSLog(@"AppController::copyToUsbDrive size of file is bigger than size of disk");
      [[self aControlView]updateValueTo:[NSString stringWithFormat:@"Not enough free space at %@",volumePath] withColor:[self.aControlView txtColor] toTextField:[aControlView cpStatusLabel]];
   }
   else{
      if ([fileManager fileExistsAtPath:tp.dstPath] == YES)
         {
            NSError *error = nil;
            [fileManager removeItemAtPath:tp.dstPath error:&error];
         }
         
      if(![fileManager copyItemAtPath:tmpUrl.path
                                 toPath:tmpUrlDst.path
                                 error:&error])
         {
            NSLog(@"Error copying files: %@", [error description]);
         }
      [[self aControlView]updateValueTo:[NSString stringWithFormat:@"Copying %d%% of %@",100,tp.dstPath] withColor:[self.aControlView txtColor] toTextField:[aControlView cpStatusLabel]];
      [[[self aControlView]cpPrgIndicator]setDoubleValue:100];
   }

   
   //[fTimer invalidate];
   NSLog(@"AppController::copyToFtp. Exiting with flag ");

   return 0;
}

-(void) ftpUploadDidFinish:(NSNotification *)notification
{
   NSLog(@"AppController:ftpUploadDidFinish");
  // [fTimer invalidate];
//   [aControlView hideCopyUI];
}

- (void)updateCpStatus:(NSTimer *)timer
{
   int state = 0;
   //NSLog(@"update cp status");
   if (activeTask.type == cp_USB)
      {
         unsigned long long dstSize = [self getFileSize:activeTask.dstPath]; // in bytes
         if ((dstSize!=0) && (activeTask.srcSize!=0)) {
            state = (int)(((double)dstSize/(double)activeTask.srcSize)*100);
         }
         NSString* s = [activeTask.dstPath lastPathComponent];
         // NSLog(@"CSSaveController updateCpStatus: %d", state);
         [[self aControlView]updateValueTo:[NSString stringWithFormat:@"Copying %d%% of %@",state,s] withColor:[self.aControlView txtColor] toTextField:[aControlView cpStatusLabel]];
         [[[self aControlView]cpPrgIndicator]setDoubleValue:state];
         if (state >=99)
         {
         
         [fTimer invalidate];
         sleep(1);
         [aControlView hideCopyUI] ;

         }


      }
   if (activeTask.type == cp_FTP)
      {
         NSString* s = [activeTask.dstPath lastPathComponent];
         NSNumber* progress = [[ftpctrl man].progress objectForKey:kFMProcessInfoProgress];
         double p = (100*progress.floatValue); //0.0f ≤ p ≤ 1.0f
         //NSLog(@"AppController::updateCpStatus ftp status update, copied %f",p);
         [[self aControlView]updateValueTo:[NSString stringWithFormat:@"Uploading to ftp: %@",s] withColor:[self.aControlView txtColor] toTextField:[aControlView cpStatusLabel]];

         [[[self aControlView]cpPrgIndicator]setDoubleValue:p];
      
         if (p >=99)
            {
            [fTimer invalidate];
            sleep(1);
            [aControlView hideCopyUI] ;

            }
      }
}

-(IBAction)actionCancelFileCopy:(id)sender
{
   [fTimer invalidate];

   [aControlView hideCopyUI];
}

- (void)copyProcessDidStart:(NSNotification *)notification
{
   [aControlView showCopyUI];

}

- (void)copyProcessDidEnd:(NSNotification *)notification
{
   void (^hCpUIBlock)(void);

   hCpUIBlock = ^{
      @try {
         [fTimer invalidate];
         [aControlView hideCopyUI];
      }
      @catch (NSException *exception) {
         NSLog(@"Exception on hiding cp ui");
      }
   };
   dispatch_async(cpUiQueue,hCpUIBlock);

}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
   [self enterFullScreen];
   [settingsMgr setCbFullScreenRecord:TRUE];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
   [self enterFullScreen];
   [settingsMgr setCbFullScreenRecord:[ckBFullScreenDuringRecord state]];
}

- (BOOL)isFullScreen {
   return ((self.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}

-(IBAction)actionShowAboutPanel:(id)sender
{
   [licCtrl showWindow:licCtrl.window];
}

@end

