//
//  ControlView.h
//  SimpleStudio
//
//  Created by centurion on 11/23/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSettingsManager.h"

@interface ControlView : NSView
{
   
int guiMode;
}
- (void) updateValueTo:(NSString*)value withColor:(NSColor*)color toTextField:(NSTextField*) txtF;
- (void)setGuiMode:(int)aGuiMode;
- (void) showCopyUI;
- (void) hideCopyUI;


@property (readwrite, assign)IBOutlet NSTextField * statusLabel;
@property (readwrite, assign)IBOutlet NSTextField * bottomStatusLabel;

@property (readwrite, assign)IBOutlet NSLevelIndicator * indicator;


@property (readwrite, assign)IBOutlet NSTextField * timerLabel;

@property (readwrite, assign)IBOutlet NSProgressIndicator *cpPrgIndicator;
@property (readwrite, assign)IBOutlet NSTextField *cpStatusLabel;
@property (assign, assign) IBOutlet NSButton *cancelCopyActionButton;


@property (readwrite) CGPoint lastDragLocation;

@property (readwrite, assign)NSColor *txtColor;
@end
