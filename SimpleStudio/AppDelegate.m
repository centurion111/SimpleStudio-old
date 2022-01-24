  //
//  AppDelegate.m
//  SimpleStudio
//
//  Created by centurion on 11/10/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
   // Insert code here to initialize your application
   NSLog (@"Starting SimpleStudio build 100");
   appCtrl = [[AppController alloc]initOnStart];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
   // Insert code here to tear down your application
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
   return NO;
}

@end
