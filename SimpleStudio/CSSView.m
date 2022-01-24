//
//  CSSView.m
//  SimpleStudio
//
//  Created by centurion on 11/24/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "CSSView.h"

@implementation CSSView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
   if ([self isInFullScreenMode]) {
      
   } else {
      
   }
    // Drawing code here.
}


- (void)windowDidResize:(NSNotification *)notification {
   // Delegate method
   NSRect zWindowRect = [[self window]frame];
   NSRect zContentRect = [[self window]contentRectForFrameRect:zWindowRect];
   NSRect zRectOfView = NSMakeRect(0.0,0.0,zContentRect.size.width,
                                   zContentRect.size.height);
   [self setFrame:zRectOfView];
   
   [self setNeedsDisplay:YES];
   
} // end windowDidResize

- (BOOL)mouseDownCanMoveWindow
{
   return YES;
}

@end
