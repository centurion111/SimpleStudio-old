//
//  CSSMainWindow.m
//  SimpleStudio
//
//  Created by centurion on 1/7/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSSMainWindow.h"

@implementation CSSMainWindow
@synthesize initialLocation;
@synthesize guiMode;
/*
In Interface Builder, the class for the window is set to this subclass. Overriding the initializer
provides a mechanism for controlling how objects of this class are created.
*/
//------------------------------------------
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
//------------------------------------------
{
  // if (rm_SCREEN == guiMode)
   {
   
   // Using NSBorderlessWindowMask results in a window without a title bar.
   self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
   if (self != nil) {
      // Turn off opacity so that the parts of the window that are not drawn into are transparent.
      [self setOpaque:NO];
      [self setHasShadow:NO];
      NSLog(@"CSSMainWindow::initWithContentRect guiMode screen");
      
      }
   }
  // else
      {
      NSLog(@"CSSMainWindow::initWithContentRect noFlag");
  //    self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO];
      }
   return self;
}



/*
 Start tracking a potential drag operation here when the user first clicks the mouse, to establish
 the initial location.
 */
//------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
//------------------------------------------
{
   NSLog(@"CSSMainWindow::mouseDown");

 //  if (rm_SCREEN == guiMode)
      {
     //    NSLog(@"CSSMainWindow::mouseDown flagActive");
      
         // Get the mouse location in window coordinates.
         self.initialLocation = [theEvent locationInWindow];
      }
}

/*
 Once the user starts dragging the mouse, move the window with it. The window has no title bar for
 the user to drag (so we have to implement dragging ourselves)
 */

//------------------------------------------
- (void)mouseDragged:(NSEvent *)theEvent
//------------------------------------------
{
   NSLog(@"CSSMainWindow::mouseDragged ");

  if (rm_SCREEN == guiMode)
      {
         NSLog(@"CSSMainWindow::mouseDragged flagActive");

         NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
         NSRect windowFrame = [self frame];
         NSPoint newOrigin = windowFrame.origin;
   
         // Get the mouse location in window coordinates.
         NSPoint currentLocation = [theEvent locationInWindow];
         // Update the origin with the difference between the new mouse location and the old mouse location.
         newOrigin.x += (currentLocation.x - initialLocation.x);
         newOrigin.y += (currentLocation.y - initialLocation.y);
   
         // Don't let window get dragged up under the menu bar
         if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
            newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
         }
         // Move the window to the new location
         [self setFrameOrigin:newOrigin];
      }
}

//------------------------------------------
- (BOOL)canBecomeKeyWindow
//------------------------------------------
{
   return YES;
}

@end
