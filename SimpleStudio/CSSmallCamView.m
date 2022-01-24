//
//  CSSmallCamView.m
//  SimpleStudio
//
//  Created by centurion on 12/8/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "CSSmallCamView.h"

@implementation CSSmallCamView
@synthesize txtColor = _txtColor;
@synthesize lastDragLocation = _lastDragLocation;


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL) acceptsFirstMouse:(NSEvent *)e {
   return YES;
}


- (void)mouseDown:(NSEvent *) e {
   
   // Convert to superview's coordinate space
   _lastDragLocation = [[self superview] convertPoint:[e locationInWindow] fromView:nil];
   
}

- (void)mouseDragged:(NSEvent *)theEvent {
   
      // We're working only in the superview's coordinate space, so we always convert.
      NSPoint newDragLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
      NSPoint thisOrigin = [self frame].origin;
      thisOrigin.x += (-self.lastDragLocation.x + newDragLocation.x);
      thisOrigin.y += (-self.lastDragLocation.y + newDragLocation.y);
      [self setFrameOrigin:thisOrigin];
      self.lastDragLocation = newDragLocation;
}



@end
