//
//  AppController.h
//  SimpleStudio
//
//  Created by centurion on 11/10/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//
@import AppKit;

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "CStatusManager.h"
#import "ControlView.h"
#import "CSSView.h"
#import "CSSettingsManager.h"
#import "CDeviceManager.h"
#import "CSCopyPath.h"
#import "CSFtpController.h"
#import "FTPManager.h"
#import "LicensingController.h"

@interface AppController : NSWindowController <AVCaptureFileOutputDelegate, AVCaptureFileOutputRecordingDelegate>
{
   NSPoint ctrlViewInitPoint;
   CSSettingsManager * settingsMgr;
   CStatusManager * alertMgr;
 //  AVCaptureVideoPreviewLayer	*previewLayer;
   
   //Keys for controls
   NSArray *videoDevices;
   NSArray *audioDevices;
//   AVCaptureDevice *selectedVideoDevice;
//   AVCaptureDevice *selectedAudioDevice;
   NSMutableArray * pathsForCPF;
   NSTimer *fTimer;   
   NSTimer  *audioLevelTimer;
   NSTimer  *recordingTimer;
   NSDate * recordingStartTime;
   NSDateFormatter *DateFormatter;
   NSImage *immgRecActive;
   NSImage *immgRecInactive;
   NSImage *immgBtnActive;
   NSArray  *observers;
   LicensingController *licCtrl;
   AVCaptureMovieFileOutput	*movieFileOutput;
   AVCaptureAudioPreviewOutput	*audioPreviewOutput;
   CGDirectDisplayID currentDisplay;
   CSFtpController * ftpctrl;
   CDeviceManager * devCtrl;
   NSString * crFileName;

   IBOutlet NSLevelIndicator  *audioLevelMeter;
   IBOutlet NSTextField *tmpPathField;
   IBOutlet NSTextField *ftpUnameField;
   IBOutlet NSTextField *ftpPasswdField;
   IBOutlet NSTextField *ftpAddressField;

   IBOutlet NSButton * recordingButton;
   IBOutlet NSButton * fsRecBtn;
   IBOutlet NSButton * toggleSettingsButton;
//   IBOutlet NSWindow * exitPipWindow;
   IBOutlet NSDrawer * drawer;
   IBOutlet  NSView * mainView;
   IBOutlet NSMenuItem * m_pipItem;
   IBOutlet NSMenuItem * m_cameraItem;
   IBOutlet NSMenuItem * m_screenItem;
   IBOutlet NSPopUpButton * audioDevSelector;
   IBOutlet NSPopUpButton * videoDevSelector;

   
   NSRect storedMainViewRect;
   NSRect storedControlViewRect;
   NSRect storedPreviewViewRect;

   
}

#pragma mark - Device Properties
@property (assign,nonatomic) AVCaptureDeviceFormat *videoDeviceFormat;
@property (assign) AVCaptureDeviceFormat *audioDeviceFormat;
@property (assign) AVFrameRateRange *frameRateRange;
- (IBAction)lockVideoDeviceForConfiguration:(id)sender;

@property (retain) AVCaptureDeviceInput *videoDeviceInput;
@property (retain) AVCaptureDeviceInput *audioDeviceInput;
@property (strong) AVCaptureScreenInput *captureScreenInput;

@property   CDeviceManager *devCtrl;
//@property   CSFtpController *ftpCtrl;
@property   FTPManager *ftpCtrl;

#pragma mark - Recording
@property (retain) AVCaptureSession *session;
@property (retain) AVCaptureSession *screenCaptureSession;
@property (nonatomic,readwrite) NSArray *availableSessionPresets;


#pragma mark - Preview
@property (retain) IBOutlet CSSView *previewView;
@property (retain) IBOutlet ControlView *aControlView;
@property (retain) IBOutlet ControlView *FSControlView;


-(instancetype) initOnStart;
+(NSString*)generateFileNameWithExtension:(NSString *)extensionString;
-(void)updateAudioLevels:(NSTimer *)timer;
-(void) registerSpaceHook;
-(void) unRegisterSpaceHook;
-(void) registerEscHook;
-(void) unRegisterEscHook;

-(void) stopRecord;
-(void) runRecord;
-(void)enterFullScreen;
- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval;
- (CGColorRef)NSColorToCGColor:(NSColor *)color;
- (id) copyWithZone:(NSZone*)zone;
+ (id) allocWithZone:(NSZone *)zone;
+ (AppController *)getInstance;
+ (AppController *) sharedInstance;

-(int)reconfigureSessions;
-(void)devicesDidChange:(NSNotification *)notification;
-(void)saveDefaults;
-(void)addMetaData;
-(void)setButtonTitleFor:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color;
-(void) disableFtpUI;
-(void) enableFtpUI;


-(int)guiModeToCamera;
-(int)guiModeToScreen;
-(int)guiModeToPIP;
-(IBAction) setSavePath :(NSButton *)sender;
-(IBAction) recordButtonPress :(id)sender;
-(IBAction)enterFullScreen:(id)sender;
@property (atomic, assign) BOOL launchOnLogin;

@property (assign) IBOutlet NSButton *ckBSaveToFlash;
@property (assign) IBOutlet NSButton *ckBCopyToFtp;
@property (assign) IBOutlet NSButton *ckBDisplayAlerts;
@property (assign) IBOutlet NSButton *ckBFullScreenDuringRecord;
@property (assign) IBOutlet NSButton *ckBLoadOnStart;
@property (assign) IBOutlet NSButton *ckbKeyHook;
@property (assign) IBOutlet NSMenuItem * RecordMenuItem;
@property (assign) IBOutlet NSSegmentedControl *modeSelector;

-(IBAction)toggleDisplayAlerts:(id)sender;
-(IBAction)toggleLoadOnStart:(id)sender;
-(IBAction)toggleSaveToFlash:(id)sender;
-(IBAction)toggleFullScreenRecord:(id)sender;
-(IBAction)toggleKeyboardHook:(id)sender;
-(IBAction)toggleCopyToFtp:(id)sender;
-(IBAction)changeGUIMode_m:(NSMenuItem*)sender;
-(IBAction)changeGUIMode:(NSSegmentedControl*)sender;
-(IBAction)exitPip:(NSButton*)sender;
-(IBAction)actionChangeSelectedAudioDevice:(id)sender;
-(IBAction)actionChangeSelectedVideoDevice:(id)sender;
-(IBAction)actionCancelFileCopy:(id)sender;
-(IBAction)actionShowAboutPanel:(id)sender;


-(void)switchGuiModeTo:(int)mode;
-(void)endSession:(AVCaptureSession*)aSession;
-(void)captureSessionRuntimeErrorDidOccur:(NSNotification *)notification;
-(void) updatePreset;

@property NSArray *videoDevices;
@property NSArray *audioDevices;
@property (assign)AVCaptureDevice *selectedVideoDevice;
@property (assign) AVCaptureDevice *selectedAudioDevice;
@property (readonly) BOOL hasRecordingDevice;
@property (assign,getter=isRecording) BOOL recording;
@property (nonatomic,readwrite) BOOL selectedVideoDeviceProvidesAudio;

-(void)setSelectedAudioDevice:(AVCaptureDevice *)aSelectedAudioDevice;
-(void)setSelectedVideoDevice:(AVCaptureDevice *)aSelectedVideoDevice;
-(void)refreshDevices;
-(BOOL)isValidAudioDevice : (NSString*) selectedDevice;
-(BOOL)isValidVideoDevice : (NSString*) selectedDevice;
-(BOOL)hasRecordingDevice;
-(BOOL)isFullScreen;
- (void)updateCpStatus:(NSTimer *)timer;
- (void)copyProcessDidStart:(NSNotification *)notification;
- (void)copyProcessDidEnd:(NSNotification *)notification;
-(int)copyToFtp;
-(int)copyToUsbDrive;
-(NSString*)makeFtpPath:(NSString*)FileName;
-(void) ftpUploadDidFinish:(NSNotification *)notification;
-(AVCaptureScreenInput*)addDisplayInputToCaptureSession;
@end
