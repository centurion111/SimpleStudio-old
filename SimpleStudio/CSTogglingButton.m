//
//  CSTogglingButton.m
//  SimpleStudio
//
//  Created by centurion on 1/2/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSTogglingButton.h"

@implementation CSTogglingButton

@synthesize isOn;

-(BOOL)wantsUpdateLayer
{
   return YES;
}

-(void)updateLayer
{
   if (isOn)
      {
         self.layer.contents = [NSImage imageNamed:@"activeBtnBg.png"];
      }
   else
      {
         self.layer.contents = [NSImage imageNamed:@"btnUnPressed.png"];
      }
}
@end
