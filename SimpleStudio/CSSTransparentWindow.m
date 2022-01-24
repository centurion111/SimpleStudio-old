//
//  CSSTransparentWindow.m
//  SimpleStudio
//
//  Created by centurion on 12/8/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "CSSTransparentWindow.h"

@implementation CSSTransparentWindow

@synthesize drawTransparent;
@synthesize initialLocation;
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
   NSLog(@"CSSTransparentWindow::initWithContentRect");

   // Using NSBorderlessWindowMask results in a window without a title bar.
   if (!drawTransparent)
   {
      self = [super initWithContentRect:contentRect styleMask:aStyle backing:NSBackingStoreBuffered defer:NO];
      if (self != nil) {
      // Turn off opacity so that the parts of the window that are not drawn into are transparent.
         [self setBackgroundColor: [NSColor windowBackgroundColor]];

         [self setOpaque:YES];
         [self setHasShadow:YES];

         [self setCollectionBehavior:NSWindowCollectionBehaviorStationary];

//      NSLog(@"CSSTransparentWindow::initWithContentRect");
      
      }
   }
   else
   {
   self = [super initWithContentRect:contentRect styleMask:aStyle backing:NSBackingStoreBuffered defer:NO];
   if (self != nil) {
      // Turn off opacity so that the parts of the window that are not drawn into are transparent.
      [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
      [self setLevel:kCGDesktopIconWindowLevelKey - 1];
      
      [self setBackgroundColor: [NSColor clearColor]];

      [self setOpaque:NO];
      [self setHasShadow:NO];
      
   }

   }
   return self;
}


//------------------------------------------
- (BOOL)canBecomeKeyWindow
//------------------------------------------
{
   return YES;
}



@end
