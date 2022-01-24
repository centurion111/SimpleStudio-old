//
//  ControlView.m
//  SimpleStudio
//
//  Created by centurion on 11/23/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import "ControlView.h"

@implementation ControlView
@synthesize indicator;
@synthesize statusLabel = _statusLabel;
@synthesize txtColor = _txtColor;
@synthesize lastDragLocation = _lastDragLocation;
@synthesize cpPrgIndicator;
@synthesize cpStatusLabel;
@synthesize cancelCopyActionButton;
@synthesize bottomStatusLabel = _bottomStatusLabel;
//------------------------------------------
- (void)awakeFromNib
//------------------------------------------
{
   // setting the style color. Google for NSColor pre defined t
   guiMode = rm_CAMERA;
   NSLog(@"ControlView::awakeFromNib");
   _txtColor = [NSColor blackColor];
   [[cpStatusLabel cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];

}

- (void)setGuiMode:(int)aGuiMode
{
   guiMode = aGuiMode;
   if ( rm_FULL_SCREEN == guiMode) {
      _txtColor = [NSColor whiteColor];
   }else
      {
      _txtColor = [NSColor blackColor];
      }
}

//set color to button title text. This function is called in awakeFromNib
//
//------------------------------------------
- (void) updateValueTo:(NSString*)value withColor:(NSColor*)color toTextField:(NSTextField*) txtF
//------------------------------------------
{
   NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:value]];
   //setting white color to button title
   [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0,[colorTitle length])];
   [txtF setAttributedStringValue:colorTitle ];
}


//------------------------------------------
- (id)initWithFrame:(NSRect)frame
//------------------------------------------

{
   self = [super initWithFrame:frame];
   if (self) {
   }
   return self;
}

//here we set the view (window) color and drawings
//------------------------------------------
- (void)drawRect:(NSRect)rect
//------------------------------------------
{
   // Clear the drawing rect and fill it with some alphavalue
   if ( rm_FULL_SCREEN==guiMode) {
     
      //NSLog(@"Redrawing ControlView to FullScreen,guiMode is %d",guiMode);
      [super drawRect: rect];
      [[[NSColor  clearColor] colorWithAlphaComponent:0.5 ] setFill];

      NSRectFill( rect);
      //drawing the border
      NSBezierPath * path;
      path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5 yRadius:5];
      //setting the border color as white
      [[NSColor whiteColor] set];
      [path stroke];
      
   }
   else if ( rm_SCREEN == guiMode )
      {
 //        NSLog(@"ControlView:: Screen mode is on, guiMode is %d",guiMode);
         //[super drawRect: rect];
      }else
         {
//            NSLog(@"ControlView:: Fullscreen mode is off,guiMode is %d",guiMode);
         
         }
   
   [self updateValueTo:[_statusLabel stringValue] withColor:_txtColor toTextField:[self statusLabel]];
   [self updateValueTo:[_timerLabel stringValue] withColor:_txtColor toTextField:[self timerLabel]];
   [self updateValueTo:@"Press Esc to exit FullScreen" withColor:_txtColor toTextField:[self bottomStatusLabel]];

}

//------------------------------------------
- (BOOL) acceptsFirstMouse:(NSEvent *)e {
//------------------------------------------
   if ( (rm_FULL_SCREEN == guiMode) || (rm_SCREEN == guiMode) )
      {
         return YES;
      }
   return NO;
}


//------------------------------------------
- (void)mouseDown:(NSEvent *) e {
//------------------------------------------
   
   // Convert to superview's coordinate space
   if ( rm_FULL_SCREEN == guiMode )
   _lastDragLocation = [[self superview] convertPoint:[e locationInWindow] fromView:nil];
   
}

//------------------------------------------
- (void)mouseDragged:(NSEvent *)theEvent
//------------------------------------------
{
//   NSLog(@"ControlView:: Fullscreen mode is off, mouse dragged");
   if ( (rm_FULL_SCREEN == guiMode) )
   {
  // NSLog(@"ControlView:: Fullscreen mode is on, mouse dragged");
      // We're working only in the superview's coordinate space, so we always convert.
      NSPoint newDragLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
      NSPoint thisOrigin = [self frame].origin;
      thisOrigin.x += (-self.lastDragLocation.x + newDragLocation.x);
      thisOrigin.y += (-self.lastDragLocation.y + newDragLocation.y);
      [self setFrameOrigin:thisOrigin];
      self.lastDragLocation = newDragLocation;
   }
}


//------------------------------------------
-(void) showCopyUI
//------------------------------------------
{
   NSLog(@"CtrlVIew::ShowCopyUI");
   @try {
      [cpPrgIndicator setHidden:NO];
      [cancelCopyActionButton setHidden:NO];
      [cpStatusLabel setHidden:NO];
      [self needsDisplay];

   }
   @catch (NSException *exception) {
      NSLog(@"UI display error");
   }

   
}

//------------------------------------------
-(void) hideCopyUI
//------------------------------------------
{
   NSLog(@"CtrlVIew::hideCopyUI");
   @try {

   [cpPrgIndicator setHidden:YES];
   [cancelCopyActionButton setHidden:YES];
   [cpStatusLabel setHidden:YES];
   [self needsDisplay];
      
   }
   @catch (NSException *exception) {
      NSLog(@"UI display error");
   }

}



@end
