//
//  LicensingController.m
//  SimpleStudio
//
//  Created by centurion on 2/20/17.
//  Copyright © 2017 centurion. All rights reserved.
//

#import "LicensingController.h"

@interface LicensingController ()
@end

@implementation LicensingController
@synthesize picView = _picView;
@synthesize numberField = _numberField;
@synthesize numberLabel = _numberLabel;
@synthesize activateButton = _activateButton;

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
   [_picView setHidden:NO];
   [_numberField setHidden:YES];
   [_numberLabel setHidden:YES];
   [_activateButton setHidden:YES];
}

-(IBAction)actionBuyLicense:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://automagiclab.com"]];
}

-(IBAction)ActionEnterSerial:(id)sender
{
   [_picView setHidden:YES];
   [_numberField setHidden:NO];
   [_numberLabel setHidden:NO];
   [_activateButton setHidden:NO];
   
}
-(IBAction)ActionCancel:(id)sender
{
   [self.window close];
}


@end
