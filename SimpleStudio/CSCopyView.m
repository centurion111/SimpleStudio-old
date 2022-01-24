//
//  CSCopyView.m
//  SimpleStudio
//
//  Created by centurion on 4/5/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSCopyView.h"

static NSProgressIndicator *progressIndicator;

@implementation CSCopyView
{
   
}
@synthesize cancelBtn;
@synthesize txtColor;
@synthesize cpStatusLabel;
@synthesize saveProgressIndicator;

-(id)init
{
   if (![super init]) {
      NSLog(@"CSCopyView::init init failed");
      return nil;
   }
   progressIndicator = saveProgressIndicator;
   return self;
   
  
}

- (void)drawRect:(NSRect)dirtyRect {
   [super drawRect:dirtyRect];
   [self setTxtColor:[NSColor blackColor]];
 //  [self updateStatus:@""withColor:txtColor];
    // Drawing code here.
}


//------------------------------------------
- (void) updateStatus:(NSString*)value withColor:(NSColor*)color
//------------------------------------------
{
   NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:value]];
   //setting white color to button title
   [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0,[colorTitle length])];
   [cpStatusLabel setAttributedStringValue:colorTitle ];
}



@end
