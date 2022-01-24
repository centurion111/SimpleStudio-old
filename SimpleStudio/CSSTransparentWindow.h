//
//  CSSTransparentWindow.h
//  SimpleStudio
//
//  Created by centurion on 12/8/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSSTransparentWindow : NSWindow
{
   // this point is used in dragging to mark the initial click location
   NSPoint initialLocation;
}

@property (assign) NSPoint initialLocation;
@property (readwrite) BOOL drawTransparent;


@end
