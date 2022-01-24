//
//  CSSmallCamView.h
//  SimpleStudio
//
//  Created by centurion on 12/8/14.
//  Copyright (c) 2014 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSSmallCamView : NSView

@property (readwrite) CGPoint lastDragLocation;

@property (readwrite, assign)NSColor *txtColor;

@end
