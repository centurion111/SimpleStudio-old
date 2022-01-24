//
//  CSSMainWindow.h
//  SimpleStudio
//
//  Created by centurion on 1/7/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSettingsManager.h"
@interface CSSMainWindow : NSWindow
{
   NSPoint initialLocation;
}

@property (assign) NSPoint initialLocation;
@property (assign) NSInteger guiMode;

@end
