//
//  CSCopyView.h
//  SimpleStudio
//
//  Created by centurion on 4/5/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSCopyView : NSView


@property (readwrite, assign)NSColor *txtColor;
@property (readwrite, assign)IBOutlet NSTextField * cpStatusLabel;
@property (readwrite, assign)IBOutlet NSButton * cancelBtn;

@property (readwrite, assign)IBOutlet NSProgressIndicator  *saveProgressIndicator;

- (void) updateStatus:(NSString*)value withColor:(NSColor*)color;

@end
